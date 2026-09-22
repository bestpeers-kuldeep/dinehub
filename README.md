# Dinehub

Rails 8.1 API for a restaurant site: menus, weekly specials, events, table availability, reservations, party/catering inquiries, and career applications.

## Stack

- Ruby 3.4.7
- Rails 8.1 (API-only)
- PostgreSQL
- Puma
- Active Storage (menu item images, event logos, career resumes)
- Solid Queue / Solid Cache / Solid Cable
- OpenAPI UI via rswag (`/api-docs`)

## Prerequisites

- Ruby 3.4.7 (see `.ruby-version`)
- PostgreSQL
- Bundler
- libvips (image processing)
- libpq (PostgreSQL client libraries)

## Setup

Create a `.env` in the project root (loaded by `dotenv-rails` in development and test). `.env*` is gitignored.

```sh
DATABASE_USERNAME=postgres
DATABASE_PASSWORD=postgres

# Optional. Defaults include local Vite/Rails ports.
# CORS_ORIGINS=http://localhost:5173,http://127.0.0.1:5173

# Optional. Used for generated URLs (Active Storage, mailers) and ngrok.
# APP_HOST=localhost
# APP_PROTOCOL=http
# APP_PORT=3000
```

Development database config (`config/database.yml`) requires `DATABASE_USERNAME` and `DATABASE_PASSWORD`. It connects to `localhost` as `dinehub_development`. Production uses `DATABASE_URL`.

Install gems and prepare the database:

```sh
bundle install
bin/rails db:prepare
bin/rails db:seed
```

`bin/setup` installs gems, runs `db:prepare`, then starts the server (`bin/dev`). Pass `--reset` to wipe and recreate the database, or `--skip-server` to stop after setup.

Seeds are idempotent. They load menus (Our Menu, Specials, Drinks), events, tables by location, and a sample table reservation. Menu and event images come from `db/seeds/images` and `db/seeds/logos`.

## Running the app

```sh
bin/dev
```

The API listens on port 3000 by default.

Interactive docs (Swagger UI) are at [http://localhost:3000/api-docs](http://localhost:3000/api-docs). The OpenAPI document is served from `/api-docs/v1/swagger.yaml`.

In development, outgoing mail is captured by Letter Opener Web at [http://localhost:3000/letter_opener](http://localhost:3000/letter_opener). Table bookings send a confirmation; party and catering inquiries send an inquiry-received email.

## API

All JSON endpoints live under `/api/v1`. CORS is limited to `/api/*`. Allowed origins come from `CORS_ORIGINS` (comma-separated). Outside production, if that variable is unset, local Vite/Rails origins plus `https://${APP_HOST}` are allowed. In production, `config.x.cors_origins` defaults to `https://${APP_HOST}` unless `CORS_ORIGINS` is set.

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/api/v1/menus` | List menus (`our_menu`, `specials`, `drinks`) |
| GET | `/api/v1/menus/:id` | Show a menu |
| GET | `/api/v1/menu_categories` | List categories (`menu_id`, `drink_type` filters) |
| GET | `/api/v1/menu_categories/:id` | Show a category |
| GET | `/api/v1/menu_items` | List items (`menu_category_id`, `drink_type` filters) |
| GET | `/api/v1/menu_items/:id` | Show an item |
| GET | `/api/v1/specials` | This week’s specials (today through today + 6 days) |
| GET | `/api/v1/events` | List events |
| GET | `/api/v1/events/:id` | Event with items |
| GET | `/api/v1/tables` | Available table **counts** by location (`date` and `start_time` required) |
| POST | `/api/v1/reservations` | Book a dining table at a location |
| POST | `/api/v1/parties_reservations` | Party inquiry |
| POST | `/api/v1/catering_reservations` | Catering inquiry |
| POST | `/api/v1/careers` | Job application (JSON or `multipart/form-data` with `resume`) |

Table reservations assign a hidden table at a location. Arrival times must land on a 30-minute slot (`18:00`, `18:30`, …). Each booking holds an estimated 2-hour dining window. Table names are not returned by the public API.

Request bodies may be flat JSON or nested (`reservation`, `parties_reservation`, `catering_reservation`, `career`). See the OpenAPI examples for fields.

## Tests

```sh
bin/rails db:test:prepare
bin/rails test
```

CI (`.github/workflows/ci.yml`) runs Brakeman, bundler-audit, RuboCop, and the test suite against PostgreSQL.

```sh
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit
```

## Configuration notes

- **Generated URLs.** Set `APP_HOST` (and optionally `APP_PROTOCOL` / `APP_PORT`) so Active Storage and mailer links match the host you use. Development also allows ngrok hostnames.
- **Production.** `APP_HOST` is required. CORS defaults to `https://${APP_HOST}`; set `CORS_ORIGINS` to override. `DATABASE_URL` is the database connection.
- **Jobs.** Reservation emails use Active Job. In Kamal production, `SOLID_QUEUE_IN_PUMA` runs the Solid Queue supervisor inside Puma.
- **Deploy.** Production image build is in `Dockerfile`; Kamal config is `config/deploy.yml`.
