# EventEase: Comprehensive Codebase Analysis & TODO List

**Generated:** December 11, 2025  
**Project Status:** Early MVP Stage (Weeks 1-3 of 5-week timeline completed)

---

## 📊 Executive Summary

**Completion Status:** ~60% (MVP Features) + Critical Issues + Enhancements Needed

### What's Working

✅ User authentication (Devise)  
✅ Event CRUD operations  
✅ Registration creation/cancellation  
✅ Check-in functionality (basic)  
✅ Database schema (3 core models)

### Critical Issues

❌ Gemfile dependency conflict (cloudinary missing, faraday-follow_redirects)  
❌ Routes duplication causing conflicts  
❌ Missing core functionality from spec  
❌ Minimal/no tests  
❌ Missing email system (Sidekiq, background jobs)  
❌ No AI features  
❌ Incomplete authorization checks

---

## 🔴 CRITICAL ISSUES (Fix Immediately)

### 1. **Gemfile Dependency Conflict**

**Severity:** HIGH  
**Impact:** Cannot run RuboCop, bundle verification fails

**Issue:**

- Gemfile lists `gem "cloudinary"` (line 79) but `faraday-follow_redirects` is missing
- Gemfile.lock is out of sync with current Gemfile
- RuboCop cannot run: `bundler: failed to load command: rubocop`

**Fix:**

```bash
# Option 1: If using Cloudinary for image uploads (observed in show.html.erb)
bundle update cloudinary faraday-follow_redirects
bundle install

# Option 2: If NOT using image uploads, remove cloudinary:
# Edit Gemfile, remove: gem "cloudinary"
# Edit app/views/events/show.html.erb, remove cloudinary image tag
bundle install
```

**Decision Required:** Does the project need Cloudinary image uploads? Check:

- `app/controllers/events_controller.rb` line 81 has `photos: []` in permit
- `app/views/events/show.html.erb` lines 1-3 use `cl_image_tag` (Cloudinary)

---

### 2. **Routes Configuration Has Duplicates & Conflicts**

**Severity:** HIGH  
**Impact:** Ambiguous routing, potential 404 errors, maintenance nightmare

**Current Issue in `config/routes.rb`:**

```ruby
# Lines 4-6: Resourceful routes (correct)
resources :events, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
  resources :registrations, only: [:create]
end

# Lines 19-28: DUPLICATE manual routes (problematic)
get "events/new", to: "indexs#new"        # ← Wrong controller! ("indexs" doesn't exist)
post "events", to: "indexs#create"        # ← Wrong controller!
get "events/:id/edit", to: "indexs#edit"  # ← Wrong controller!
patch "events/:id", to: "indexs#update"   # ← Wrong controller!
delete "events/:id", to: "indexs#destroy" # ← Wrong controller!
get "/events/:id", to: "indexs#show"      # ← Wrong controller!
```

**Fix Required:**

