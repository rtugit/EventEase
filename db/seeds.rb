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
  "Digital Marketing Summit",
  "Advanced CSS Techniques",
  "Cloud Architecture Masterclass",
  "Blockchain & Web3 Summit",
  "Mobile Development Sprint",
  "AI Ethics Workshop",
  "Sustainable Tech Conference"
].freeze

EVENT_DESCRIPTIONS = [
  "Join us for an engaging discussion about the latest JavaScript frameworks and best practices. Learn from industry experts about React, Vue, Next.js, and modern tooling. This is a hands-on session where we'll explore real-world applications and discuss common pitfalls. Perfect for developers looking to enhance their JavaScript skills and stay updated with the rapidly evolving ecosystem. Network with fellow developers and get insights into the future of web development.",
  "Learn Ruby on Rails best practices and modern techniques from experienced developers. This comprehensive workshop covers authentication, database optimization, testing strategies, and deployment workflows. We'll work through practical examples and real-world applications, discussing how to build scalable and maintainable applications. Get your questions answered and connect with the Rails community. Whether you're new to Rails or looking to deepen your expertise, this workshop offers valuable insights.",
  "Dive deep into data science with Python in this comprehensive talk. We'll explore pandas, scikit-learn, and TensorFlow with practical examples. Learn how to handle large datasets, perform statistical analysis, build predictive models, and visualize results effectively. Industry experts will share their experiences with real-world data science projects and challenges. Perfect for beginners and intermediate practitioners looking to enhance their data science toolkit and learn best practices.",
  "Transform your user experience with cutting-edge UX design principles and methodologies. This conference brings together designers, researchers, and product managers to discuss user-centered design, accessibility, and modern design systems. Explore case studies from leading companies and learn practical techniques for improving user satisfaction. Network with design professionals and discover the latest tools and frameworks shaping the industry.",
  "Pitch your startup ideas to a panel of experienced investors and entrepreneurs. This is an excellent opportunity to get feedback on your business model, market strategy, and execution plan. Whether you're in the idea stage or scaling up, this event connects you with potential investors, mentors, and collaborators. Learn from successful founders about their journey and the key lessons they've learned.",
  "Rejuvenate your mind and body with our comprehensive yoga and wellness class. Suitable for all levels, from beginners to experienced practitioners. Our certified instructors will guide you through a series of poses, breathing exercises, and meditation techniques. Join a welcoming community and discover the physical and mental benefits of regular practice. Bring your yoga mat and prepare for a transformative experience.",
  "Network with ambitious professionals over breakfast in a relaxed and welcoming environment. This brunch event brings together entrepreneurs, freelancers, and business professionals for meaningful conversations and potential collaborations. Enjoy delicious food while building valuable connections. Share your ideas, learn from others' experiences, and explore partnership opportunities. Perfect for those looking to expand their professional network.",
  "Explore the city's hidden gems and beautiful locations through photography. Our guided photography walk is perfect for enthusiasts of all skill levels. Learn composition techniques, lighting principles, and how to tell stories through images. Discover scenic spots while connecting with fellow photography enthusiasts. Bring your camera and capture the beauty of urban and natural landscapes.",
  "Join our monthly book club discussion and dive into literary worlds with fellow book lovers. We'll discuss the selected book's themes, characters, and author's perspective. Share your interpretations and discover different viewpoints. Whether you're a casual reader or bookworm, this is a great place to find your next favorite book and connect with like-minded people.",
  "Experience the creative energy of a music jam session with talented musicians. Whether you play an instrument or just love music, this is a perfect opportunity to collaborate, jam, and have fun. All skill levels welcome. Bring your instrument or come to listen and appreciate live music. Create new compositions and build musical connections with fellow musicians.",
  "Accelerate your startup journey with comprehensive guidance from experienced mentors and investors. This intensive program covers business strategy, fundraising, product development, and marketing. Participate in workshops, one-on-one mentoring sessions, and pitch practice. Connect with fellow entrepreneurs and access resources to take your startup to the next level.",
  "Master digital marketing strategies in today's competitive landscape. This summit covers SEO, social media marketing, content strategy, email campaigns, and analytics. Learn from leading digital marketers about the latest trends and techniques. Discover tools and platforms that can boost your online presence and drive business growth. Network with marketing professionals and expand your knowledge.",
  "Advance your CSS skills with advanced techniques and modern practices. Learn about CSS Grid, Flexbox, animations, and responsive design patterns. Explore styling strategies for large-scale applications and how to write maintainable CSS. This workshop covers performance optimization and browser compatibility considerations. Perfect for developers wanting to create beautiful and efficient user interfaces.",
  "Understand cloud architecture from basics to advanced patterns. Learn about AWS, Azure, and Google Cloud services. Explore microservices, containerization, and serverless computing. This masterclass covers scalability, security, reliability, and cost optimization. Industry experts share real-world examples and best practices. Ideal for developers and architects looking to design robust cloud solutions.",
  "Explore the world of blockchain and Web3 technologies shaping the future of the internet. Understand smart contracts, decentralized applications, and cryptocurrency fundamentals. Learn about use cases beyond finance and the challenges facing blockchain adoption. Connect with developers and entrepreneurs building the Web3 ecosystem. Discover opportunities in this rapidly evolving space.",
  "Intensive mobile development sprint focusing on iOS and Android development. Learn modern frameworks like React Native and Flutter. Build real applications and understand best practices for mobile UI/UX. This sprint covers testing, performance optimization, and deployment strategies. Collaborate with other developers and create something amazing in a short timeframe.",
  "Discuss ethical considerations in AI and machine learning development. Explore bias in algorithms, privacy concerns, and responsible AI practices. Learn how to build fair and transparent AI systems. Join conversations about regulation, governance, and the societal impact of AI. Perfect for technologists, ethicists, and anyone interested in responsible innovation.",
  "Discover how technology can contribute to a sustainable future. Learn about green computing, renewable energy, and sustainable business practices. Explore case studies from companies leading the sustainability movement. Understand how tech professionals can make a positive environmental impact. Network with like-minded individuals passionate about sustainable development."
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

# Add Duck Duck Go user (special request)
duck_duck_go_user = User.create!(
  email: "duckduckgo@email.com",
  password: "password",
  password_confirmation: "password",
  first_name: "Duck",
  last_name: "Duck Go",
  time_zone: "Europe/Berlin"
)
organizers << duck_duck_go_user
puts "✓ Created special user: #{duck_duck_go_user.full_name} (#{duck_duck_go_user.email})"

puts "\nCreating events from event titles..."
events = []
EVENT_TITLES.each_with_index do |title, index|
  organizer = organizers.sample
  
  start_time = Faker::Time.between(from: DateTime.now, to: DateTime.now + 60.days)
  end_time = start_time + (Faker::Number.between(from: 1, to: 8)).hours
  
  event = Event.create!(
    organizer_id: organizer.id,
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
  events << event
  puts "✓ Event #{index + 1}: #{event.title} (Organizer: #{organizer.full_name})"
end

# Create the special Regular Friday Pub event for Duck Duck Go user
puts "\n🦆 Creating special event: Regular Friday Pub..."
regular_friday_pub_description = <<~DESC
Hello Loves,

Regular Friday Pub is happening tomorrow 👋🏽

WHERE:
Butler - Bar, Café, Lounge
Karlstraße 15, 40210 Düsseldorf

It's actually easier to get to! It's, like, right near the Hbf. You can just walk from the main station, no need to figure out any trams or buses.

🕘 TIME
Friday at 9:00 PM
We stay until around 1:00 AM (or later, who knows 😊).

🎉 WHAT HAPPENS
Talking, laughing, making new friends, and just having a good time.

🍻 ONE RULE
Don't ask "Where are you from?" or "What do you do?"
If you do—you have to buy a drink for someone. 😜

It's going to be fun.

See you tomorrow evening!
DESC

friday_pub_event = Event.create!(
  organizer_id: duck_duck_go_user.id,
  title: "Regular Friday Pub",
  description: regular_friday_pub_description.strip,
  location: "Butler - Bar, Café, Lounge, Karlstraße 15, 40210 Düsseldorf",
  starts_at: Time.parse("2025-12-12 21:00:00"),
  ends_at: Time.parse("2025-12-13 01:00:00"),
  capacity: 50,
  status: "published",
  registration_open_from: Time.now - 7.days,
  registration_open_until: Time.parse("2025-12-12 20:00:00"),
  created_at: Time.parse("2025-12-11 12:00:00"),
  updated_at: Time.parse("2025-12-11 12:00:00")
)
events << friday_pub_event
puts "✓ Created special event: #{friday_pub_event.title}"
puts "  └─ Organizer: #{duck_duck_go_user.full_name}"
puts "  └─ Location: #{friday_pub_event.location}"
puts "  └─ Starts: #{friday_pub_event.starts_at.strftime('%A, %B %d at %I:%M %p')}"

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
puts "\n🦆 Special User (Regular Friday Pub):"
puts "  Email: duckduckgo@email.com"
puts "  Password: password"
puts "\n👥 Organizer Credentials:"
(1..5).each do |i|
  puts "  Email: organizer#{i}@eventease.com"
  puts "  Password: password123"
end
