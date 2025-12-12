# EventEase — Full-Scale Project Specification

**Le Wagon Bootcamp Project**  
**Version 1.0**  
**Date: December 2025**

---

## 📋 Executive Summary

**EventEase** is a lightweight, minimalist micro-SaaS platform for managing small, local events. It solves the everyday chaos of organizing meetups, student groups, workshops, and sports clubs through WhatsApp by providing a clean, intuitive interface for event creation, registration, attendee tracking, and check-in management.

**Target Timeline:** 5 weeks (bootcamp project week + post-project polish)  
**Team Size:** 1-3 developers  
**Technology Stack:** Ruby on Rails 7, PostgreSQL, Hotwire/Turbo, Sidekiq, Redis, SendGrid/Mailgun

---

## 🎯 Problem Statement

### Current Pain Points

1. **Chaotic Sign-ups:** WhatsApp group chats create confusion about who's attending
2. **No Headcount Clarity:** Organizers can't easily track how many people will show up
3. **Lost Messages:** Important updates get buried in group chats
4. **Manual Check-ins:** No digital way to verify who actually attended
5. **Scale Limitations:** Eventbrite and Meetup are overkill for small, local events

### Why Existing Solutions Don't Work

- **Eventbrite:** Designed for large-scale ticketed events; expensive, overly complex
- **Meetup:** Requires lengthy profiles, groups, and social setup; too heavy
- **Simple forms (Google Forms):** No real-time updates, no check-in capability
- **Spreadsheets:** No live updates or participant notifications

---

## 💡 Solution Overview

**EventEase** is a one-stop event management platform that makes organizing small events as simple as:

1. **Create** an event in 30 seconds
2. **Share** a link with potential attendees
3. **Track** who's coming and manage the capacity
4. **Check-in** attendees on the day
5. **Communicate** updates to all registered participants

**Core Value Proposition:** Clarity, simplicity, and real-time visibility—everything organizers need, nothing they don't.

---

## ✨ Core MVP Features

### 1. **Event Creation & Management**
- Organizer creates event with:
  - Title, description, date/time, location
  - Capacity limit (e.g., max 20 attendees)
  - Category (optional: sports, workshop, meetup, etc.)
- Organizers can edit event details before the event
- Auto-generated shareable event URL
- Event preview page (public-facing)

### 2. **User Registration & Cancellation**
- One-click registration: Users join with minimal friction
  - Option: No account required (email-only registration)
  - Or: Simple account creation with email/password
- Live slot counter: "12/20 seats taken"
- Ability to cancel registration at any time
- View registered attendees (organizer-only)

### 3. **Attendee Management**
- Real-time attendee list (organizer dashboard)
- Filter/search attendees by name
- Mark attendees as "checked in" on event day
- Export attendee list (CSV)
- Capacity warning when event nears capacity

### 4. **Event Discovery**
- Homepage event listing (if public discovery enabled)
- Search events by:
  - Name/title
  - Location (text search, not geolocation initially)
  - Date range
- Filter by category (optional)
- "Upcoming" vs. "Past" event tabs

### 5. **Email Notifications (Sidekiq Background Jobs)**
- **Confirmation email** on registration
- **Cancellation email** on removal
- **24-hour reminder email** before event (scheduled job)
- **Organizer notifications** when new registrations arrive
- Simple, clean email templates

### 6. **Organizer Check-in Mode**
- Mobile-friendly check-in interface
- Mark attendees as checked in (tick/check icon)
- Display "Checked In: 14/20" counter
- Quick search to find attendee by name

### 7. **User Authentication**
- Email/password signup and login
- Optional: Single sign-on (Google OAuth)
- Password reset functionality
- Session management

---

## 🎨 UI/UX Principles

- **Notion-style design:** Clean, minimal, card-based layout
- **Mobile-first responsive design** (works on phones and tablets)
- **High contrast & accessibility:** WCAG AA standards
- **Dark mode support** (optional enhancement)
- **Intuitive iconography** (calendar, location, users, etc.)
- **Minimal friction:** Reduce clicks, maximize clarity
- **Real-time UI updates** (using Hotwire/Turbo for live attendee count)

