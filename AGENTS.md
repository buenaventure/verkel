# AGENTS.md

## Cursor Cloud specific instructions

VerKeL is a single Rails 8 monolith (Ruby 3.4.8, PostgreSQL, Yarn/Webpack + Sass). See `README.md` for the basics; this section covers non-obvious Cloud VM details.

### System prerequisites (one-time per VM)

- **Ruby 3.4.8** via rbenv (see `.ruby-version`). Ensure `~/.bashrc` initializes rbenv (`eval "$(rbenv init - bash)"`).
- **PostgreSQL 18** (required): `db/structure.sql` sets `transaction_timeout`, which needs PG 17+. CI uses `postgres:18-alpine`. Ubuntu’s default PG 16 package is insufficient for `bin/rails db:prepare` / `db:schema:load`.
  - Start before Rails commands: `sudo pg_ctlcluster 18 main start` (cluster must listen on port **5432** for default `config/database.yml`).
  - Dev credentials used in CI and locally: `DATABASE_USER=postgres`, `DATABASE_PASSWORD=postgres`, `DATABASE_HOST=127.0.0.1`.

### Environment variables

Export for Rails, tests, and `bin/dev`:

```bash
export DATABASE_USER=postgres DATABASE_PASSWORD=postgres DATABASE_HOST=127.0.0.1
```

Optional `.env` is supported via `dotenv-rails` (gitignored).

### Dependencies and database

```bash
bundle install
yarn install
yarn build && yarn build:css   # required before first server start; gitignored under app/assets/builds/
bin/rails db:prepare
bin/rails db:seed              # admin@example.com / admin + sample Kochgruppen/Meals
```

`bin/setup` runs bundle + `db:prepare` and can start `bin/dev` (omit `--skip-server` only when you want the server immediately).

### Running the app (development)

Use **Foreman** via `bin/dev` (`Procfile.dev`: Rails on port 3000, `yarn build --watch`, `yarn build:css --watch`). Foreman is installed on first `bin/dev` run.

Without Foreman, run all three processes in separate terminals.

### Lint / test

| Task | Command |
|------|---------|
| Lint | `bin/rubocop` (many existing offenses; CI does not run RuboCop) |
| Tests | `bin/rake spec` (or `bin/rake`, same as CI) after `bin/rails db:schema:load` |

Run the suite via **Rake**, not bare `bin/rspec`. CSS/JS are built by Yarn into gitignored `app/assets/builds/`; `cssbundling-rails` hooks that step onto `test:prepare`, which Rake runs before specs. Direct `bin/rspec` skips the build and request specs that render the layout fail looking for `sassc`.

Tests only need PostgreSQL; they do not need asset watchers running during the suite.

### Seeded demo login

After `db:seed`: **admin@example.com** / **admin**. Core UI routes include `/groups` (Kochgruppen) and `/meals` (Menü).
