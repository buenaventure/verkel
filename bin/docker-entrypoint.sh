#!/bin/sh
set -e

case "${DISABLE_DB_MIGRATE}" in
  true|TRUE|1|yes|YES)
    ;;
  *)
    echo "Running database migrations..."
    bundle exec rails db:migrate
    ;;
esac

exec "$@"