---

## 🤖 AI Add-Ons (MVP Includes at Least 1)

### Option 1: AI Description Generator ⭐ **RECOMMENDED FOR MVP**
- Organizer enters event title + a few keywords
- AI generates a clean, professional description
- Organizer can accept, edit, or regenerate
- **Implementation:** OpenAI GPT-4 API (streaming response)
- **Example:**
  - Input: "JavaScript Meetup, Düsseldorf, Beginners"
  - Output: "Join us for a beginner-friendly JavaScript meetup in Düsseldorf! This session covers modern ES6 features and best practices. Perfect for anyone looking to level up their JavaScript skills..."

### Option 2: AI Announcement Writer
- Organizer types a short message: "Location changed to Marienplatz 10"
- AI formats it as a professional announcement
- Auto-sends to all registered attendees
- **Example:**
  - Input: "10 min late"
  - Output: "Good news! We're running only 10 minutes late. See you soon!"

### Option 3: AI Scheduling Assistant
- Organizer enters 3-4 possible date/time slots
- AI suggests optimal time based on:
  - Historical attendance patterns
  - Day of week/time heuristics
  - Attendee timezone considerations
- **Implementation:** Simple ML-based recommendation (no complex ML required)

**MVP Recommendation:** Start with **AI Description Generator** (highest user value, simplest integration).

---

## 🏗️ Technical Architecture

### Database Schema

```plaintext
users
├── id (PK)
├── email (UNIQUE)
├── password_digest
├── first_name
├── last_name
├── created_at
└── updated_at

events
├── id (PK)
├── user_id (FK → users, organizer)
├── title
├── description
├── date_time
├── location
├── capacity
├── category (enum: meetup, workshop, sports, student, company, other)
├── status (enum: draft, published, cancelled, completed)
├── created_at
└── updated_at

registrations
├── id (PK)
├── event_id (FK)
├── user_id (FK)
├── email (for email-only guests)
├── checked_in (boolean, default: false)
├── checked_in_at (timestamp)
├── registered_at
├── cancelled_at
└── updated_at

email_logs
├── id (PK)
├── event_id (FK)
├── recipient_email
├── email_type (enum: confirmation, reminder, cancellation, announcement)
├── sent_at
└── status (enum: pending, sent, failed)
```

### Ruby Gems & Dependencies

```ruby
# Authentication
gem 'devise'                    # User authentication
gem 'pundit'                    # Authorization (organizer vs attendee)

# Background Jobs & Scheduling
gem 'sidekiq'                   # Background job processor
gem 'sidekiq-scheduler'         # Job scheduling (24h reminders)

# Email & Notifications
gem 'sendgrid-ruby'             # Email service provider
# OR
gem 'mailgun-ruby'              # Alternative email provider

# AI Integration
gem 'ruby-openai'               # OpenAI API client

# Frontend & UI
gem 'rails-html-sanitizer'      # Safe HTML rendering
gem 'kaminari'                  # Pagination

# Database & Data
gem 'pg'                        # PostgreSQL adapter
gem 'redis'                     # Redis caching & Sidekiq

# Testing & Development
group :development, :test do
  gem 'rspec-rails'             # RSpec testing framework
  gem 'factory_bot_rails'       # Test data factories
  gem 'faker'                   # Generate fake data
end

# Hotwire (Real-time UI updates)
# Included by default in Rails 7
gem 'turbo-rails'               # Turbo for real-time updates
gem 'stimulus-rails'            # Stimulus controllers
```

### API Endpoints (RESTful)

