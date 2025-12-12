# EventEase: Seed Data Setup Instructions

## 📋 What Was Created

The seed file (`db/seeds.rb`) now creates:

- **5 Organizer Users** (+ 1 Demo User) = 6 total users
- **12 Random Events** with realistic details
- **60-150+ Random Registrations** with varied statuses

### Sample Data Includes:

- ✅ Event titles: JavaScript Meetup, Ruby Workshop, Python Talk, etc.
- ✅ Random descriptions
- ✅ 12 German cities (Düsseldorf, Berlin, Munich, etc.)
- ✅ Random capacities (10-150 attendees)
- ✅ Random registration statuses:
  - **Registered** (70%): Waiting for event
  - **Checked-in** (20%): Already attended
  - **Cancelled** (10%): Changed their mind

---

## 🚀 Step-by-Step Instructions

### Step 1: Add Faker Gem

**Already done!** I added `gem "faker"` to your Gemfile in the `development, test` group.

### Step 2: Install Dependencies

Run this command in your terminal:

```bash
cd /Users/nadir/code/TechnoVen/EventEase
bundle install
```

**Expected output:**

```
Resolving dependencies...
Using faker X.X.X
...
Bundle complete!
```

### Step 3: Reset Database (One-Time Setup)

```bash
bin/rails db:reset
```

This will:

1. Drop the existing database
2. Create a new one
3. Run all migrations
4. Load seed data

**⚠️ Warning:** This deletes all existing data. Use only for development!

### Step 4: Run Seeds Only (If Database Already Exists)

If you already have a database and just want to reload seed data:

```bash
bin/rails db:seed
```

---

## 📊 Expected Output

When you run the seed command, you'll see:

```
Clearing existing data...
Creating 5 organizer users...
✓ Created organizer: John Smith (organizer1@eventease.com)
✓ Created organizer: Jane Doe (organizer2@eventease.com)
✓ Created organizer: Michael Johnson (organizer3@eventease.com)
✓ Created organizer: Sarah Williams (organizer4@eventease.com)
✓ Created organizer: David Brown (organizer5@eventease.com)
✓ Created demo user: Demo User

Creating 12 random events...
✓ Event 1: JavaScript Meetup (Organizer: John Smith)
✓ Event 2: Ruby on Rails Workshop (Organizer: Jane Doe)
✓ Event 3: Python Data Science Talk (Organizer: Michael Johnson)
... (9 more events)

Creating random registrations (attendees)...
  └─ 8 registrations for 'JavaScript Meetup'
  └─ 12 registrations for 'Ruby on Rails Workshop'
  └─ 5 registrations for 'Python Data Science Talk'
... (9 more events)

============================================================
✅ SEED DATA CREATED SUCCESSFULLY!
============================================================
Summary:
  • Users (Organizers): 6
  • Events: 12
  • Total Registrations: 89
  • Registered attendees: 62
  • Checked-in attendees: 18
  • Cancelled registrations: 9
============================================================

📝 Demo Login Credentials:
  Email: demo@example.com
  Password: password

👥 Organizer Credentials:
  Email: organizer1@eventease.com
  Password: password123
  Email: organizer2@eventease.com
  Password: password123
  ... (3 more organizers)
```

---

## 🔑 Login Credentials for Testing

### Demo User (Attendee Role)

```
Email:    demo@example.com
Password: password
```

### Organizer Users (5 available)

```
Email:    organizer1@eventease.com
Email:    organizer2@eventease.com
Email:    organizer3@eventease.com
Email:    organizer4@eventease.com
Email:    organizer5@eventease.com
Password: password123 (same for all)
```

---

## 📝 What To Do Next

### 1. **Verify Data in Rails Console**

```bash
bin/rails console
```

Then run these commands to inspect your data:

```ruby
# Check users
User.count          # Should show 6
User.all            # List all users

# Check events
Event.count         # Should show 12
Event.first         # See first event details
Event.last.registrations  # See registrations for last event

# Check registrations
Registration.count  # Should show ~60-150
Registration.where(status: 'checked_in').count  # Checked-in count
Registration.where(status: 'registered').count   # Still registered

# Check specific event
event = Event.first
event.title              # Event name
event.registrations.count # Registration count
event.organizer.full_name # Organizer name
```

