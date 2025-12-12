# RuboCop Fixes and Refactoring

## Overview

This document records the changes made to resolve RuboCop offenses and improve code quality in the EventEase application.

## 1. RuboCop Configuration

**File:** `.rubocop.yml`

**Change:** updated the manner in which extensions are loaded.
**Reason:** RuboCop now requires using `plugins:` instead of `require:` for loading extensions like `rubocop-rails` and `rubocop-capybara`.

```yaml
# Before
require:
  - rubocop-rails
  - rubocop-capybara

# After
plugins:
  - rubocop-rails
  - rubocop-capybara
```

## 2. Localization (I18n)

**Files:**

- `app/controllers/registrations_controller.rb`
- `app/models/registration.rb`
- `config/locales/en.yml`
- `app/controllers/events_controller.rb` (New)

**Change:** Extracted hardcoded strings into the locale file.
**Reason:** To satisfy `Rails/I18nLocaleTexts` rule and support future translation/localization of the app.

**Key Changes:**

- Defined keys under `en.registrations`, `en.events`, and `en.activerecord.errors.models.registration`.
- Replaced strings in controller and model with `t("key")` helpers.

## 3. User Model Associations

**File:** `app/models/user.rb`

**Change:**

1. Removed duplicate `has_many :events` association which was redundant with `has_many :organized_events`.
2. Added `dependent: :destroy` to `has_many :organized_events`.

**Reason:**

- **Redundancy:** The `events` association was defined with the exact same options as `organized_events`, just with a different name. `organized_events` is more descriptive.
- **Data Integrity (`Rails/HasManyOrHasOneDependent`):** RuboCop requires a `dependent` option to ensure referential integrity (e.g., deleting a user should delete their events).

```ruby
# Before
has_many :organized_events, class_name: "Event", foreign_key: "organizer_id", inverse_of: :organizer
has_many :events, class_name: "Event", foreign_key: "organizer_id", inverse_of: :organizer

# After
has_many :organized_events, class_name: "Event", foreign_key: "organizer_id", inverse_of: :organizer, dependent: :destroy
```

## Verification

Ran `rubocop -A` which is now passing with no offenses.

---

# Stimulus Registration Controller Implementation

## Overview

Implemented a Stimulus controller to handle registration form interactions, specifically disabling the submit button to prevent double submissions.

## 1. Stimulus Controller

**File:** `app/javascript/controllers/registration_controller.js`

**Logic:**

- Defines a `submitButton` target.
- `disable(event)` method: Changes button text to "Joining..." and sets the `disabled` attribute.

## 2. Event Show View

**File:** `app/views/events/show.html.erb`

**Changes:**

- Created the view to display event details.
- Added usage of the `registration` controller in the `form_with`.
- `data: { controller: "registration", action: "submit->registration#disable" }` on the form.
- `data: { registration_target: "submitButton" }` on the submit button.

---

# Check-in Controller and Event Search

## Overview

Implemented a Stimulus check-in controller for real-time feedback and a basic event search feature.

## 1. Stimulus Check-in Controller

**File:** `app/javascript/controllers/checkin_controller.js`

**Logic:**

- `confirm(event)`: Prevents default if not confirmed (optional), changes button text to "Checking in..." and disables it.

## 2. Attendees Check-in UI

**File:** `app/views/events/show.html.erb`

**Changes:**

- Added "Attendees" list section.
- Added "Check In" button for each registered attendee, connected to `checkin_controller`.

## 3. Basic Event Search

**File:** `app/controllers/events_controller.rb`

- Updated `index` action to filter by `params[:query]` using SQL `LIKE`.
- Fixed various syntax errors in the controller.

**File:** `app/views/events/index.html.erb`

- Added a search form (GET request) at the top of the page.