```plaintext
PUBLIC ROUTES:
GET    /                           → Home/landing page
GET    /events                      → Browse all events
GET    /events/:id                  → Event details page
POST   /registrations               → Register for event
DELETE /registrations/:id           → Cancel registration

AUTHENTICATED (User/Organizer):
GET    /dashboard                   → User dashboard
GET    /my-events                   → Organizer's events
POST   /events                      → Create new event
GET    /events/:id/edit             → Edit event form
PATCH  /events/:id                  → Update event
DELETE /events/:id                  → Delete event
GET    /events/:id/attendees        → Attendee list (organizer-only)
POST   /events/:id/check-in         → Check-in interface
PATCH  /registrations/:id/check-in  → Mark as checked in
GET    /events/:id/export           → Export attendees (CSV)

AI ENDPOINTS:
POST   /ai/generate-description     → AI description generator
POST   /ai/write-announcement       → AI announcement formatter
POST   /ai/suggest-time             → AI scheduling assistant
```

### Background Jobs (Sidekiq)

```ruby
# app/jobs/send_confirmation_email_job.rb
class SendConfirmationEmailJob < ApplicationJob
  queue_as :default
  
  def perform(registration_id)
    registration = Registration.find(registration_id)
    EventMailer.confirmation_email(registration).deliver_now
  end
end

# app/jobs/send_reminder_email_job.rb
class SendReminderEmailJob < ApplicationJob
  queue_as :default
  
  def perform(event_id)
    event = Event.find(event_id)
    event.registrations.each do |registration|
      EventMailer.reminder_email(registration).deliver_now
    end
  end
end

# Sidekiq Scheduler: Schedule 24h reminder
# config/sidekiq.yml
:scheduler:
  :schedule:
    send_event_reminder:
      cron: '0 9 * * *'  # 9 AM daily
      class: EventReminderSchedulerJob
```

### Deployment Architecture

```
┌─────────────────────────────────────┐
│    Render/Railway/Heroku Rails App  │
│    (Web Server: Puma)               │
│    - HTTP/HTTPS requests            │
│    - User authentication            │
│    - Event CRUD operations          │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        │             │
   ┌────▼─────┐  ┌───▼────────┐
   │PostgreSQL│  │ Redis Queue │
   │Database  │  │(Sidekiq)    │
   └──────────┘  └───┬────────┘
                     │
              ┌──────▼──────┐
              │ Sidekiq     │
              │ Worker      │
              │ (Background │
              │  Jobs)      │
              └─────┬──────┘
                    │
           ┌────────┴────────┐
           │                 │
      ┌────▼────┐    ┌──────▼─────┐
      │SendGrid │    │OpenAI API   │
      │(Email)  │    │(AI features)│
      └─────────┘    └─────────────┘
```

---

## 📅 Project Timeline (5 Weeks)

### **Week 1: Foundation & Setup**
- [ ] Setup Rails 7 app, PostgreSQL, Devise authentication
- [ ] Design database schema (users, events, registrations)
- [ ] Create models with associations
- [ ] Setup Git repository and GitHub

**Deliverable:** Working authentication, basic models

---

