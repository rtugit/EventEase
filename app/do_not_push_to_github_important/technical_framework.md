db# Technical Framework

## Core entities

### User (organizer)

Represents people who create and manage events; attendees never need a User record.

**Suggested columns**

- `id`: bigint, primary key
- `first_name`: string, null: false
- `last_name`: string, null: false
- `email`: string, null: false, index: { unique: true }
- `time_zone`: string, null: false, default: "Europe/Berlin"
- `created_at`: datetime, null: false
- `updated_at`: datetime, null: false

**Rails model sketch**

- **Validations**:
  - presence: `first_name`, `last_name`, `email`
  - uniqueness: `email` (case-insensitive)
- **Associations**:
  - `has_many :organized_events, class_name: "Event", foreign_key: "organizer_id", inverse_of: :organizer`

### Event

Public, organizer-owned event with schedule, location, and capacity control.

**columns**

- `id`: bigint, primary key
- `organizer_id`: bigint, null: false, index, FK → `users.id`
- `title`: string, null: false
- `description`: text, null: false
- `location`: string, null: false
- `starts_at`: datetime, null: false
- `ends_at`: datetime, null: true
- `capacity`: integer, null: true # null = unlimited
- `status`: string, null: false, default: "published"
  - domain: "draft", "published", "archived"
- `registration_open_from`: datetime, null: true
- `registration_open_until`: datetime, null: true
- `created_at`: datetime, null: false
- `updated_at`: datetime, null: false

**Derived/virtual data**

- `registrations_count`: integer (counter cache) – number of registrations.
- `confirmed_registrations_count`: integer – count of non-cancelled registrations.
- `remaining_spots`: integer – capacity - confirmed_registrations_count (nil if capacity is null).

**Rails model sketch**

- `belongs_to :organizer, class_name: "User", inverse_of: :organized_events`
- `has_many :registrations, dependent: :destroy, inverse_of: :event`
- counter_cache on registrations (add `registrations_count` to events)
- **Validations**:
  - presence: `organizer`, `title`, `description`, `location`, `starts_at`
  - `ends_at` after `starts_at` (custom validation) if present
  - `capacity` >= 0 if present
- Optional enum for status using a string-backed enum.

### Registration

Atomic record of one attendee’s relationship to one event.

**Suggested columns**

- `id`: bigint, primary key
- `event_id`: bigint, null: false, index, FK → `events.id`
- `email`: string, null: false, index
- `name`: string, null: true
- `status`: string, null: false, default: "registered"
  - domain: "registered", "checked_in", "cancelled"
- `check_in_at`: datetime, null: true
- `cancelled_at`: datetime, null: true
- `created_at`: datetime, null: false
- `updated_at`: datetime, null: false

**Constraints**

- Unique index on `[:event_id, :email]` to prevent duplicate registrations per event.

**Rails model sketch**

- `belongs_to :event, inverse_of: :registrations`
- **Validations**:
  - presence: `event`, `email`, `status`
  - format: `email` (simple regex)
- Optional enum for status: registered / checked_in / cancelled.
- **Callbacks/helpers**:
  - `check_in!` sets status to "checked_in" and `check_in_at` to current time.
  - `cancel!` sets status to "cancelled" and `cancelled_at` to current time.

## Relationships and constraints

### ERD-style overview

- User
  - 1 → N organized_events (Events)
- Event
  - N → 1 organizer (User)
  - 1 → N registrations (Registrations)
- Registration
  - N → 1 event (Event)

**Key relational rules**

- A User can exist without events.
- An Event must belong to an organizer (User).
- A Registration must belong to an Event and must have an email.
- A Registration’s status must be one of the allowed values; transitions are controlled at the model/service level.

## Routes and object shapes

### REST routes (MVP)

- `GET /` → `events#index`
- `GET /events` → `events#index`
- `GET /events/:id` → `events#show`
- `POST /events` → `events#create`
- `PATCH/PUT /events/:id` → `events#update`
- `DELETE /events/:id` → `events#destroy`
- `POST /events/:event_id/registrations` → `registrations#create`
- `DELETE /events/:event_id/registrations/:id` → `registrations#destroy`
- `PATCH /events/:event_id/registrations/:id/check_in` → `registrations#check_in`

## Summary table

| Entity       | Purpose                              | Key fields (beyond id & timestamps)                                                                   |
| ------------ | ------------------------------------ | ----------------------------------------------------------------------------------------------------- |
| User         | Organizer account                    | first_name, last_name, email (unique), time_zone                                                      |
| Event        | Public event owned by a user         | organizer_id, title, description, location, starts_at, ends_at, capacity, status, registrations_count |
| Registration | Link attendee (by email) to an event | event_id, email, name, status, check_in_at, cancelled_at                                              |
