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

**Change:** Extracted hardcoded strings into the locale file.
**Reason:** To satisfy `Rails/I18nLocaleTexts` rule and support future translation/localization of the app.

**Key Changes:**

- Defined keys under `en.registrations` and `en.activerecord.errors.models.registration`.
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