### **Week 2: Core Event Management (Create, Read, Update)**
- [ ] Build Event model with validations
- [ ] Create event CRUD controllers & views
- [ ] Design event creation form
- [ ] Build event details page
- [ ] Organizer dashboard (list organizer's events)
- [ ] Event editing & deletion for organizers

**Deliverable:** Organizers can create, view, edit events

---

### **Week 3: Registration & Attendee Management**
- [ ] Build Registration model
- [ ] Create one-click registration flow
- [ ] Build real-time attendee counter (Hotwire/Turbo)
- [ ] Attendee list view (organizer-only)
- [ ] Cancellation functionality
- [ ] Capacity validation & warnings
- [ ] Export attendees to CSV

**Deliverable:** Users can register/cancel; organizers see real-time attendee lists

---

### **Week 4: Email Notifications & Background Jobs**
- [ ] Setup Sidekiq + Redis
- [ ] Configure SendGrid/Mailgun
- [ ] Build email templates (confirmation, reminder, announcement)
- [ ] Implement SendConfirmationEmailJob
- [ ] Implement SendReminderEmailJob with scheduling
- [ ] Setup Sidekiq scheduler
- [ ] Test email delivery (staging environment)

**Deliverable:** Automated emails working; 24h reminders scheduled

---

### **Week 5: AI Features, Check-in, Polish & Deployment**
- [ ] Integrate OpenAI API for AI Description Generator
- [ ] Build AI description UI & generation flow
- [ ] Implement check-in interface (mobile-friendly)
- [ ] Real-time check-in counter
- [ ] Search/filter for attendee check-in
- [ ] UI polish (Notion-style design, accessibility)
- [ ] Security hardening (CSRF, SQL injection prevention)
- [ ] Setup production deployment (Render/Railway)
- [ ] Performance testing & optimization

**Deliverable:** Fully functional MVP with AI features, deployed to production

---

## 🚀 Deployment & DevOps

### Production Deployment Steps

1. **Database Migration:**
   ```bash
   rails db:create RAILS_ENV=production
   rails db:migrate RAILS_ENV=production
   ```

2. **Environment Variables (Render/Railway):**
   ```
   RAILS_MASTER_KEY=xxx
   DATABASE_URL=postgresql://...
   REDIS_URL=redis://...
   SENDGRID_API_KEY=xxx
   OPENAI_API_KEY=xxx
   DEVISE_SECRET_KEY=xxx
   ```

3. **Sidekiq Background Worker Setup:**
   - Create separate Sidekiq worker process (on Render: Background Worker)
   - Start command: `bundle exec sidekiq -c 5`

4. **Rails Web Service:**
   - Create Web Service on Render/Railway
   - Build: `bundle install; bundle exec rake assets:precompile`
   - Start: `bundle exec puma -t 5:5 -w 3`

5. **Redis Setup:**
   - Provision Redis instance (Render: Managed Redis, or upstash.com)
   - Add REDIS_URL to environment variables

### CI/CD Pipeline (GitHub Actions)

```yaml
name: CI/CD
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.2
          bundler-cache: true
      - run: bundle exec rails db:create
      - run: bundle exec rails db:migrate
      - run: bundle exec rspec
```

---

## 🧪 Testing Strategy

### Unit Tests (RSpec)
```ruby
# spec/models/event_spec.rb
describe Event, type: :model do
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:date_time) }
  it { should validate_presence_of(:capacity) }
  it { should have_many(:registrations) }
  it { should belong_to(:user) }
  
  describe '#is_full?' do
    it 'returns true when at capacity' do
      event = create(:event, capacity: 2)
      create_list(:registration, 2, event: event)
      expect(event.is_full?).to eq(true)
    end
  end
end
```

### Integration Tests
```ruby
# spec/requests/events_spec.rb
describe 'Event Management', type: :request do
  describe 'POST /events' do
    it 'creates a new event' do
      user = create(:user)
      sign_in(user)
      expect {
        post '/events', params: { event: attributes_for(:event) }
      }.to change(Event, :count).by(1)
    end
  end
end
```

### Feature Tests (Capybara)
```ruby
# spec/features/registration_spec.rb
feature 'Event Registration', js: true do
  scenario 'User registers for event' do
    event = create(:event)
    visit event_path(event)
    click_button 'Register'
    expect(page).to have_content('You are registered!')
  end
end
```

---

## 🔒 Security Considerations

### Authentication & Authorization
- Use Devise for secure user authentication
- Use Pundit for role-based authorization (organizer vs attendee)
- Validate that only event organizer can edit/delete events
- Protect attendee data (PII)

### Data Protection
- CSRF token validation (Rails default)
- SQL injection prevention (Rails ORM protection)
- XSS protection (Rails sanitization)
- Rate limiting on API endpoints (Rack::Attack gem)
- Password reset token expiration

### Email Security
- Verify SendGrid API key is secure (environment variables)
- Implement unsubscribe links in emails (SendGrid feature)
- Use transactional email service (SendGrid/Mailgun)

### API Security
- No sensitive data in URLs (use POST for sensitive operations)
- Validate all user input
- Log security events (failed logins, permission denials)

---

## 📊 Analytics & Monitoring

### Metrics to Track
- User signups & retention
- Events created per day
- Average registration rate per event
- Email delivery success rate
- Background job execution time
- API response times

### Tools
- **Sidekiq Web Dashboard:** Monitor background jobs
- **Render/Railway Logs:** Application logs & errors
- **Sentry.io:** Error tracking
- **Google Analytics:** User behavior (optional)

---

## 🎨 UI/UX Wireframes (Text Description)

### 1. **Home/Landing Page**
```
┌─────────────────────────────────┐
│ EventEase | Sign In | Sign Up    │
├─────────────────────────────────┤
│                                 │
│    Headline: "Organize your     │
│    event in 30 seconds"         │
│                                 │
│    [Create Event] button        │
│                                 │
├─────────────────────────────────┤
│ Upcoming Events (Browse)         │
│ ┌──────────┐ ┌──────────┐       │
│ │JS Meetup │ │Yoga Class│       │
│ │Fri 7 Dec │ │Sat 8 Dec │       │
│ │12/20     │ │8/15      │       │
│ └──────────┘ └──────────┘       │
└─────────────────────────────────┘
```

### 2. **Event Creation Form**
```
┌──────────────────────────────────┐
│ Create Event                      │
├──────────────────────────────────┤
│ Event Title:                      │
│ [________________________] (req)   │
│                                   │
│ Date & Time:                      │
│ [________] [________] (req)       │
│                                   │
│ Location:                         │
│ [________________________] (req)   │
│                                   │
│ Capacity:                         │
│ [________] attendees (req)        │
│                                   │
│ Description:                      │
│ [_________________________]       │
│ [_________________________]       │
│                                   │
│ [✨ Generate with AI] [Skip]     │
│                                   │
│ [Save & Publish] [Save Draft]    │
└──────────────────────────────────┘
```

### 3. **Event Details Page (Public)**
```
┌──────────────────────────────────┐
│ EventEase | Dashboard | Sign Out  │
├──────────────────────────────────┤
│ JavaScript Meetup                 │
│ 📅 Friday, December 7, 2025       │
│ ⏰ 7:00 PM - 9:00 PM              │
│ 📍 Düsseldorf, Germany            │
│ 👥 12/20 seats taken              │
│                                   │
│ Description:                      │
│ Join us for a JavaScript meetup...│
│                                   │
│ [Register] (or [Cancel] if user   │
│  is already registered)           │
│                                   │
│ [Share] [Export]                  │
└──────────────────────────────────┘
```

### 4. **Attendee Check-in (Mobile)**
```
┌──────────────────────────────────┐
│ JavaScript Meetup - Check-in      │
│ Dec 7, 2025 | 7:00 PM            │
├──────────────────────────────────┤
│ Checked In: 8/20                  │
│                                   │
│ 🔍 [Search by name___]            │
│                                   │
│ ✅ John Smith                     │
│ ☐ Jane Doe                        │
│ ✅ Mike Johnson                   │
│ ☐ Sarah Williams                  │
│                                   │
│ [Refresh] [Done]                  │
└──────────────────────────────────┘
```

---

## 📈 Success Metrics

### MVP Success Criteria
- [ ] 0 critical bugs in staging environment
- [ ] All core features deployed and working
- [ ] Email delivery >95% success rate
- [ ] Page load time <2 seconds
- [ ] Mobile responsiveness verified on iOS & Android
- [ ] AI feature generates reasonable descriptions
- [ ] Organizer can manage 50+ attendees without lag

### Post-Launch Metrics (Nice to Have)
- 50+ events created in first month
- 70%+ registration completion rate
- 80%+ email open rate
- <1% background job failure rate

---

## 🔮 Future Enhancement Features (Post-MVP)

### Phase 2: Discovery & Social
- [ ] Geolocation-based event discovery
- [ ] Event categories & tags
- [ ] User profiles & preferences
- [ ] "Attending" badges for user credibility
- [ ] Event ratings & reviews

### Phase 3: Advanced Event Management
- [ ] Recurring events
- [ ] Ticket pricing & payment (Stripe integration)
- [ ] QR code check-in
- [ ] Event announcements & push notifications
- [ ] Waitlist functionality

### Phase 4: Community & Engagement
- [ ] Event reviews & ratings
- [ ] User reputation scores
- [ ] Following/discovering organizers
- [ ] Event recommendations via ML

### Phase 5: Admin & Analytics
- [ ] Admin dashboard
- [ ] Event analytics (conversion, no-show rate)
- [ ] Organizer analytics & insights
- [ ] API for third-party integrations

---

## 👥 User Stories

### Organizer User Stories
1. **As an organizer**, I want to create an event with title, date, location, and capacity so that I can advertise it to potential attendees.
2. **As an organizer**, I want to view a list of all registered attendees so that I know how many people are coming.
3. **As an organizer**, I want to check in attendees on event day so that I can track who actually shows up.
4. **As an organizer**, I want to send announcements to all registered attendees so that I can communicate last-minute updates.
5. **As an organizer**, I want AI to generate an event description for me so that I don't have to write it myself.

### Attendee User Stories
1. **As an attendee**, I want to register for an event with one click so that I can quickly confirm my attendance.
2. **As an attendee**, I want to see how many seats are available so that I know if the event is full.
3. **As an attendee**, I want to receive a reminder email 24 hours before the event so that I don't forget.
4. **As an attendee**, I want to cancel my registration if my plans change so that the seat opens up for someone else.
5. **As an attendee**, I want to browse upcoming events so that I can discover new ones.

---

## 📝 Code Example: Event Model

```ruby
# app/models/event.rb
class Event < ApplicationRecord
  belongs_to :user  # Organizer
  has_many :registrations, dependent: :destroy
  has_many :registered_users, through: :registrations, source: :user
  
  enum category: { meetup: 0, workshop: 1, sports: 2, student: 3, company: 4, other: 5 }
  enum status: { draft: 0, published: 1, cancelled: 2, completed: 3 }
  
  validates :title, :date_time, :location, :capacity, presence: true
  validates :capacity, numericality: { greater_than: 0 }
  validates :title, length: { minimum: 3, maximum: 255 }
  
  scope :published, -> { where(status: :published) }
  scope :upcoming, -> { where('date_time > ?', Time.current).order(date_time: :asc) }
  scope :past, -> { where('date_time <= ?', Time.current).order(date_time: :desc) }
  
  def is_full?
    registrations.where(cancelled_at: nil).count >= capacity
  end
  
  def available_slots
    capacity - registrations.where(cancelled_at: nil).count
  end
  
  def attendee_count
    registrations.where(cancelled_at: nil).count
  end
  
  def checked_in_count
    registrations.where.not(checked_in_at: nil).count
  end
  
  def schedule_reminder_email
    SendReminderEmailJob.set(wait_until: date_time - 24.hours)
                        .perform_later(self.id)
  end
  
  after_create :schedule_reminder_email
end
```

---

## 📋 Checklist for Launch

### Backend Readiness
- [ ] All models complete with validations
- [ ] All migrations written and tested
- [ ] Database indexes optimized (especially for event/registration queries)
- [ ] Devise authentication working
- [ ] Pundit authorization policies written
- [ ] Sidekiq jobs tested locally
- [ ] SendGrid/Mailgun integration verified
- [ ] OpenAI API integration tested
- [ ] Error handling & logging setup
- [ ] Rate limiting implemented

### Frontend Readiness
- [ ] All views created (no ERB stubs)
- [ ] Responsive design tested on mobile/tablet/desktop
- [ ] Forms validate client-side & server-side
- [ ] UI components consistent with design system
- [ ] Accessibility (WCAG AA) verified
- [ ] Dark mode tested (if included)
- [ ] Loading states & error messages present

### Testing Readiness
- [ ] Unit tests: >80% coverage
- [ ] Integration tests: Core flows tested
- [ ] Feature tests: Main user journeys tested
- [ ] All tests passing locally

### Deployment Readiness
- [ ] Production environment variables set
- [ ] Database backup strategy defined
- [ ] Redis caching configured
- [ ] SSL certificate setup
- [ ] CDN for static assets (optional)
- [ ] Monitoring & error tracking (Sentry) setup
- [ ] Logs configured for production

### Security Readiness
- [ ] CSRF protection enabled
- [ ] SQL injection tests passed
- [ ] XSS protection verified
- [ ] Authentication flow secured
- [ ] API rate limiting enabled
- [ ] Secrets management (no hardcoded keys)

---

## 📚 Resources & References

### Rails Best Practices
- Rails 7 Official Guides: https://guides.rubyonrails.org/
- Rails 7 Improvements: https://blog.lewagon.com/skills/learn-ruby-on-rails/
- Hotwire/Turbo Guide: https://turbo.hotwire.dev/

### Authentication & Authorization
- Devise Gem: https://github.com/heartcombo/devise
- Pundit Authorization: https://github.com/varvet/pundit

### Background Jobs
- Sidekiq Official: https://sidekiq.org/
- Sidekiq Scheduler: https://github.com/moove-it/sidekiq-scheduler
- Render Sidekiq Setup: https://render.com/docs/deploy-rails-sidekiq

### Email Services
- SendGrid Ruby: https://github.com/sendgrid/sendgrid-ruby
- Mailgun Ruby: https://github.com/mailgun/mailgun-ruby
- ActionMailer Guide: https://guides.rubyonrails.org/action_mailer_basics.html

### AI Integration
- Ruby OpenAI: https://github.com/alexrudall/ruby-openai
- OpenAI API Docs: https://platform.openai.com/docs

### Deployment
- Render Rails Guide: https://render.com/docs/deploy-rails
- Railway Rails Guide: https://railway.app/docs
- Heroku Rails Guide (alternative): https://devcenter.heroku.com/articles/getting-started-with-rails7

---

## 📞 Project Contact & Roles

**Project Lead:** [Your Name]  
**Stack:** Rails 7, PostgreSQL, Sidekiq, React/Hotwire  
**Repository:** [GitHub Link]  
**Demo URL:** [Deployed URL]  
**Issue Tracker:** GitHub Issues

---

## Appendix A: Database Diagram

```
┌────────────┐         ┌──────────────┐        ┌──────────────┐
│   users    │         │    events    │        │registrations │
├────────────┤         ├──────────────┤        ├──────────────┤
│ id (PK)    │         │ id (PK)      │        │ id (PK)      │
│ email      │         │ user_id (FK) │───────│ event_id (FK)│
│ password   │◄────────│ title        │        │ user_id (FK) │
│ first_name │         │ description  │        │ email        │
│ last_name  │         │ date_time    │        │ checked_in   │
│ created_at │         │ location     │        │ registered_at│
│ updated_at │         │ capacity     │        │ cancelled_at │
└────────────┘         │ category     │        │ checked_in_at│
                       │ status       │        └──────────────┘
                       │ created_at   │
                       │ updated_at   │
                       └──────────────┘

                    1:N Relationship
                    user has_many events
                    
                    1:N Relationship
                    event has_many registrations
```

---

## Appendix B: Sample .env Configuration

```bash
# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=xxx

# Database
DATABASE_URL=postgresql://user:password@host:5432/eventease_prod

# Redis (Sidekiq & Caching)
REDIS_URL=redis://user:password@host:6379/0

# Email Service
SENDGRID_API_KEY=SG.xxx
SENDGRID_FROM_EMAIL=noreply@eventease.com

# AI (OpenAI)
OPENAI_API_KEY=sk-xxx
OPENAI_API_VERSION=2024-10

# Devise
DEVISE_SECRET_KEY=xxx

# (Optional) Google OAuth
GOOGLE_OAUTH_CLIENT_ID=xxx
GOOGLE_OAUTH_CLIENT_SECRET=xxx

# App URL
APP_URL=https://eventease.example.com

# (Optional) Sentry Error Tracking
SENTRY_DSN=https://xxx@sentry.io/xxx
```

---

**Document Version:** 1.0  
**Last Updated:** December 2025  
**Status:** Ready for Development