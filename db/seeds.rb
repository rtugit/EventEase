# db/seeds.rb

require "faker"

# ------------------------------------------------------------
# Helper
# ------------------------------------------------------------
def attach_if_exists(attached, relative_path, content_type:)
  path = Rails.root.join(relative_path)
  return unless File.exist?(path)

  attached.attach(
    io: File.open(path),
    filename: File.basename(path),
    content_type: content_type
  )
end

# ------------------------------------------------------------
# Assets (optional)
# ------------------------------------------------------------
EVENT_IMAGES = [
  "public/images/photo-1.jpg",
  "public/images/photo-2.jpg",
  "public/images/photo-3.jpg"
].freeze

AVATAR_IMAGES = [
  "public/images/avatars/girl.png",
  "public/images/avatars/girll.png",
  "public/images/avatars/man.png",
  "public/images/avatars/mann.png"
].freeze

# ------------------------------------------------------------
# Reset data
# ------------------------------------------------------------
puts "Clearing existing data..."
Registration.destroy_all
Event.destroy_all
User.destroy_all

# ------------------------------------------------------------
# Constants
# ------------------------------------------------------------
FIRST_NAMES = %w[
  John Jane Michael Sarah David Emma James Alice Robert Sophia
  William Olivia Daniel Isabella Matthew
].freeze

LAST_NAMES = %w[
  Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez
  Martinez Hernandez Lopez Gonzalez Wilson Anderson
].freeze

EVENT_TITLES = [
  "JavaScript Meetup",
  "Ruby on Rails Workshop",
  "Python Data Science Talk",
  "UX Design Conference",
  "Startup Pitch Night",
  "Yoga & Wellness Class",
  "Networking Brunch",
  "Photography Walk",
  "Book Club Meeting",
  "Music Jam Session",
  "Tech Startup Accelerator",
  "Digital Marketing Summit",
  "Advanced CSS Techniques",
  "Cloud Architecture Masterclass",
  "Blockchain & Web3 Summit",
  "Mobile Development Sprint",
  "AI Ethics Workshop",
  "Sustainable Tech Conference"
].freeze

EVENT_DESCRIPTIONS = [
  "Join us for an engaging discussion about the latest JavaScript frameworks and best practices.",
  "Learn Ruby on Rails best practices and modern techniques from experienced developers.",
  "Dive deep into data science with Python in this comprehensive talk.",
  "Transform your user experience with cutting-edge UX design principles.",
  "Pitch your startup ideas to a panel of experienced investors.",
  "Rejuvenate your mind and body with our yoga and wellness class.",
  "Network with ambitious professionals over breakfast.",
  "Explore the city through a guided photography walk.",
  "Join our monthly book club discussion.",
  "Experience the creative energy of a music jam session.",
  "Accelerate your startup journey with experienced mentors.",
  "Master digital marketing strategies in today’s landscape.",
  "Advance your CSS skills with modern techniques.",
  "Understand cloud architecture from basics to advanced patterns.",
  "Explore blockchain and Web3 technologies.",
  "Intensive mobile development sprint for iOS and Android.",
  "Discuss ethical considerations in AI development.",
  "Discover how technology can contribute to sustainability."
].freeze

LOCATIONS = [
  "Düsseldorf, Germany",
  "Berlin, Germany",
  "Munich, Germany",
  "Hamburg, Germany",
  "Cologne, Germany",
  "Frankfurt, Germany",
  "Stuttgart, Germany",
  "Hannover, Germany",
  "Dresden, Germany",
  "Leipzig, Germany",
  "Virtual",
  "Zoom"
].freeze

# ------------------------------------------------------------
# Users
# ------------------------------------------------------------
puts "Creating organizer users..."
organizers = []

5.times do |i|
  user = User.create!(
    email: "organizer#{i + 1}@eventease.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: FIRST_NAMES.sample,
    last_name: LAST_NAMES.sample,
    time_zone: "Europe/Berlin"
  )

  attach_if_exists(user.photo, AVATAR_IMAGES.sample, content_type: "image/png") if rand < 0.5
  organizers << user
end

demo_user = User.create!(
  email: "demo@example.com",
  password: "password",
  password_confirmation: "password",
  first_name: "Demo",
  last_name: "User",
  time_zone: "Europe/Berlin"
)
attach_if_exists(demo_user.photo, AVATAR_IMAGES.sample, content_type: "image/png")
organizers << demo_user

duck_user = User.create!(
  email: "duckduckgo@email.com",
  password: "password",
  password_confirmation: "password",
  first_name: "Duck",
  last_name: "Duck Go",
  time_zone: "Europe/Berlin"
)
attach_if_exists(duck_user.photo, AVATAR_IMAGES.sample, content_type: "image/png")
organizers << duck_user

# ------------------------------------------------------------
# Events
# ------------------------------------------------------------
puts "Creating events..."
events = []

EVENT_TITLES.each_with_index do |title, index|
  start_time = Faker::Time.between(from: Time.current, to: 60.days.from_now)
  end_time = start_time + Faker::Number.between(from: 1, to: 8).hours

  event = Event.create!(
    organizer: organizers.sample,
    title: title,
    description: EVENT_DESCRIPTIONS[index],
    location: LOCATIONS.sample,
    starts_at: start_time,
    ends_at: end_time,
    capacity: Faker::Number.between(from: 10, to: 150),
    status: "published",
    registration_open_from: start_time - 7.days,
    registration_open_until: start_time - 1.hour
  )

  attach_if_exists(event.photos, EVENT_IMAGES.sample, content_type: "image/jpeg")
  events << event
end

# Special Friday Pub
friday_event = Event.create!(
  organizer: duck_user,
  title: "Regular Friday Pub",
  description: "Regular Friday Pub – casual meetup, drinks, conversations.",
  location: "Butler - Bar, Café, Lounge, Düsseldorf",
  starts_at: Time.parse("2025-12-12 21:00"),
  ends_at: Time.parse("2025-12-13 01:00"),
  capacity: 50,
  status: "published",
  registration_open_from: 7.days.ago,
  registration_open_until: Time.parse("2025-12-12 20:00")
)
attach_if_exists(friday_event.photos, EVENT_IMAGES.sample, content_type: "image/jpeg")
events << friday_event

# ------------------------------------------------------------
# Registrations
# ------------------------------------------------------------
puts "Creating registrations..."
events.each do |event|
  Faker::Number.between(from: 3, to: [15, event.capacity].min).times do
    email = Faker::Internet.unique.email
    next if Registration.exists?(event: event, email: email)

    status = %w[registered registered registered checked_in cancelled].sample

    Registration.create!(
      event: event,
      email: email,
      name: Faker::Name.name,
      status: status,
      check_in_at: status == "checked_in" ? Faker::Time.between(from: event.starts_at, to: Time.current) : nil,
      cancelled_at: status == "cancelled" ? Faker::Time.between(from: event.registration_open_from, to: Time.current) : nil
    )
  end
end

puts "✅ SEED DATA CREATED SUCCESSFULLY"
puts "Users: #{User.count}"
puts "Events: #{Event.count}"
puts "Registrations: #{Registration.count}"
puts "Demo login: demo@example.com / password"
