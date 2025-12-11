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

Event.create([
{
  organizer_id: User.last.id,
  title: "picnic",
  description: "picnic at the beach",
  location: "beach",
  starts_at: DateTime.now,
  ends_at: DateTime.now + 1,
  capacity: 10,
  status: "published",
  registration_open_from: DateTime.now,
  registration_open_until: DateTime.now + 1,
  registrations_count: 0
},
{
  organizer_id: User.last.id,
  title: "Winter Music Party",
  description: "Sing, Dance, Drink",
  location: "ABC club",
  starts_at: DateTime.parse("2025-12-20 20:00"),
  ends_at: DateTime.parse("2025-12-21 02:00"),
  capacity: 100,
  status: "published",
  registration_open_from: DateTime.parse("2025-12-19 00:00"),
  registration_open_until: DateTime.parse("2025-12-20 00:00"),
  registrations_count: 0
}
]
)
