# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed demo user
User.find_or_create_by!(email: "demo@example.com") do |user|
    user.password = "password"
    user.password_confirmation = "password"
    user.first_name = "Demo"
    user.last_name = "User"
  end

# Clear existing events for clean seed
Event.destroy_all

# Get or create demo user
demo_user = User.find_or_create_by!(email: "demo@example.com") do |user|
  user.password = "password"
  user.password_confirmation = "password"
  user.first_name = "Demo"
  user.last_name = "User"
end

# Create a comprehensive event with rundown items (past event for reviews)
event = Event.find_or_create_by!(title: "Tech Innovation Summit 2025") do |e|
  e.organizer = demo_user
  e.description = "Join us for an exciting day of tech innovation, networking, and learning. This summit brings together industry leaders, startups, and tech enthusiasts to explore the latest trends in technology, AI, and digital transformation. Don't miss out on this opportunity to connect with like-minded professionals and gain insights from expert speakers."
  e.location = "Berlin, Germany"
  # Set event date in the past (November 2024)
  e.starts_at = DateTime.parse("2025-11-15 09:00")
  e.ends_at = DateTime.parse("2025-11-15 18:00")
  e.capacity = 150
  e.status = "published"
end

# Attach Berlin image to the event if no photos are attached
if event.photos.empty?
  berlin_image_path = Rails.root.join("app", "assets", "images", "berlin.jpg")
  if File.exist?(berlin_image_path)
    event.photos.attach(
      io: File.open(berlin_image_path),
      filename: "berlin.jpg",
      content_type: "image/jpeg"
    )
    puts "   - Photo attached: berlin.jpg"
  else
    puts "   - Warning: berlin.jpg not found at #{berlin_image_path}"
  end
end

# Add rundown items
if event.rundown_items.empty?
  event.rundown_items.create!([
    {
      heading: "Welcome & Registration",
      description: "Coffee, networking, and registration. Meet fellow attendees and grab your welcome package.",
      position: 1
    },
    {
      heading: "Keynote: The Future of AI",
      description: "Opening keynote address by industry expert discussing the latest developments in artificial intelligence and machine learning.",
      position: 2
    },
    {
      heading: "Panel Discussion: Startup Ecosystem",
      description: "Interactive panel with successful entrepreneurs sharing their journey and insights on building tech startups.",
      position: 3
    },
    {
      heading: "Lunch Break",
      description: "Networking lunch with catered food and beverages. Great opportunity to connect with speakers and attendees.",
      position: 4
    },
    {
      heading: "Workshop Sessions",
      description: "Choose from multiple hands-on workshops covering topics like cloud computing, cybersecurity, and mobile app development.",
      position: 5
    },
    {
      heading: "Closing Remarks & Networking",
      description: "Final thoughts from organizers followed by an extended networking session with drinks and snacks.",
      position: 6
    }
  ])
end

# Create some registrations
if event.registrations.empty?
  # Create additional users for registrations
  user1 = User.find_or_create_by!(email: "john@example.com") do |u|
    u.password = "password"
    u.password_confirmation = "password"
    u.first_name = "John"
    u.last_name = "Doe"
  end

  user2 = User.find_or_create_by!(email: "jane@example.com") do |u|
    u.password = "password"
    u.password_confirmation = "password"
    u.first_name = "Jane"
    u.last_name = "Smith"
  end

  user3 = User.find_or_create_by!(email: "alex@example.com") do |u|
    u.password = "password"
    u.password_confirmation = "password"
    u.first_name = "Alex"
    u.last_name = "Johnson"
  end

  # Create registrations
  event.registrations.create!([
    {
      email: user1.email,
      name: "#{user1.first_name} #{user1.last_name}",
      status: "registered"
    },
    {
      email: user2.email,
      name: "#{user2.first_name} #{user2.last_name}",
      status: "checked_in"
    },
    {
      email: user3.email,
      name: "#{user3.first_name} #{user3.last_name}",
      status: "registered"
    }
  ])

  # Update registrations count
  event.update(registrations_count: event.registrations.count)

  # Create a review from one of the registrations
  if event.reviews.empty? && user1
    registration1 = event.registrations.find_by(email: user1.email)
    if registration1
      event.reviews.create!(
        registration: registration1,
        rating: 5,
        comment: "Amazing event! The speakers were incredibly insightful and the networking opportunities were fantastic. The AI keynote was particularly inspiring, and I learned a lot from the panel discussion. Highly recommend attending future events!"
      )
    end
  end
end

puts "✅ Seeded event: #{event.title}"
puts "   - Organizer: #{event.organizer.email}"
puts "   - Rundown items: #{event.rundown_items.count}"
puts "   - Registrations: #{event.registrations.count}"
puts "   - Reviews: #{event.reviews.count}"
puts "   - Location: #{event.location}"
puts "   - Date: #{event.starts_at.strftime('%B %d, %Y at %I:%M %p')} (Past event)"
