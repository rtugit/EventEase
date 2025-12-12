# EventEase: AI Coding Agent Instructions

## Architecture Overview

**EventEase** is a lightweight event management platform for small, local meetups. Built with Rails 7, PostgreSQL, Hotwire/Turbo, and Bootstrap 5.

### Core Domain Model (3 tables, 3 controllers)

- **User** (Devise): Organizers only; `has_many :events`
- **Event**: Public events owned by a User; `has_many :registrations`
- **Registration**: Attendee link to event; scoped uniquely by `[:event_id, :email]`

Data flows: Organizers create events → attendees register via email → organizers check-in attendees on event day.

### Key Routes & Patterns

```
events: CRUD + show (nested under devise auth)
registrations: create (nested under event), destroy, check_in (custom member action)
```

Routes have duplication (both resourceful and manual routes in routes.rb—see TODO in `routes.rb`).

## Developer Workflows

### Setup & Running

```bash
bundle install
bin/rails db:setup          # Create DB + schema
bin/rails server           # Start Puma (localhost:3000)
bin/rails test             # Run test suite (currently minimal)
```

### Database Changes

- Migrations live in `db/migrate/`
- Schema snapshots in `db/schema.rb`
- Seed data in `db/seeds.rb` (use `db:seed`)
- Always run `db:migrate:status` before deploying

### Code Quality

- RuboCop enabled (see `.rubocop.yml`): `bundle exec rubocop` + `--fix-all` for auto-fixes
- Uses `rubocop-rails` + `rubocop-capybara` plugins
- Tests: minimal coverage; extend in `test/` directory (test_helper auto-requires fixtures: false)

## Critical Patterns & Conventions

### Models

1. **Validations**: Use presence, format (email regex), inclusion (enums), and custom validators
2. **Associations**: Always use `inverse_of:` for bidirectional relations (improves memory efficiency)
3. **Status Enums**: Stored as strings ("registered", "checked_in", "cancelled"); change via methods like `check_in!` and `cancel!`
4. **Counter Cache**: `registrations_count` on Event is maintained via Rails counter_cache

### Controllers

- **Authentication**: `before_action :authenticate_user!` gates organizer endpoints
- **Authorization**: Check `current_user` owns event/registration before modifying (see `registrations#check_in`)
- **Params**: Use `permit` whitelisting; never permit nested attrs without explicit need
- **Redirects**: Use `status: :see_other` for destructive actions (DELETE → redirect is safe)
- **Localization**: Use `t('.key')` for view strings; translation files in `config/locales/`

### Views

- Bootstrap 5 + Font Awesome icons for UI
- SimpleForm gem for form rendering (configured in `config/initializers/simple_form.rb`)
- Stimulus JS for interactivity (minimal controllers in `app/javascript/controllers/`)
- Turbo for SPA-like navigation (auto-wired in `layout/application.html.erb`)

### Devise Setup

- User model includes: `authenticatable`, `registerable`, `recoverable`, `rememberable`, `validatable`
- Email is unique index; password stored encrypted
- Custom fields: `first_name`, `last_name`, `time_zone` (default "Europe/Berlin")
- Routes auto-mounted; customize in `config/initializers/devise.rb`

## Important Implementation Notes

1. **Attendee Registration**: No user account required—registrations identified by email only. Supports guest attendance.
2. **Status Transitions**: Registration status is controlled by model methods (`check_in!`, `cancel!`), not by raw updates.
3. **Unique Constraint**: Registrations scoped by `[event_id, email]` prevents duplicate registrations for same event.
4. **Organizer Visibility**: Only event organizer can see/modify registrations for their events.

## File Reference

- **Models**: `app/models/{user,event,registration}.rb`
- **Controllers**: `app/controllers/{events,registrations}_controller.rb`
- **Views**: `app/views/{events,registrations}/`, also `app/views/devise/` (Devise forms)
- **Migrations**: Latest is `20251209_141951_create_registrations.rb`
- **Config**: Check `config/environments/{development,production}.rb` for mailer/storage settings
- **Locales**: `config/locales/en.yml` + `devise.en.yml` + `simple_form.en.yml`

## Common Tasks

**Adding a field to Event**: (1) Create migration, (2) add validator in model, (3) add to form in view, (4) permit in controller, (5) update tests.

**Sending emails**: Set `config.action_mailer.delivery_method` in environment; currently in test mode. Mailer template location: `app/mailers/` + `app/views/application_mailer/`.

**Styling changes**: SCSS in `app/assets/stylesheets/` (organized by component/page); imports Bootstrap via `@import "bootstrap";`.

## Known TODOs & Quirks

- `routes.rb` has duplicate route definitions (resourceful + manual routes for events CRUD)—consolidate to resourceful only
- Test suite is minimal; extend with real unit + integration tests
- Production mailer domain is TODO placeholder—set before deploying
- No enum macro used; status stored as string (acceptable, but could migrate to Rails enum if scaling)