Type `exit` to leave the console.

### 2. **Start Development Server & Test**

```bash
bin/rails server
```

Then:

1. Go to `http://localhost:3000`
2. Click "Sign In"
3. Login as `demo@example.com` / `password`
4. Or login as `organizer1@eventease.com` / `password123` to see organizer features

### 3. **Check Database in pgAdmin (Optional)**

If you have PostgreSQL installed:

```bash
psql -U postgres eventease_development
```

Then query:

```sql
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM events;
SELECT COUNT(*) FROM registrations;
SELECT status, COUNT(*) FROM registrations GROUP BY status;
```

### 4. **Run Tests (When Available)**

```bash
bin/rails test
```

### 5. **RuboCop Check (Optional)**

```bash
bundle exec rubocop db/seeds.rb
```

---

## 🔄 Running Seeds Multiple Times

**Option 1: Reset Everything (Clear & Reload)**

```bash
bin/rails db:reset
```

✅ Use this when you want a fresh start with new random data

**Option 2: Just Reload Seeds (Keep Database)**

```bash
bin/rails db:seed
```

⚠️ This will error if records already exist (unique constraint on email)

**Option 3: Clear & Reload (Safe Method)**

```bash
bin/rails db:drop db:create db:migrate db:seed
```

✅ Equivalent to `db:reset`

---

## 📚 Data Structure Reference

### Users Table

```
id | email | first_name | last_name | encrypted_password | time_zone | created_at | updated_at
1  | demo@example.com | Demo | User | [encrypted] | Europe/Berlin | ... | ...
2  | organizer1@eventease.com | John | Smith | [encrypted] | Europe/Berlin | ... | ...
```

### Events Table

```
id | organizer_id | title | description | location | starts_at | ends_at | capacity | status | registrations_count
1  | 1 | JavaScript Meetup | ... | Düsseldorf | 2025-12-15 19:00 | 2025-12-15 21:00 | 50 | published | 8
2  | 2 | Ruby Workshop | ... | Berlin | 2025-12-20 10:00 | 2025-12-20 13:00 | 30 | published | 12
```

### Registrations Table

```
id | event_id | email | name | status | check_in_at | cancelled_at | created_at | updated_at
1  | 1 | john.smith123@example.com | John Smith | registered | NULL | NULL | ... | ...
2  | 1 | jane.doe456@example.com | Jane Doe | checked_in | 2025-12-15 19:15 | NULL | ... | ...
3  | 1 | bob.wilson789@example.com | Bob Wilson | cancelled | NULL | 2025-12-10 10:30 | ... | ...
```

---

## ✅ Checklist

- [ ] Ran `bundle install`
- [ ] Ran `bin/rails db:reset`
- [ ] Verified output shows "✅ SEED DATA CREATED SUCCESSFULLY!"
- [ ] Tested login with demo@example.com / password
- [ ] Tested login with organizer1@eventease.com / password123
- [ ] Viewed events as organizer
- [ ] Viewed events as attendee
- [ ] Checked Rails console to inspect database

---

## 🐛 Troubleshooting

### Error: "Could not find gem 'faker'"

```bash
bundle install --local
```

Then run:

```bash
bundle update faker
```

### Error: "Duplicate entry for key 'email'"

The seed file clears data first, but if it fails halfway:

```bash
bin/rails db:drop db:create db:migrate db:seed
```

### Error: "Cloudinary gem not found"

This is a separate issue. For now, ignore or:

```bash
# Remove cloudinary from views
# Edit app/views/events/show.html.erb and remove the cl_image_tag line
```

### Rails Console Not Showing?

Make sure you're in the right directory:

```bash
cd /Users/nadir/code/TechnoVen/EventEase
bin/rails console
```

---

## 🎯 Next Steps for Development

1. ✅ **Seed database** with test data (just did!)
2. **Fix critical bugs** (see CODEBASE_ANALYSIS.md):
   - Fix routes.rb duplication
   - Fix events_controller.rb authorization
   - Fix Gemfile cloudinary issue
3. **Implement email system** (Sidekiq + mailers)
4. **Add AI features** (OpenAI integration)
5. **Write tests** (RSpec)
6. **Deploy to production** (Render/Railway)

---

For any questions, refer to `CODEBASE_ANALYSIS.md` for detailed technical information!