1. Remove lines 19-28 entirely (they're redundant with resourceful routes)
2. Verify controller is `events_controller.rb` not `indexs_controller.rb`
3. Add missing routes:
   - `check_in_event_path` → `events#check_in` (PATCH)
   - `dashboard` route currently points to `events#index`

**Corrected routes.rb:**

```ruby
Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  resources :events, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :registrations, only: [:create]
    member do
      get :check_in
    end
  end

  resources :registrations, only: [:destroy] do
    member do
      patch :check_in
    end
  end

  get "dashboard", to: "events#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

### 3. **Authorization Checks Incomplete**

**Severity:** MEDIUM  
**Impact:** Potential security vulnerability—any user can delete/edit any event

**Issues Found:**

**EventsController#index:**

```ruby
# Line 8: Shows ALL events, then overwrites with current_user.events
@popular_events = Event.popular      # Method doesn't exist!
@new_events     = Event.upcoming     # Method doesn't exist!
@events = Event.all                  # Should not be here
@events = current_user.events.includes(:registrations).order(starts_at: :asc) # Overwrites above
```

→ Fix: Remove lines 7-9, keep line 10 only

**EventsController#show, edit, update, destroy:**

```ruby
# Missing authorization! Should verify current_user == @event.organizer
before_action :set_event, only: %i[show edit update destroy check_in]
# But no check that current_user owns the event!
```

→ Fix: Add authorization helper or check in controller

**EventsController#check_in:**

```ruby
# Line 68: Authorization is present and correct ✓
unless @event.organizer == current_user
  redirect_to event_path(@event), alert: "..."
end
```

→ Pattern to replicate for edit/update/destroy

---

## 🟡 MISSING FILES & FEATURES

### Models Missing

1. **No Background Job Files**

   - Missing: `app/jobs/send_confirmation_email_job.rb`
   - Missing: `app/jobs/send_reminder_email_job.rb`
   - Missing: `app/jobs/send_announcement_job.rb`
   - **Impact:** Email notifications not implemented

2. **No Mailer Classes**

   - Missing: `app/mailers/registration_mailer.rb`
   - Missing: `app/mailers/event_mailer.rb`
   - **Impact:** Cannot send emails (Devise mailer exists, but not custom mailers)

3. **Missing Model Methods & Scopes**

**Event Model Missing:**

```ruby
# Scopes mentioned in EventsController but not implemented:
scope :popular       # Line 7 of events_controller.rb
scope :upcoming      # Line 8 of events_controller.rb

# Needed for spec features:
def is_full?
  return false if capacity.nil?
  registrations.where(status: "registered").count >= capacity
end

def available_spots
  return nil if capacity.nil?
  capacity - registrations.where(status: "registered").count
end

def confirmed_registrations_count
  registrations.where(status: ["registered", "checked_in"]).count
end

def registration_window_open?
  return true if registration_open_from.nil? || registration_open_until.nil?
  Time.current.between?(registration_open_from, registration_open_until)
end
```

**Registration Model Missing:**

```ruby
# Model has check_in! and cancel!, but missing:
def checked_in?
  status == "checked_in"
end

def confirmed?
  status != "cancelled"
end
```

### Controllers Missing

1. **Pages Controller** (exists but minimal)

   - Has `pages#home` but no implementation for:
     - Public event listing (non-authenticated users)
     - Event discovery/search
     - Landing page with AI features preview

2. **Missing API Endpoints** (if JSON API planned)
   - No `/api/events` endpoints
   - No `/api/registrations` endpoints

### Views/UI Missing or Incomplete

1. **Dashboard/Index Views**

   - `app/views/events/index.html.erb` - Exists but unclear if complete
   - Missing: Filter by date (code exists in controller but view doesn't use it)
   - Missing: Filter by location (code exists in controller but view doesn't use it)

2. **Check-in Interface**

   - `app/views/events/check_in.html.erb` - Exists
   - **Issue:** No search/filter for attendees (spec mentions "Quick search")
   - **Issue:** No real-time counter visible

3. **Missing Views from Spec**

   - No "event discovery" page (browse public events)
   - No "attendee export to CSV" UI
   - No "AI description generator" UI

4. **User Profile/Settings** (Not in Current Scope?)
   - No user profile view
   - No organizer settings page

### Configuration Missing

1. **No Sidekiq Configuration**

   - Missing: `config/sidekiq.yml`
   - Missing: `Procfile` or `Procfile.dev` (for development)
   - Missing: Redis configuration (commented out in Gemfile)

2. **No Email Configuration for Production**

   - `config/environments/production.rb` line 4: `host: "http://TODO_PUT_YOUR_DOMAIN_HERE"`
   - Missing: SendGrid/Mailgun configuration
   - Missing: Email credentials in credentials.yml

3. **Missing Environment Variables (.env)**
   - No `.env.example` or documented required vars
   - Needed for: Cloudinary, SendGrid, OpenAI, Redis, etc.

---

## 🟠 NEEDED CHANGES (Refactoring & Bug Fixes)

### 1. **Events Controller - Query Logic Bug**

**File:** `app/controllers/events_controller.rb`  
**Lines:** 5-26

**Current Code (BROKEN):**

```ruby
def index
  @popular_events = Event.popular      # ❌ Method doesn't exist!
  @new_events     = Event.upcoming      # ❌ Method doesn't exist!

  @events = Event.all                  # ❌ Shows ALL events to organizer
  @events = current_user.events.includes(:registrations).order(starts_at: :asc)

  if params[:query].present?           # ❌ Redundant conditionals
    @events = @events.where("title ILIKE ?", "%#{params[:query]}%")
  end

  if params[:location].present?        # ❌ Overwrites previous @events
    @events = @events.where("location ILIKE ?", "%#{params[:location]}%")
  end

  if params[:date].present?            # ❌ 'date' field doesn't exist in Event model
    @events = @events.where(date: params[:date])
  end

  @events = @events.where(             # ❌ Overwrites all previous filters!
    "title ILIKE :query OR location ILIKE :query",
    query: "%#{params[:query]}%"
  )
end
```

**Fix:**

```ruby
def index
  @events = current_user.events.includes(:registrations).order(starts_at: :asc)

  # Search by title or location
  if params[:query].present?
    @events = @events.where("title ILIKE ? OR location ILIKE ?",
                            "%#{params[:query]}%", "%#{params[:query]}%")
  end

  # Filter by location (optional)
  if params[:location].present?
    @events = @events.where("location ILIKE ?", "%#{params[:location]}%")
  end
end
```

### 2. **Registration Model - Validation Issue**

**File:** `app/models/registration.rb`  
**Line:** 6

**Current:**

```ruby
validates :email, uniqueness: { scope: :event_id }
```

**Issue:** Email validation format comes AFTER uniqueness check. Order matters for error messages.

**Fix:**

```ruby
validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP },
                  uniqueness: { scope: :event_id, message: "is already registered for this event" }
```

### 3. **Authorization Helper Missing**

**File:** Needs new file `app/controllers/concerns/authorizable.rb`

**Add:**

```ruby
module Authorizable
  extend ActiveSupport::Concern

  included do
    helper_method :can_edit?, :can_delete?, :can_check_in?
  end

  def authorize_event_owner!
    return if @event.organizer == current_user
    redirect_to events_path, alert: "Not authorized"
  end

  private

  def can_edit?(event)
    event.organizer == current_user
  end

  def can_delete?(event)
    event.organizer == current_user
  end

  def can_check_in?(event)
    event.organizer == current_user
  end
end
```

### 4. **Event Migration - Add Missing Columns**

**Issue:** Schema has columns but some constraints are missing

**Check if migration needed:**

- `registration_open_from` and `registration_open_until` - Present ✓
- `registrations_count` with counter_cache - Present ✓ but needs counter_cache in association
- `photos` (for Cloudinary) - Present in controller permit but NOT in schema!

**Fix:** Create migration if using Cloudinary:

```ruby
class AddPhotosToEvents < ActiveRecord::Migration[7.1]
  def change
    add_column :events, :photos, :json, array: true, default: []
  end
end
```

---

## 🔵 ENHANCEMENTS & FEATURE GAPS

### Priority 1: Email System (Week 4 in Spec)

**Missing Completely:**

1. SendGrid/Mailgun integration
2. Background jobs (Sidekiq + Redis)
3. Email templates
4. Scheduler for reminder emails

**Implementation Checklist:**

```
[ ] Add gems: sidekiq, redis, whenever
[ ] Create Redis configuration
[ ] Create Sidekiq configuration (config/sidekiq.yml)
[ ] Create RegistrationMailer (send_confirmation, send_reminder)
[ ] Create EventMailer (send_update_to_registrants)
[ ] Create SendConfirmationEmailJob
[ ] Create SendReminderEmailJob
[ ] Create SendAnnouncementJob
[ ] Setup ActionMailer for SendGrid/Mailgun
[ ] Add email views in app/views/mailers/
[ ] Add job scheduling with Whenever gem
[ ] Test email delivery in development
```

### Priority 2: AI Features (Week 5 in Spec)

**Missing Completely:**

1. OpenAI integration
2. AI description generator UI
3. AI prompt management

**Implementation Checklist:**

```
[ ] Add gem: ruby-openai
[ ] Create OpenAI configuration (credentials)
[ ] Create AiDescriptionGeneratorService
[ ] Add controller action: events#generate_description (POST)
[ ] Create Stimulus controller for real-time generation
[ ] Add UI button in event form: "✨ Generate with AI"
[ ] Handle streaming response from OpenAI
[ ] Add error handling for API failures
[ ] Add usage tracking (for cost control)
```

### Priority 3: Testing (Currently None)

**Current State:** Minimal/no tests

```
test/
├── models/
│   ├── event_test.rb           # Empty
│   ├── registration_test.rb    # Empty
│   └── user_test.rb            # Empty
├── controllers/
│   └── events_controller_test.rb # Empty
└── system/                      # No tests
```

**Implementation Checklist:**

```
[ ] Setup RSpec (replace Test::Unit)
[ ] Add gems: rspec-rails, factory_bot_rails, shoulda-matchers
[ ] Create factories for User, Event, Registration
[ ] Write model tests:
    - User validations & associations
    - Event validations, scopes, capacity checks
    - Registration uniqueness, status transitions
[ ] Write controller tests:
    - Authentication requirements
    - Authorization (owner-only actions)
    - CRUD operations
    - Error handling
[ ] Write integration tests:
    - Registration flow (create → show → check_in → destroy)
    - Search/filter
[ ] Setup CI/CD with GitHub Actions (test on push)
[ ] Aim for >80% coverage
```

### Priority 4: Public Event Discovery (Week 2+ in Spec)

**Missing:**

- Public event listing (not scoped to current user)
- Event search/filtering for guests
- Event filtering by date, location, category

**Implementation Checklist:**

```
[ ] Create PagesController#events (public listing)
[ ] Add scopes to Event model:
    - scope :published, -> { where(status: 'published') }
    - scope :upcoming, -> { where('starts_at > ?', Time.current) }
    - scope :past, -> { where('starts_at < ?', Time.current) }
    - scope :by_location, ->(loc) { where('location ILIKE ?', "%#{loc}%") }
    - scope :by_title, ->(q) { where('title ILIKE ?', "%#{q}%") }
[ ] Create view: app/views/pages/events.html.erb
[ ] Add search filters (title, location, date range)
[ ] Add pagination (kaminari gem)
[ ] Make event cards responsive (Bootstrap grid)
```

### Priority 5: CSV Export & Data Handling

**Missing:**

- CSV export of attendees
- Bulk operations on registrations

**Implementation Checklist:**

```
[ ] Add gem: csv
[ ] Create RegistrationExporter service
[ ] Add controller action: events#export_attendees (GET)
[ ] Generate CSV with: event_title, name, email, status, check_in_time
[ ] Add button in event show view
[ ] Handle edge cases: UTF-8, special chars, empty list
```

### Priority 6: Real-Time Updates (Hotwire/Turbo)

**Current State:** Uses Turbo but minimal real-time features

**Implementation Checklist:**

```
[ ] Real-time registration counter update (on show page)
[ ] Real-time check-in counter (on check_in page)
[ ] Attendee list updates when someone registers/cancels
[ ] Use Turbo Streams for live updates:
    - POST /registrations updates counter via Turbo Stream
    - PATCH check_in updates attendee row via Turbo Stream
[ ] Update check_in.html.erb to use Turbo Streams
```

### Priority 7: UI/UX Polish (Week 5 in Spec)

**Current State:** Bootstrap 5, minimal styling

**Needed:**

- Notion-style design refinement
- Better error messages & flash styling
- Mobile responsiveness testing
- Accessibility (WCAG AA)
- Dark mode (optional)

**Implementation Checklist:**

```
[ ] Audit mobile responsiveness (iPhone, Android)
[ ] Improve card designs (border, shadow, spacing)
[ ] Better form styling & validation feedback
[ ] Improve navbar: active links, user menu
[ ] Add loading states & spinners
[ ] Improve empty states ("No events created yet")
[ ] Test contrast ratios for accessibility
[ ] Add skip links for keyboard nav
[ ] Test with screen reader
```

---

## 🎯 Missing Model Scopes & Methods

### Event Model

```ruby
# Add to app/models/event.rb:

scope :published, -> { where(status: 'published') }
scope :upcoming, -> { where('starts_at > ?', Time.current).order(starts_at: :asc) }
scope :past, -> { where('starts_at < ?', Time.current) }
scope :popular, -> { joins(:registrations).group('events.id').order('COUNT(*) DESC') }
scope :by_location, ->(loc) { where('location ILIKE ?', "%#{loc}%") if loc.present? }

# Add counter_cache to association:
has_many :registrations, dependent: :destroy, inverse_of: :event, counter_cache: true

# Add instance methods:
def is_full?
  return false if capacity.nil?
  registrations.where(status: ['registered', 'checked_in']).count >= capacity
end

def available_spots
  return nil if capacity.nil?
  capacity - registrations.where(status: ['registered', 'checked_in']).count
end

def remaining_spots
  available_spots  # Alias for spec compatibility
end

def confirmed_registrations_count
  registrations.where.not(status: 'cancelled').count
end

def checked_in_count
  registrations.where(status: 'checked_in').count
end

def registration_window_open?
  return true if registration_open_from.blank? || registration_open_until.blank?
  Time.current.between?(registration_open_from, registration_open_until)
end

def can_register?
  return false if !registration_window_open?
  return true if capacity.nil?
  !is_full?
end
```

### User Model

```ruby
# Already has:
validates :first_name, presence: true ✓
validates :last_name, presence: true ✓
has_many :events, class_name: "Event", foreign_key: "organizer_id" ✓

# Add:
has_many :organized_events, class_name: "Event", foreign_key: "organizer_id", inverse_of: :organizer
# (alias for clarity; current code uses both)

def full_name
  "#{first_name} #{last_name}"
end

def organized_events_count
  events.count
end
```

---

## 📋 File Checklist: What Exists vs. Missing

### Controllers (4/5 exist)

- ✅ `app/controllers/events_controller.rb` - Exists, needs fixes
- ✅ `app/controllers/registrations_controller.rb` - Exists, mostly complete
- ✅ `app/controllers/pages_controller.rb` - Exists, minimal
- ✅ `app/controllers/application_controller.rb` - Exists
- ❌ `app/controllers/api/` - Missing (if JSON API needed)

### Models (3/6 exist)

- ✅ `app/models/user.rb` - Exists
- ✅ `app/models/event.rb` - Exists, needs scopes & methods
- ✅ `app/models/registration.rb` - Exists, needs methods
- ❌ `app/models/concerns/` - Missing helpers/validators
- ❌ Background job models (discussed below)
- ❌ `app/models/event_category.rb` - If using categories (spec mentions optional)

### Mailers (1/3 exist)

- ✅ `app/mailers/application_mailer.rb` - Exists but empty
- ❌ `app/mailers/registration_mailer.rb` - Missing
- ❌ `app/mailers/event_mailer.rb` - Missing

### Background Jobs (0/3 exist)

- ❌ `app/jobs/send_confirmation_email_job.rb` - Missing
- ❌ `app/jobs/send_reminder_email_job.rb` - Missing
- ❌ `app/jobs/send_announcement_job.rb` - Missing

### Views (8/12+ exist)

- ✅ `app/views/events/index.html.erb`
- ✅ `app/views/events/show.html.erb`
- ✅ `app/views/events/new.html.erb`
- ✅ `app/views/events/edit.html.erb`
- ✅ `app/views/events/check_in.html.erb`
- ✅ `app/views/pages/home.html.erb`
- ✅ `app/views/shared/` - navbar, flashes, form
- ✅ `app/views/devise/` - Devise forms
- ❌ `app/views/events/_attendee_row.html.erb` - For check-in list (might be inline)
- ❌ `app/views/pages/events.html.erb` - Public event listing
- ❌ Email templates (`app/views/registration_mailer/`, etc.)

### JavaScript/Stimulus (4/5 exist)

- ✅ `app/javascript/controllers/registration_controller.js`
- ✅ `app/javascript/controllers/checkin_controller.js`
- ✅ `app/javascript/controllers/hello_controller.js`
- ✅ `app/javascript/controllers/application.js`
- ❌ `app/javascript/controllers/ai_description_controller.js` - For AI feature

### Configuration (Missing/Incomplete)

- ❌ `config/sidekiq.yml` - Not created
- ❌ `Procfile.dev` - Not created (for local Sidekiq)
- ❌ `.env.example` - Not created
- ❌ `config/credentials.yml.enc` - Needs OpenAI, SendGrid keys
- ✅ `config/initializers/devise.rb` - Exists
- ✅ `config/initializers/simple_form.rb` - Exists

### Tests (0/10 exist)

- ❌ Model tests (user, event, registration)
- ❌ Controller tests (events, registrations)
- ❌ Feature/Integration tests
- ❌ Mailer tests
- ❌ Job tests

---

## 🚀 Implementation Priority Roadmap

### Phase 1: FIX CRITICAL ISSUES (1-2 days)

1. ✅ Resolve Gemfile/Bundler conflicts
2. ✅ Fix routes.rb duplication
3. ✅ Fix EventsController#index logic
4. ✅ Add authorization checks to edit/update/destroy

### Phase 2: COMPLETE CORE MVP (3-5 days)

1. ✅ Add missing scopes & methods to Event model
2. ✅ Ensure registration flow is fully functional
3. ✅ Complete check-in UI (search, counter)
4. ✅ Add CSV export
5. ✅ Public event discovery page

### Phase 3: EMAIL SYSTEM (3-4 days)

1. ✅ Setup Sidekiq + Redis
2. ✅ Create mailers & jobs
3. ✅ Configure SendGrid
4. ✅ Setup job scheduling

### Phase 4: TESTING (2-3 days)

1. ✅ Setup RSpec
2. ✅ Write model tests
3. ✅ Write controller tests
4. ✅ Setup CI/CD

### Phase 5: AI FEATURES (2-3 days)

1. ✅ OpenAI integration
2. ✅ Description generator
3. ✅ Streaming responses

### Phase 6: POLISH & DEPLOYMENT (2-3 days)

1. ✅ UI/UX refinements
2. ✅ Mobile responsiveness
3. ✅ Accessibility audit
4. ✅ Production deployment

---

## 📝 Summary: TODO Items by Category

### BUGS (Must Fix)

- [ ] Gemfile: Remove cloudinary OR install missing dependencies
- [ ] routes.rb: Remove duplicate manual routes (lines 19-28)
- [ ] events_controller.rb: Fix #index query logic (remove .popular/.upcoming calls)
- [ ] events_controller.rb: Add authorization to edit/update/destroy actions
- [ ] event.rb: Fix counter_cache setup

### MISSING FILES (Must Create)

- [ ] app/mailers/registration_mailer.rb
- [ ] app/mailers/event_mailer.rb
- [ ] app/jobs/send_confirmation_email_job.rb
- [ ] app/jobs/send_reminder_email_job.rb
- [ ] app/jobs/send_announcement_job.rb
- [ ] config/sidekiq.yml
- [ ] Procfile.dev
- [ ] .env.example
- [ ] app/controllers/concerns/authorizable.rb
- [ ] app/views/pages/events.html.erb
- [ ] Email templates in app/views/registration_mailer/ and app/views/event_mailer/

### MISSING METHODS/SCOPES

- [ ] Event: scope :published, :upcoming, :past, :popular, :by_location
- [ ] Event: methods is_full?, available_spots, confirmed_registrations_count, etc.
- [ ] Registration: methods checked_in?, confirmed?
- [ ] User: method full_name

### MISSING FEATURES

- [ ] Sidekiq setup & configuration
- [ ] Email system (mailers + jobs)
- [ ] Background job scheduling
- [ ] OpenAI integration
- [ ] AI description generator UI
- [ ] Public event discovery
- [ ] CSV export of attendees
- [ ] Real-time Turbo Stream updates
- [ ] Search/filter for check-in attendees

### MISSING TESTS

- [ ] All model tests
- [ ] All controller tests
- [ ] Integration tests
- [ ] Feature tests with Capybara

### ENHANCEMENTS (Nice to Have)

- [ ] Event categories/tags
- [ ] User profiles
- [ ] Event reviews/ratings
- [ ] Recurring events
- [ ] QR code check-in
- [ ] Ticket pricing (Stripe)
- [ ] Dark mode
- [ ] Geolocation search
- [ ] Push notifications
