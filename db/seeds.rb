# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

require 'faker'

# Clear existing data (safe for development)
puts "Clearing existing data..."
Registration.delete_all
Event.delete_all
User.delete_all

# Sample data for variety
FIRST_NAMES = ["John", "Jane", "Michael", "Sarah", "David", "Emma", "James", "Alice", "Robert", "Sophia", "William", "Olivia", "Daniel", "Isabella", "Matthew"].freeze
LAST_NAMES = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson"].freeze

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
  "Digital Marketing Summit"
].freeze

EVENT_DESCRIPTIONS = [
  "Join us for an engaging discussion about the latest web technologies and frameworks.",
  "Learn best practices and modern techniques from industry experts.",
  "Network with fellow professionals and expand your connections.",
  "Hands-on workshop with practical examples and real-world applications.",
  "Discover new skills and stay updated with industry trends.",
  "Fun and interactive session with Q&A and networking opportunities.",
  "Share knowledge and learn from experienced practitioners.",
  "Great opportunity to connect with like-minded professionals.",
  "Casual meetup to discuss recent developments and innovations.",
  "Collaborative session bringing together enthusiasts and experts."
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

puts "Creating 5 organizer users..."
organizers = []
5.times do |i|
  first_name = FIRST_NAMES.sample
  last_name = LAST_NAMES.sample
  email = "organizer#{i + 1}@eventease.com"
  
  user = User.create!(
    email: email,
    password: "password123",
    password_confirmation: "password123",
    first_name: first_name,
    last_name: last_name,
    time_zone: "Europe/Berlin"
  )
  organizers << user
  puts "✓ Created organizer: #{user.full_name} (#{email})"
end

# Add demo user
demo_user = User.create!(
  email: "demo@example.com",
  password: "password",
  password_confirmation: "password",
  first_name: "Demo",
  last_name: "User",
  time_zone: "Europe/Berlin"
)
organizers << demo_user
puts "✓ Created demo user: #{demo_user.full_name}"

puts "\nCreating 12 random events..."
events = []
EVENT_TITLES.each_with_index do |title, index|
  organizer = organizers.sample
  
  start_time = Faker::Time.between(from: DateTime.now, to: DateTime.now + 60.days)
  end_time = start_time + (Faker::Number.between(from: 1, to: 8)).hours
  
  event = Event.create!(
    organizer_id: organizer.id,
    title: title,
    description: EVENT_DESCRIPTIONS.sample,
    location: LOCATIONS.sample,
    starts_at: start_time,
    ends_at: end_time,
    capacity: Faker::Number.between(from: 10, to: 150),
    status: "published",
    registration_open_from: start_time - 7.days,
    registration_open_until: start_time - 1.hour
  )
  events << event
  puts "✓ Event #{index + 1}: #{event.title} (Organizer: #{organizer.full_name})"
end

puts "\nCreating random registrations (attendees)..."
total_registrations = 0

events.each do |event|
  # Create 3-15 random registrations per event
  num_registrations = Faker::Number.between(from: 3, to: [15, event.capacity].min)
  
  num_registrations.times do
    first_name = FIRST_NAMES.sample
    last_name = LAST_NAMES.sample
    email = "#{first_name.downcase}.#{last_name.downcase}#{Faker::Number.between(from: 100, to: 999)}@example.com"
    
    # Avoid duplicate registrations for same event
    next if Registration.exists?(event_id: event.id, email: email)
    
    # Random status distribution: 70% registered, 20% checked_in, 10% cancelled
    status = case Faker::Number.between(from: 1, to: 10)
             when 1..7 then "registered"
             when 8..9 then "checked_in"
             else "cancelled"
             end
    
    registration = Registration.create!(
      event_id: event.id,
      email: email,
      name: "#{first_name} #{last_name}",
      status: status,
      check_in_at: status == "checked_in" ? Faker::Time.between(from: event.starts_at, to: Time.current) : nil,
      cancelled_at: status == "cancelled" ? Faker::Time.between(from: event.registration_open_from, to: Time.current) : nil
    )
    
    total_registrations += 1
  end
  
  puts "  └─ #{num_registrations} registrations for '#{event.title}'"
end

puts "\n" + "="*60
puts "✅ SEED DATA CREATED SUCCESSFULLY!"
puts "="*60
puts "Summary:"
puts "  • Users (Organizers): #{User.count}"
puts "  • Events: #{Event.count}"
puts "  • Total Registrations: #{Registration.count}"
puts "  • Registered attendees: #{Registration.where(status: 'registered').count}"
puts "  • Checked-in attendees: #{Registration.where(status: 'checked_in').count}"
puts "  • Cancelled registrations: #{Registration.where(status: 'cancelled').count}"
puts "="*60
puts "\n📝 Demo Login Credentials:"
puts "  Email: demo@example.com"
puts "  Password: password"
puts "\n👥 Organizer Credentials:"
(1..5).each do |i|
  puts "  Email: organizer#{i}@eventease.com"
  puts "  Password: password123"
end
