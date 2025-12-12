# EventEase Implementation Checklist

## 1) Data Model & Migrations

- Add enums to `events` (`status`: draft/published/cancelled/completed; `category` optional) and reconcile `date_time` vs `starts_at/ends_at`.
- Add `registrations.user_id`, ensure `checked_in`/status alignment, indexes on `event_id`, `email`, `status`.
- Add `email_logs` table for outbound emails.
- Add scopes: `published`, `upcoming`, `past`, `popular`, `by_location`; add counter caches where needed.

## 2) Auth & Authorization

- Add `pundit` and policies for events/registrations; enforce organizer ownership on edit/update/destroy/check-in.
- Restrict attendees to their own registrations; organizers to their own events.

## 3) Background Jobs & Emails

- Add gems: `sidekiq`, `sidekiq-scheduler`, `redis`, SendGrid/Mailgun.
- Add config: `config/sidekiq.yml`, `Procfile`/`Procfile.dev`, initializer.
- Add jobs: `SendConfirmationEmailJob`, `SendReminderEmailJob`, `SendAnnouncementEmailJob`.
- Add mailers + views: `RegistrationMailer`, `EventMailer`; wire reminder scheduling (24h before event) and organizer notification on new registration.

## 4) AI Features

- Add `ruby-openai`; initializer with credentials.
- Services: AI description generator (and optional announcement/time suggestions).
- Endpoints: `POST /ai/generate-description`, etc.; Stimulus UI button on event form for “Generate with AI”.

## 5) Routes & Controllers

- Clean routes; add public discovery index, AI endpoints, CSV export, attendee list, check-in routes.
- Controllers: fix index/search logic; add CSV export action; attendee search/filter in check-in.

## 6) Views / UX

- Public discovery page with search/filter/date-range.
- Event form: AI button, capacity warning, CSV export link on show.
- Check-in page: search/filter + live counter.
- Turbo Streams for live registration/check-in counters.

## 7) Testing & CI

- Add `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`, `faker`, `capybara`.
- Specs: models (validations/scopes/status), controllers/requests (auth/authorization/flows), features (register, cancel, check-in).
- CI: GitHub Actions workflow to run tests (and RuboCop if desired).

## 8) Deployment & Config

- `.env.example`/credentials: `RAILS_MASTER_KEY`, `DATABASE_URL`, `REDIS_URL`, `SENDGRID_API_KEY`/`MAILGUN_API_KEY`, `OPENAI_API_KEY`, `DEVISE_SECRET_KEY`, `APP_URL`.
- Production mailer config; Redis/Sidekiq process; optional Procfile worker entry.
- Optional monitoring: Sentry; rate limiting with Rack::Attack.

## 9) Security & Observability

- Enable Rack::Attack; ensure CSRF defaults; avoid hardcoded secrets.
- Add error tracking (Sentry) and basic logging/metrics hooks.

## 10) Optional Post-MVP

- Categories/tags; recurring events; payments/Stripe; QR check-in; waitlist; ratings/reviews; geolocation search; dark mode.
