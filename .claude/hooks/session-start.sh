#!/bin/bash
# SessionStart hook for Claude Code on the web.
#
# Provisions the toolchain described in AGENTS.md -- Ruby from .ruby-version
# (via rbenv), Node from .node-version and PostgreSQL 18 (CI runs
# postgres:18-alpine; db/structure.sql needs PG 17+) -- then installs gems and
# JS packages, builds assets and prepares the development and test databases.
#
# The web sandbox blocks cache.ruby-lang.org and apt.postgresql.org, so Ruby is
# built from its GitHub tag and PostgreSQL comes from conda-forge. The PG build
# is registered as a regular Debian cluster, so `pg_ctlcluster 18 main start`
# works as documented in AGENTS.md.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$PROJECT_DIR"

RUBY_VERSION="$(tr -d '[:space:]' < .ruby-version)"
NODE_VERSION="$(tr -d '[:space:]' < .node-version)"
NODE_PREFIX="/opt/node-${NODE_VERSION}"
PG_MAJOR=18
PG_PREFIX="/opt/postgresql-${PG_MAJOR}"
RBENV_ROOT="${RBENV_ROOT:-/opt/rbenv}"
export MAMBA_ROOT_PREFIX=/opt/micromamba
MICROMAMBA_VERSION=2.9.0

export DATABASE_USER=postgres DATABASE_PASSWORD=postgres DATABASE_HOST=127.0.0.1
export PATH="${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:${NODE_PREFIX}/bin:${PATH}"
export DEBIAN_FRONTEND=noninteractive
export LANG=C.UTF-8

log() { echo "[session-start] $*" >&2; }

# Run a command with its output captured; show the tail only if it fails.
quiet() {
  local out
  out="$(mktemp)"
  if ! "$@" >"$out" 2>&1; then
    tail -50 "$out" >&2
    rm -f "$out"
    return 1
  fi
  rm -f "$out"
}

# --- System libraries -------------------------------------------------------
if ! dpkg -s libvips42t64 >/dev/null 2>&1; then
  log "Installing libvips"
  apt-get update -qq >/dev/null 2>&1 || true # some preinstalled PPAs are blocked
  quiet apt-get install -y -qq --no-install-recommends libvips42t64
fi

# --- Ruby -------------------------------------------------------------------
build_ruby() {
  local src
  src="$(mktemp -d)"
  git -c advice.detachedHead=false clone -q --depth 1 --branch "v${RUBY_VERSION}" \
    https://github.com/ruby/ruby.git "$src"
  (
    cd "$src"
    ./autogen.sh
    ./configure --prefix="${RBENV_ROOT}/versions/${RUBY_VERSION}" --disable-install-doc --enable-shared
    make -j"$(nproc)"
    make install
  )
  rm -rf "$src"
}

if [ ! -x "${RBENV_ROOT}/versions/${RUBY_VERSION}/bin/ruby" ]; then
  log "Building Ruby ${RUBY_VERSION} from source"
  quiet build_ruby
  rbenv rehash
fi

# --- Node.js + Yarn (select2 requires Node >= 24) ---------------------------
if [ ! -x "${NODE_PREFIX}/bin/node" ]; then
  log "Installing Node.js ${NODE_VERSION}"
  mkdir -p "${NODE_PREFIX}"
  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" |
    tar -xJ --strip-components=1 -C "${NODE_PREFIX}"
fi
[ -x "${NODE_PREFIX}/bin/yarn" ] || quiet npm install -g yarn@1

# --- PostgreSQL -------------------------------------------------------------
if [ ! -x "${PG_PREFIX}/bin/postgres" ]; then
  log "Installing PostgreSQL ${PG_MAJOR} from conda-forge"
  if [ ! -x "${MAMBA_ROOT_PREFIX}/bin/micromamba" ]; then
    mkdir -p "${MAMBA_ROOT_PREFIX}"
    curl -fsSL "https://conda.anaconda.org/conda-forge/linux-64/micromamba-${MICROMAMBA_VERSION}-0.tar.bz2" |
      tar -xj -C "${MAMBA_ROOT_PREFIX}" bin/micromamba
  fi
  quiet "${MAMBA_ROOT_PREFIX}/bin/micromamba" create -y \
    -p "${PG_PREFIX}" -c conda-forge --override-channels "postgresql=${PG_MAJOR}"
fi
ln -sfn "${PG_PREFIX}" "/usr/lib/postgresql/${PG_MAJOR}"

# Move the preinstalled PG 16 cluster out of the way of port 5432.
if [ -f /etc/postgresql/16/main/postgresql.conf ]; then
  pg_ctlcluster 16 main stop >/dev/null 2>&1 || true
  sed -i 's/^port = 5432\b/port = 5433/' /etc/postgresql/16/main/postgresql.conf
  echo manual > /etc/postgresql/16/main/start.conf
fi

if [ ! -d "/etc/postgresql/${PG_MAJOR}/main" ]; then
  log "Creating PostgreSQL ${PG_MAJOR} cluster"
  quiet pg_createcluster "${PG_MAJOR}" main --port 5432 --locale C.UTF-8 --encoding UTF8
fi
if ! pg_lsclusters -h | awk -v v="${PG_MAJOR}" '$1 == v && $2 == "main" && $4 == "online"' | grep -q .; then
  pg_ctlcluster "${PG_MAJOR}" main start
fi
su postgres -c "psql -h /var/run/postgresql -p 5432 -qc \"ALTER USER postgres PASSWORD '${DATABASE_PASSWORD}'\""

# --- App dependencies -------------------------------------------------------
log "Installing gems"
bundle check >/dev/null 2>&1 || quiet bundle install

log "Installing JS packages and building assets"
quiet yarn install --non-interactive
quiet yarn build
quiet yarn build:css

# The web image ships bun, and cssbundling-rails then runs `bun install` (from
# yarn.lock) during test:prepare, leaving an untracked bun.lock behind.
if [ -d .git/info ] && ! grep -qx '/bun.lock' .git/info/exclude 2>/dev/null; then
  echo '/bun.lock' >> .git/info/exclude
fi

log "Preparing databases"
quiet bin/rails db:prepare
RAILS_ENV=test quiet bin/rails db:prepare

# --- Session environment ----------------------------------------------------
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  cat >> "$CLAUDE_ENV_FILE" <<EOF
export PATH="${RBENV_ROOT}/shims:${RBENV_ROOT}/bin:${NODE_PREFIX}/bin:\$PATH"
export DATABASE_USER=${DATABASE_USER} DATABASE_PASSWORD=${DATABASE_PASSWORD} DATABASE_HOST=${DATABASE_HOST}
EOF
fi

log "Ready: $(ruby -v | cut -d' ' -f1-2), node $(node -v), $("${PG_PREFIX}/bin/postgres" --version)"
