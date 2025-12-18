# db/seeds.rb

require "faker"
require "date"

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
# Assets
# ------------------------------------------------------------
EVENT_IMAGES = [
  "public/images/photo-1.jpg",
  "public/images/photo-2.jpg",
  "public/images/photo-3.jpg"
].freeze

# 1. Load all avatar files
AVATAR_DIR = Rails.root.join("public/images/avatars")
# Sort to ensure consistent order before shuffling if needed, 
# though we shuffle anyway.
ALL_AVATAR_FILES = Dir.children(AVATAR_DIR).sort
puts "Found #{ALL_AVATAR_FILES.count} avatar files."

# ------------------------------------------------------------
# Reset data
# ------------------------------------------------------------
puts "Clearing existing data..."
Registration.destroy_all
RundownItem.destroy_all
Review.destroy_all
Event.destroy_all
User.destroy_all

# ------------------------------------------------------------
# Users
# ------------------------------------------------------------
puts "Creating users..."

# Separate avatars for system users and general pool
# We'll take the first few for organizers to ensure consistency, or random
# Let's just shuffle them to make it fun but ensure distinct ones
shuffled_avatars = ALL_AVATAR_FILES.shuffle
system_avatars = shuffled_avatars.pop(7) # 5 organizers + demo + duck
attendee_avatars = shuffled_avatars # The rest

organizers = []

# 1. Create 5 Organizers
5.times do |i|
  avatar_file = system_avatars.pop
  # Use filename as name if it looks like a name (has space), else Faker
  base_name = File.basename(avatar_file, ".*")
  if base_name.include?(" ")
    first_name, last_name = base_name.split(" ", 2)
  else
    first_name = Faker::Name.first_name
    last_name = Faker::Name.last_name
  end

  user = User.create!(
    email: "organizer#{i + 1}@eventease.com",
    password: "password123",
    password_confirmation: "password123",
    first_name: first_name,
    last_name: last_name,
    time_zone: "Europe/Berlin"
  )
  attach_if_exists(user.photo, "public/images/avatars/#{avatar_file}", content_type: "image/jpeg")
  organizers << user
  puts "Created Organizer: #{user.full_name}"
end

# 2. Demo User
demo_avatar = system_avatars.pop
user_name = File.basename(demo_avatar, ".*")
first, last = user_name.include?(" ") ? user_name.split(" ", 2) : ["Demo", "User"]

demo_user = User.create!(
  email: "demo@example.com",
  password: "password",
  password_confirmation: "password",
  first_name: first,
  last_name: last,
  time_zone: "Europe/Berlin"
)
attach_if_exists(demo_user.photo, "public/images/avatars/#{demo_avatar}", content_type: "image/jpeg")
organizers << demo_user

# 3. DuckDuckGo User
duck_avatar = system_avatars.pop
duck_user = User.create!(
  email: "duckduckgo@email.com",
  password: "password",
  password_confirmation: "password",
  first_name: "Duck",
  last_name: "Duck Go",
  time_zone: "Europe/Berlin"
)
attach_if_exists(duck_user.photo, "public/images/avatars/#{duck_avatar}", content_type: "image/jpeg")
organizers << duck_user

# 4. Create Pool of Attendee Users from remaining Avatars
puts "Creating attendee user pool (#{attendee_avatars.count} users)..."
attendee_users = []

attendee_avatars.each do |filename|
  base_name = File.basename(filename, ".*")
  
  # Heuristics to get a clean name
  clean_name = base_name.gsub(/[-_]/, " ").gsub(/\d+/, "").strip
  clean_name = "User #{SecureRandom.hex(2)}" if clean_name.blank?

  if clean_name.include?(" ")
    first_name, last_name = clean_name.split(" ", 2)
  else
    first_name = clean_name
    last_name = "User"
  end

  # Generate email based on name to look realistic
  email_name = clean_name.downcase.gsub(/[^a-z0-9]/, ".")
  email = "#{email_name}.#{SecureRandom.hex(2)}@example.com"

  user = User.create!(
    email: email,
    password: "password",
    password_confirmation: "password",
    first_name: first_name,
    last_name: last_name,
    time_zone: "Europe/Berlin"
  )
  attach_if_exists(user.photo, "public/images/avatars/#{filename}", content_type: "image/jpeg")
  attendee_users << user
end
puts "Created #{attendee_users.count} attendee users."

# 5. Specific User: Ahmed Nadir
ahmed = User.find_by(first_name: "Ahmed", last_name: "Nadir")
if ahmed
  attach_if_exists(ahmed.photo, "public/images/avatars/Ahmed_Nadir_Profile.jpeg", content_type: "image/jpeg")
  puts "Assigned avatar to Ahmed Nadir"
end

# 6. Specific Event: Regular Friday Pub
# Ensure it exists and has guests
target_organizer = ahmed || organizers.first
pub_event = Event.find_or_create_by!(
  title: "Regular Friday Pub",
  organizer: target_organizer
) do |e|
  e.description = "Weekly social gathering for the team."
  e.location = "The Local Pub"
  e.category = "Party & Social"
  e.starts_at = Time.zone.now.next_occurring(:friday).change(hour: 18, min: 0)
  e.ends_at = Time.zone.now.next_occurring(:friday).change(hour: 23, min: 0)
  e.capacity = 50
  e.status = "published"
end

# Assign 10 random guests
puts "Assigning 10 guests to Regular Friday Pub..."
attendee_users.sample(10).each do |guest|
  Registration.create!(
    event: pub_event,
    user: guest,
    email: guest.email,
    status: "registered"
  )
rescue ActiveRecord::RecordInvalid
  # Ignore if already registered
end

# 7. Specific Images for Events
# Assign images to events matching specific titles
image_assignments = {
  "Paris Art Workshop - Watercolor Painting" => "Paris Art Workshop - Watercolor Painting.png",
  "London Comedy Night - Stand Up Showcase" => "London_Comedy.avif",
  "Berlin Outdoor Adventure - Urban Hiking" => "Berlin Outdoor Adventure - Urban Hiking.jpg",
  "London Book Club - Contemporary Fiction" => "London Book Club - Contemporary Fiction.jpg",
  "London Running Club - Thames Riverside" => "London Running Club - Thames Riverside.jpeg",
  "Paris Internationals - Afterwork Social" => "Paris Internationals - Afterwork Social.jpg"
}

puts "Assigning specific images to events..."
image_assignments.each do |title, filename|
  event = Event.find_by(title: title)
  if event
    # Remove existing photos to ensure the specific one is the main one or only one
    event.photos.purge
    attach_if_exists(event.photos, "public/images/#{filename}", content_type: "image/#{File.extname(filename).delete('.')}")
    puts "Assigned #{filename} to #{title}"
  else
    puts "Event not found for image assignment: #{title}"
  end
end


# ------------------------------------------------------------
# Events Data
# ------------------------------------------------------------
EVENTS_DATA = [
  {
    title: "London Music Showcase - Gigs & Drinks",
    description: "A showcase of some of the best London bands playing their music in London. This is also a Meetup group, so you'll get to watch the gig with a mix of regular members and newcomers. Look for the 'MEETUP SIGN' or ask the Host on the door when you arrive. We're a friendly mix of French, Portuguese, Italian, Spanish, Japanese and English people, so I'm sure you will meet someone that shares a passion for rocking music.",
    location: "The Dublin Castle, 94 Parkway, Camden, London NW1 7AN, UK",
    event_time: "19:30",
    category: "Party & Social", # Mapped to one of our categories
    end_time: "23:00",
    capacity: 80,
    rundown: "7:30 PM - Doors open and welcome drinks, 8:00 PM - Opening band performance, 8:45 PM - Meetup group introductions, 9:00 PM - Main band showcase, 10:30 PM - Social drinks and networking"
  },
  {
    title: "International & Social Events Berlin - Improv Meetup",
    description: "Develop your spontaneity on stage and in life, with playful scene games. Meet new people, perform in public, learn to tell short engaging stories, and build confidence on and off stage. Every session includes icebreakers, warm-up games, exercises to think 'scenically,' and techniques to improve spontaneity. Beginner-friendly event hosted in a purpose-built arts centre.",
    location: "DNA House, Wrangelstraße 25, 10997 Berlin, Germany",
    event_time: "14:30",
    category: "Community",
    end_time: "16:00",
    capacity: 25,
    rundown: "2:30 PM - Icebreaker activities, 2:45 PM - Warm-up games, 3:00 PM - Scene work exercises, 3:30 PM - Performance practice, 3:45 PM - Group feedback and networking"
  },
  {
    title: "Barcelona International Social - Saturday Brunch",
    description: "New Saturday brunch to meet new people in a relaxed atmosphere. Join us for delicious food, great conversations, and the opportunity to make new friends from around the world. Perfect for expats, travelers, and locals looking to expand their social circle in Barcelona.",
    location: "SAO MEDIALUNAS Y CAFES, Carrer de la Princesa, 15, 08003 Barcelona, Spain",
    event_time: "12:30",
    category: "Party & Social",
    end_time: "15:00",
    capacity: 30,
    rundown: "12:30 PM - Welcome and introductions, 1:00 PM - Brunch service begins, 1:30 PM - Icebreaker games, 2:00 PM - Open networking, 2:30 PM - Group photo and contact exchange"
  },
  {
    title: "Paris Internationals - Afterwork Social",
    description: "Join us for afterwork drinks with internationals in Paris at Le Froggy bar. Perfect opportunity to practice languages, meet people from different cultures, and expand your professional and social network. Whether you're new to Paris or a longtime resident, everyone is welcome.",
    location: "Le Froggy, 12 Rue de la Roquette, 75011 Paris, France",
    event_time: "19:30",
    category: "Networking",
    end_time: "22:00",
    capacity: 50,
    rundown: "7:30 PM - Welcome drinks and registration, 8:00 PM - Speed networking round, 8:30 PM - Language exchange corner, 9:00 PM - Open socializing, 9:30 PM - Group activities and games"
  },
  {
    title: "Amsterdam Language Cafe - French Workshop",
    description: "Practice your French or help others practice in a relaxed and warm atmosphere. We welcome French lovers from beginner+ to advanced levels. Native speakers are also welcome to help practice French with non-natives. The event includes a French workshop, break with drinks, and conversation practice.",
    location: "Koentact Dutch School, Keizersgracht 316, 1016 EV Amsterdam, Netherlands",
    event_time: "19:00",
    category: "Study",
    end_time: "21:30",
    capacity: 35,
    rundown: "7:00 PM - Doors open and registration, 7:30 PM - First French workshop session, 8:15 PM - Break with drinks and networking, 8:45 PM - Second workshop session, 9:15 PM - Free conversation practice"
  },
  {
    title: "London Tech Startup Meetup - AI & Future",
    description: "Connect with London's vibrant tech startup community at our AI-focused meetup. Learn about the latest trends in artificial intelligence, machine learning, and automation. Network with entrepreneurs, developers, and investors who are shaping the future of technology.",
    location: "WeWork Old Street, 41 Corsham St, London N1 6DR, UK",
    event_time: "18:00",
    category: "Talk",
    end_time: "20:30",
    capacity: 60,
    rundown: "6:00 PM - Registration and welcome drinks, 6:30 PM - Keynote: AI Trends 2025, 7:00 PM - Startup pitch session, 7:30 PM - Networking break, 8:00 PM - Panel discussion: Future of AI, 8:30 PM - Closing and networking"
  },
  {
    title: "Berlin Photography Workshop - Street Photography",
    description: "Master the art of street photography in Berlin's most photogenic neighborhoods. Learn composition techniques, lighting tricks, and how to capture authentic moments. Suitable for all skill levels from beginners to advanced photographers. Bring your camera or smartphone.",
    location: "Alexanderplatz, Alexanderpl., 10178 Berlin, Germany",
    event_time: "10:00",
    category: "Community",
    end_time: "13:00",
    capacity: 20,
    rundown: "10:00 AM - Meet at Alexanderplatz, 10:15 AM - Introduction to street photography, 10:30 AM - Shooting session in Hackescher Markt, 11:30 AM - Break and photo review, 11:45 AM - Shooting session in Mitte district, 12:45 PM - Wrap-up and feedback session"
  },
  {
    title: "Barcelona Wine Tasting - Catalan Wines",
    description: "Discover the rich world of Catalan wines with our expert sommelier. Taste premium wines from Penedès, Priorat, and Empordà regions while learning about local winemaking traditions. Perfect for wine enthusiasts and those wanting to explore Spanish wine culture.",
    location: "Vila Viniteca, Agullers, 7, 08003 Barcelona, Spain",
    event_time: "19:00",
    category: "Party & Social",
    end_time: "21:00",
    capacity: 25,
    rundown: "7:00 PM - Welcome and introductions, 7:15 PM - Introduction to Catalan wine regions, 7:30 PM - First tasting: White wines from Penedès, 8:00 PM - Second tasting: Red wines from Priorat, 8:30 PM - Food pairing session, 9:00 PM - Q&A and networking"
  },
  {
    title: "Paris Yoga & Meditation - Morning Flow",
    description: "Start your day with a revitalizing yoga session in the heart of Paris. Suitable for all levels, this class combines gentle flow sequences with meditation techniques. Connect with your body and mind while meeting like-minded wellness enthusiasts in a beautiful studio setting.",
    location: "Centre de Yoga du Marais, 14 Rue des Guillemites, 75004 Paris, France",
    event_time: "08:00",
    category: "Sport & Activity",
    end_time: "09:30",
    capacity: 15,
    rundown: "8:00 AM - Arrival and mat setup, 8:15 AM - Opening meditation, 8:30 AM - Sun salutations and flow sequence, 9:00 AM - Balance poses and core work, 9:15 AM - Final relaxation and meditation, 9:25 AM - Closing circle and tea"
  },
  {
    title: "Amsterdam Cycling Tour - Hidden Gems",
    description: "Explore Amsterdam's hidden gems on two wheels with our local guide. Discover charming neighborhoods, secret courtyards, and picturesque canals that most tourists never see. Includes bike rental and stops at local cafes for authentic Dutch treats.",
    location: "MacBike Amsterdam Central, Stationsplein 12, 1012 AB Amsterdam, Netherlands",
    event_time: "14:00",
    category: "Sport & Activity",
    end_time: "17:00",
    capacity: 12,
    rundown: "2:00 PM - Bike pickup and safety briefing, 2:30 PM - Start cycling tour through Jordaan, 3:15 PM - Stop at hidden courtyard, 3:45 PM - Continue through Plantage neighborhood, 4:15 PM - Coffee break at local café, 4:45 PM - Return journey"
  },
  {
    title: "London Book Club - Contemporary Fiction",
    description: "Join our monthly book club discussion featuring contemporary fiction. This month we're discussing 'Hamnet' by Maggie O'Farrell. Engage in thoughtful literary discussions while meeting fellow book lovers in a cozy London pub setting.",
    location: "The Lamb, 94 Lamb's Conduit St, Bloomsbury, London WC1N 3LZ, UK",
    event_time: "19:00",
    category: "Community",
    end_time: "21:00",
    capacity: 20,
    rundown: "7:00 PM - Welcome drinks and introductions, 7:20 PM - Book discussion begins, 8:00 PM - Break and socializing, 8:15 PM - Final thoughts and next book selection, 8:45 PM - Informal networking and drinks"
  },
  {
    title: "Berlin Food Tour - International Cuisine",
    description: "Taste Berlin's incredible international food scene with our guided culinary tour. Sample dishes from Turkish, Vietnamese, Syrian, and Italian communities while learning about the city's multicultural history. Perfect for foodies and cultural explorers.",
    location: "Hackescher Markt, Am Zwirngraben 4, 10178 Berlin, Germany",
    event_time: "12:00",
    category: "Party & Social",
    end_time: "15:00",
    capacity: 16,
    rundown: "12:00 PM - Meet at Hackescher Markt, 12:15 PM - Turkish kebab tasting, 1:00 PM - Vietnamese pho experience, 1:45 PM - Syrian mezze platter, 2:30 PM - Italian gelato finale, 2:45 PM - Group photo and recommendations"
  },
  {
    title: "Barcelona Art Workshop - Gaudí Mosaics",
    description: "Create your own Gaudí-inspired mosaic artwork in this hands-on workshop. Learn about the famous architect's techniques and create a beautiful souvenir to take home. All materials provided, suitable for complete beginners.",
    location: "Taller Gaudí, Carrer de Sant Pere Més Alt, 43, 08003 Barcelona, Spain",
    event_time: "15:00",
    category: "Community",
    end_time: "17:30",
    capacity: 18,
    rundown: "3:00 PM - Introduction to Gaudí's mosaic techniques, 3:20 PM - Design planning and sketching, 3:45 PM - Mosaic creation begins, 4:30 PM - Break and inspiration sharing, 4:45 PM - Continue mosaic work, 5:15 PM - Finishing touches and photos, 5:20 PM - Workshop wrap-up and socializing"
  },
  {
    title: "Paris Cooking Class - French Pastries",
    description: "Master the art of French pastry making in this hands-on cooking class. Learn to create classic French desserts like éclairs, macarons, and tarte tatin from a professional pastry chef. Take home your delicious creations and new skills.",
    location: "La Cuisine Paris, 80 Quai de l'Hôtel de Ville, 75004 Paris, France",
    event_time: "14:00",
    category: "Party & Social",
    end_time: "17:00",
    capacity: 12,
    rundown: "2:00 PM - Welcome and chef introduction, 2:15 PM - Pastry theory and techniques, 2:45 PM - Hands-on éclair making, 3:30 PM - Macaron preparation, 4:15 PM - Tarte tatin demonstration, 4:45 PM - Tasting and packaging to go"
  },
  {
    title: "Amsterdam Networking - Tech Professionals",
    description: "Connect with Amsterdam's tech community at our monthly networking event. Meet developers, entrepreneurs, and digital professionals from startups and established companies. Exchange ideas, find collaborators, and discover new opportunities.",
    location: "Spaces Herengracht, Herengracht 124, 1015 BT Amsterdam, Netherlands",
    event_time: "18:30",
    category: "Networking",
    end_time: "21:00",
    capacity: 80,
    rundown: "6:30 PM - Registration and welcome drinks, 7:00 PM - Speed networking session, 7:30 PM - Tech startup showcase, 8:00 PM - Open networking and drinks, 8:45 PM - Closing remarks and contact exchange"
  },
  {
    title: "London Comedy Night - Stand Up Showcase",
    description: "Enjoy a hilarious evening of stand-up comedy featuring both established and up-and-coming comedians. Perfect for a night out with friends or meeting new people who appreciate good humor. The show is followed by social drinks.",
    location: "The Comedy Store, 1a Oxendon St, London SW1Y 4EE, UK",
    event_time: "20:00",
    category: "Party & Social",
    end_time: "22:30",
    capacity: 100,
    rundown: "8:00 PM - Doors open and seating, 8:30 PM - Opening act, 8:45 PM - Featured comedians, 9:30 PM - Headliner performance, 10:00 PM - Social drinks at bar, 10:30 PM - Event concludes"
  },
  {
    title: "Berlin Outdoor Adventure - Urban Hiking",
    description: "Discover Berlin's urban nature on this guided hiking tour through parks, forests, and hidden green spaces. Learn about the city's ecology and history while getting fresh air and exercise. Suitable for all fitness levels.",
    location: "Volkspark Friedrichshain, Am Friedrichshain 1, 10407 Berlin, Germany",
    event_time: "10:00",
    category: "Sport & Activity",
    end_time: "13:00",
    capacity: 25,
    rundown: "10:00 AM - Meet at park entrance, 10:15 AM - Safety briefing and route overview, 10:30 AM - Begin hiking tour, 11:30 AM - Nature break and photography, 12:00 PM - Continue through forest paths, 12:45 PM - Final group photo and wrap-up"
  },
  {
    title: "Barcelona Salsa Night - Beginner Class",
    description: "Learn to dance salsa in this fun and friendly beginner class. No experience necessary! Professional instructors will teach you the basic steps and turns in a supportive environment. Perfect for meeting new people and learning a new skill.",
    location: "Antilla Barcelona, Carrer de la Diputació, 235, 08007 Barcelona, Spain",
    event_time: "20:00",
    category: "Sport & Activity",
    end_time: "22:00",
    capacity: 30,
    rundown: "8:00 PM - Registration and partner assignment, 8:15 PM - Basic step instruction, 8:45 PM - Turn patterns and combinations, 9:15 PM - Practice and social dancing, 9:45 PM - Freestyle dancing and socializing"
  },
  {
    title: "Paris Museum Tour - Hidden Masterpieces",
    description: "Explore Paris's lesser-known museums and discover hidden artistic treasures. This guided tour takes you off the beaten path to show you incredible artworks that most tourists never see. Perfect for art lovers and culture enthusiasts.",
    location: "Musée Rodin, 77 Rue de Varenne, 75007 Paris, France",
    event_time: "14:00",
    category: "Community",
    end_time: "17:00",
    capacity: 15,
    rundown: "2:00 PM - Meet at Musée Rodin, 2:15 PM - Private guided tour begins, 3:00 PM - Walk to next museum, 3:15 PM - Musée Maillol visit, 4:00 PM - Coffee break discussion, 4:15 PM - Final museum visit, 4:45 PM - Tour conclusion and recommendations"
  },
  {
    title: "Amsterdam Boat Tour - Canals & History",
    description: "Experience Amsterdam from the water on this informative canal cruise. Learn about the city's Golden Age history, architecture, and unique urban planning while enjoying stunning views from a traditional canal boat.",
    location: "Blue Boat Company, Stadhouderskade 501, 1071 ZD Amsterdam, Netherlands",
    event_time: "15:00",
    category: "Sport & Activity",
    end_time: "16:30",
    capacity: 40,
    rundown: "3:00 PM - Boarding and safety briefing, 3:15 PM - Departure and historical introduction, 3:30 PM - Canal ring tour with commentary, 4:00 PM - Photo opportunities, 4:15 PM - Return journey with Q&A, 4:30 PM - Disembarkation"
  },
  {
    title: "London Board Game Café - Strategy Games",
    description: "Join fellow board game enthusiasts for an evening of strategy games and social fun. From Catan to Carcassonne, we'll play a variety of modern board games while enjoying drinks and snacks. Perfect for meeting new gaming friends.",
    location: "Draughts London, 337 Acton Mews, London E8 4EA, UK",
    event_time: "19:00",
    category: "Party & Social",
    end_time: "22:00",
    capacity: 24,
    rundown: "7:00 PM - Welcome and game selection, 7:15 PM - Table assignments and rule explanations, 7:30 PM - Gaming session 1, 8:30 PM - Break and socializing, 8:45 PM - Gaming session 2, 9:45 PM - Final scores and networking"
  },
  {
    title: "Berlin Startup Pitch - Demo Night",
    description: "Watch Berlin's most innovative startups pitch their ideas to investors and the community. Network with entrepreneurs, investors, and tech professionals while discovering the next big thing in European tech.",
    location: "The Factory Berlin, Rheinsberger Str. 76/77, 10115 Berlin, Germany",
    event_time: "19:00",
    category: "Talk",
    end_time: "21:30",
    capacity: 120,
    rundown: "7:00 PM - Registration and networking drinks, 7:30 PM - Opening remarks, 7:45 PM - Startup pitches begin, 8:30 PM - Audience Q&A, 8:45 PM - Judges deliberation, 9:00 PM - Winner announcement, 9:15 PM - Closing networking"
  },
  {
    title: "Barcelona Beach Volleyball - Social Games",
    description: "Enjoy a fun afternoon of beach volleyball at Barcelona's beautiful beaches. All skill levels welcome - we'll organize mixed teams and play friendly matches. Great way to stay active and meet new people in a relaxed beach setting.",
    location: "Playa de la Barceloneta, Passeig Marítim de la Barceloneta, 16, 08003 Barcelona, Spain",
    event_time: "16:00",
    category: "Sport & Activity",
    end_time: "18:00",
    capacity: 24,
    rundown: "4:00 PM - Meet at beach volleyball courts, 4:15 PM - Warm-up and team formation, 4:30 PM - Round robin tournament begins, 5:30 PM - Finals and awards, 5:45 PM - Group photo and socializing, 6:00 PM - Optional beach drinks"
  },
  {
    title: "Paris Language Exchange - International Evening",
    description: "Practice languages and meet people from around the world at our international evening. Speak French, English, Spanish, German, or any language you want to practice. Fun icebreakers and a friendly atmosphere make language learning enjoyable.",
    location: "Le Comptoir Général, 80 Quai de Jemmapes, 75010 Paris, France",
    event_time: "19:00",
    category: "Study",
    end_time: "22:00",
    capacity: 60,
    rundown: "7:00 PM - Welcome and language level assessment, 7:20 PM - Speed language exchange rounds, 8:00 PM - Group conversation topics, 8:30 PM - Cultural exchange games, 9:00 PM - Open networking and socializing, 9:45 PM - Contact exchange and farewells"
  },
  {
    title: "Amsterdam Craft Beer Tasting - Local Breweries",
    description: "Taste the best of Amsterdam's craft beer scene with our guided brewery tour. Sample unique local brews while learning about Dutch brewing traditions and meeting fellow beer enthusiasts. Includes visits to three different craft breweries.",
    location: "Brouwerij 't IJ, Funenkade 7, 1018 AL Amsterdam, Netherlands",
    event_time: "15:00",
    category: "Party & Social",
    end_time: "18:00",
    capacity: 20,
    rundown: "3:00 PM - Meet at first brewery, 3:15 PM - Brewery tour and tasting 1, 4:00 PM - Walk to second brewery, 4:15 PM - Tasting session 2, 5:00 PM - Final brewery visit, 5:15 PM - Tasting session 3, 5:45 PM - Group discussion and recommendations"
  },
  {
    title: "London Film Screening - Independent Cinema",
    description: "Discover groundbreaking independent films at our monthly screening event. Watch thought-provoking cinema followed by a Q&A with filmmakers and industry professionals. Perfect for film buffs and those interested in contemporary storytelling.",
    location: "Genesis Cinema, 93-95 Mile End Rd, London E1 4UJ, UK",
    event_time: "19:00",
    category: "Community",
    end_time: "21:30",
    capacity: 50,
    rundown: "7:00 PM - Arrival and refreshments, 7:30 PM - Film screening begins, 9:00 PM - Q&A with filmmaker, 9:20 PM - Audience discussion, 9:30 PM - Networking and social drinks"
  },
  {
    title: "Berlin Art Gallery Opening - Contemporary Art",
    description: "Attend an exclusive gallery opening featuring emerging contemporary artists. Meet the artists, view cutting-edge artworks, and network with Berlin's vibrant art community. Complimentary drinks and a sophisticated atmosphere for art enthusiasts.",
    location: "Kunsthaus Dahlem, Käuzchensteig 8, 14195 Berlin, Germany",
    event_time: "18:00",
    category: "Community",
    end_time: "21:00",
    capacity: 80,
    rundown: "6:00 PM - Gallery doors open with welcome drinks, 6:30 PM - Artist introductions and speeches, 7:00 PM - Guided exhibition tour, 7:45 PM - Networking and art viewing, 8:30 PM - Closing remarks and socializing"
  },
  {
    title: "Barcelona Networking - Digital Nomads",
    description: "Connect with Barcelona's growing digital nomad community. Share experiences, exchange tips about remote work, and discover collaboration opportunities. Perfect for location-independent professionals looking to build their network.",
    location: "Betahaus Barcelona, Carrer de Vilafranca, 7, 08024 Barcelona, Spain",
    event_time: "18:00",
    category: "Networking",
    end_time: "20:00",
    capacity: 40,
    rundown: "6:00 PM - Welcome and coworking space tour, 6:20 PM - Digital nomad introductions, 6:45 PM - Skill sharing session, 7:15 PM - Open networking, 7:45 PM - Collaboration opportunities discussion, 8:00 PM - Social drinks and contact exchange"
  },
  {
    title: "Paris Jazz Evening - Live Music",
    description: "Enjoy an intimate evening of live jazz music at one of Paris's legendary jazz clubs. Experience the city's rich musical heritage while meeting fellow music lovers in a cozy, atmospheric setting. Features both established and emerging jazz musicians.",
    location: "Le Duc des Lombards, 42 Rue des Lombards, 75001 Paris, France",
    event_time: "21:00",
    category: "Party & Social",
    end_time: "23:30",
    capacity: 60,
    rundown: "9:00 PM - Arrival and seating, 9:30 PM - First jazz set, 10:15 PM - Intermission and socializing, 10:30 PM - Second jazz set, 11:15 PM - Open jam session, 11:30 PM - Networking and drinks"
  },
  {
    title: "Amsterdam Pottery Workshop - Ceramic Art",
    description: "Get your hands dirty and create beautiful ceramic art in this beginner-friendly pottery workshop. Learn basic techniques like wheel throwing and hand building while creating functional pieces to take home. All materials and tools provided.",
    location: "Clay Amsterdam, Eerste van der Helststraat 19, 1073 AA Amsterdam, Netherlands",
    event_time: "14:00",
    category: "Community",
    end_time: "16:30",
    capacity: 16,
    rundown: "2:00 PM - Introduction to pottery techniques, 2:20 PM - Wheel throwing demonstration, 2:45 PM - Hands-on pottery creation, 3:30 PM - Break and technique refinement, 3:45 PM - Final touches and glazing discussion, 4:15 PM - Cleanup and socializing"
  },
  {
    title: "London Running Club - Thames Riverside",
    description: "Join our friendly running group for a scenic jog along the Thames riverside. All paces welcome - we'll organize groups by speed and stop for photos at iconic London landmarks. Great way to stay fit while exploring the city.",
    location: "Tower Bridge, London SE1 2UP, UK",
    event_time: "09:00",
    category: "Sport & Activity",
    end_time: "10:30",
    capacity: 30,
    rundown: "9:00 AM - Meet at Tower Bridge, 9:10 AM - Warm-up and group formation, 9:20 AM - Start running towards Westminster, 9:50 AM - Photo stop at London Eye, 10:00 AM - Continue to Big Ben, 10:20 AM - Cool down and stretching, 10:30 AM - Optional coffee at nearby café"
  },
  {
    title: "Berlin Music Jam Session - Open Mic",
    description: "Showcase your musical talent or enjoy live performances at our open mic night. All instruments and genres welcome - from acoustic singer-songwriters to electronic producers. Supportive community of musicians and music lovers.",
    location: "Madame Claude, Lübbener Str. 19, 10997 Berlin, Germany",
    event_time: "20:00",
    category: "Party & Social",
    end_time: "23:00",
    capacity: 50,
    rundown: "8:00 PM - Sound check and setup, 8:30 PM - Open mic begins, 9:15 PM - Intermission and networking, 9:30 PM - Second performance set, 10:15 PM - Collaborative jam session, 10:45 PM - Final performances and closing"
  },
  {
    title: "Barcelona Tapas Crawl - Food Adventure",
    description: "Embark on a delicious tapas adventure through Barcelona's historic neighborhoods. Sample traditional and modern tapas at carefully selected local bars while learning about Spanish food culture and meeting fellow food enthusiasts.",
    location: "Cervecería Catalana, Carrer de Mallorca, 236, 08008 Barcelona, Spain",
    event_time: "19:30",
    category: "Party & Social",
    end_time: "22:30",
    capacity: 20,
    rundown: "7:30 PM - Meet at first tapas bar, 7:45 PM - Traditional tapas tasting, 8:30 PM - Walk to second location, 8:45 PM - Modern fusion tapas, 9:30 PM - Final tapas bar, 10:15 PM - Dessert and digestifs, 10:30 PM - Group photo and farewells"
  },
  {
    title: "Paris Startup Weekend - Entrepreneurship",
    description: "Transform your business idea into reality in just 54 hours. Work with a team of passionate entrepreneurs to develop, prototype, and pitch your startup. Mentorship from successful founders and networking with the Paris startup ecosystem.",
    location: "Station F, 5 Parvis Alan Turing, 75013 Paris, France",
    event_time: "18:00",
    category: "Talk",
    end_time: "21:00",
    capacity: 100,
    rundown: "Friday 6:00 PM - Opening pitches and team formation, Friday 9:00 PM - Team building and planning, Saturday 9:00 AM - Workshop sessions and mentorship, Saturday 6:00 PM - Progress presentations, Sunday 9:00 AM - Final pitch preparation, Sunday 6:00 PM - Final pitches and judging, Sunday 9:00 PM - Awards ceremony and celebration"
  },
  {
    title: "Amsterdam Environmental Workshop - Sustainability",
    description: "Learn practical ways to live more sustainably in this hands-on workshop. Discover eco-friendly lifestyle changes, DIY natural products, and local sustainable businesses. Connect with like-minded people passionate about environmental protection.",
    location: "De Ceuvel, Korte Papaverweg 4, 1032 KB Amsterdam, Netherlands",
    event_time: "14:00",
    category: "Study",
    end_time: "16:30",
    capacity: 25,
    rundown: "2:00 PM - Introduction to sustainable living, 2:30 PM - DIY natural cleaning products workshop, 3:15 PM - Zero waste lifestyle tips, 3:45 PM - Local sustainable business showcase, 4:15 PM - Group discussion and action planning, 4:30 PM - Networking and resource sharing"
  },
  {
    title: "London Mindfulness Workshop - Stress Relief",
    description: "Learn practical mindfulness techniques to reduce stress and improve well-being in this supportive group setting. Guided meditation, breathing exercises, and stress management strategies. Perfect for busy professionals and anyone seeking inner peace.",
    location: "The Mindfulness Project, 6 Fitzroy Square, London W1T 5DX, UK",
    event_time: "18:30",
    category: "Sport & Activity",
    end_time: "20:00",
    capacity: 20,
    rundown: "6:30 PM - Arrival and settling in, 6:45 PM - Introduction to mindfulness, 7:00 PM - Guided breathing meditation, 7:20 PM - Stress relief techniques, 7:40 PM - Group discussion and sharing, 7:50 PM - Final meditation and closing"
  },
  {
    title: "Berlin History Tour - Cold War Sites",
    description: "Explore Berlin's fascinating Cold War history on this guided walking tour. Visit iconic sites like the Berlin Wall, Checkpoint Charlie, and hidden historical locations while learning about the city's divided past from expert guides.",
    location: "Brandenburg Gate, Pariser Platz, 10117 Berlin, Germany",
    event_time: "10:00",
    category: "Community",
    end_time: "12:30",
    capacity: 25,
    rundown: "10:00 AM - Meet at Brandenburg Gate, 10:15 AM - Introduction to Cold War Berlin, 10:30 AM - Walk to Berlin Wall Memorial, 11:15 AM - Visit to Checkpoint Charlie, 12:00 PM - Hidden historical sites, 12:15 PM - Discussion and Q&A, 12:30 PM - Tour conclusion"
  },
  {
    title: "Barcelona Photography Meetup - Street Art",
    description: "Capture Barcelona's vibrant street art scene on this guided photography walk. Learn about urban art culture while practicing street photography techniques. Discover hidden murals and graffiti in the city's most artistic neighborhoods.",
    location: "MACBA, Plaça dels Àngels, 1, 08001 Barcelona, Spain",
    event_time: "16:00",
    category: "Community",
    end_time: "18:30",
    capacity: 18,
    rundown: "4:00 PM - Meet at MACBA, 4:15 PM - Street art history briefing, 4:30 PM - Photography techniques workshop, 4:45 PM - Street art hunting in Raval, 5:30 PM - Break and photo sharing, 5:45 PM - Continue to Born district, 6:15 PM - Final photo review and socializing"
  },
  {
    title: "Paris Gourmet Tour - French Cheese & Wine",
    description: "Indulge in France's finest cheeses and wines on this gourmet walking tour. Visit traditional fromageries and wine bars while learning about French culinary traditions from expert guides. Perfect for food lovers wanting an authentic taste of Paris.",
    location: "Fromagerie Laurent Dubois, 47 Ter Bd Saint-Germain, 75005 Paris, France",
    event_time: "17:00",
    category: "Party & Social",
    end_time: "19:30",
    capacity: 16,
    rundown: "5:00 PM - Meet at specialty cheese shop, 5:15 PM - Cheese tasting and education, 5:45 PM - Walk to wine bar, 6:00 PM - Wine and cheese pairing session, 6:45 PM - Visit to second location, 7:00 PM - Final tastings and discussion, 7:30 PM - Tour conclusion and recommendations"
  },
  {
    title: "Amsterdam Dance Workshop - Contemporary",
    description: "Express yourself through contemporary dance in this beginner-friendly workshop. Learn fundamental techniques, improvisation skills, and choreography while building confidence and meeting fellow dance enthusiasts. No previous dance experience required.",
    location: "Dansmakers Amsterdam, Overhoeksplein 1, 1031 KS Amsterdam, Netherlands",
    event_time: "11:00",
    category: "Community",
    end_time: "13:00",
    capacity: 20,
    rundown: "11:00 AM - Warm-up and introductions, 11:20 AM - Contemporary dance basics, 11:45 AM - Improvisation exercises, 12:15 PM - Learning a short choreography, 12:45 PM - Creative expression time, 12:55 PM - Cool down and group reflection"
  },
  {
    title: "London Vegan Cooking Class - Plant-Based Delights",
    description: "Master the art of delicious plant-based cooking in this hands-on class. Learn to create satisfying vegan meals that everyone will love, from mains to desserts. Perfect for vegans, vegetarians, and anyone curious about plant-based cuisine.",
    location: "Cookery School, 1 Cathedral St, London SE1 9DE, UK",
    event_time: "10:00",
    category: "Party & Social",
    end_time: "13:00",
    capacity: 14,
    rundown: "10:00 AM - Welcome and ingredient overview, 10:20 AM - Vegan cooking techniques demo, 10:45 AM - Hands-on cooking session 1, 11:30 AM - Break and discussion, 11:45 AM - Cooking session 2, 12:30 PM - Tasting and recipe sharing, 12:45 PM - Q&A and networking"
  },
  {
    title: "Berlin Karaoke Night - International Hits",
    description: "Sing your heart out at Berlin's most international karaoke night. Choose from songs in multiple languages and meet music lovers from around the world. Supportive atmosphere where everyone's a star - no experience necessary!",
    location: "Monster Ronson's Karaoke, Warschauer Str. 34a, 10243 Berlin, Germany",
    event_time: "21:00",
    category: "Party & Social",
    end_time: "23:30",
    capacity: 40,
    rundown: "9:00 PM - Welcome and song selection, 9:15 PM - Karaoke begins, 10:00 PM - Group sing-along session, 10:30 PM - International hits segment, 11:00 PM - Final performances, 11:20 PM - Awards and socializing, 11:30 PM - After party begins"
  },
  {
    title: "Barcelona Hiking Group - Montjuïc Adventure",
    description: "Explore Barcelona's iconic Montjuïc hill on this guided hiking adventure. Discover gardens, viewpoints, and historical sites while getting exercise and fresh air. Suitable for all fitness levels with plenty of photo opportunities.",
    location: "Plaça d'Espanya, Barcelona, Spain",
    event_time: "10:00",
    category: "Sport & Activity",
    end_time: "13:00",
    capacity: 25,
    rundown: "10:00 AM - Meet at Plaça d'Espanya, 10:15 AM - Hiking safety briefing, 10:30 AM - Begin ascent of Montjuïc, 11:00 AM - Visit to Magic Fountain, 11:30 AM - Continue through gardens, 12:00 PM - Lunch break with views, 12:30 PM - Descent and conclusion"
  },
  {
    title: "Paris Art Workshop - Watercolor Painting",
    description: "Learn watercolor painting techniques in this inspiring workshop set in beautiful Parisian surroundings. Perfect for beginners and intermediate painters wanting to improve their skills. Create beautiful artworks while meeting fellow art enthusiasts.",
    location: "Square du Vert-Galant, 15 Place du Pont Neuf, 75001 Paris, France",
    event_time: "14:00",
    category: "Community",
    end_time: "17:00",
    capacity: 15,
    rundown: "2:00 PM - Meet at park location, 2:15 PM - Watercolor basics and techniques, 2:45 PM - First painting session, 3:30 PM - Break and technique refinement, 3:45 PM - Second painting session, 4:30 PM - Group exhibition and feedback, 4:45 PM - Socializing and contact exchange"
  },
  {
    title: "Amsterdam Storytelling Night - True Stories",
    description: "Share and listen to true stories in this intimate storytelling evening. Whether you have a funny anecdote, life lesson, or inspiring tale, all stories are welcome. Supportive community that celebrates authentic human experiences.",
    location: "Mezrab, Veemkade 576, 1019 BL Amsterdam, Netherlands",
    event_time: "20:00",
    category: "Party & Social",
    end_time: "22:00",
    capacity: 30,
    rundown: "8:00 PM - Welcome and storytelling guidelines, 8:15 PM - First storyteller, 8:30 PM - Open mic sign-ups, 8:45 PM - Storytelling continues, 9:30 PM - Final stories and reflections, 9:45 PM - Group discussion and networking, 10:00 PM - Social drinks and farewells"
  },
  {
    title: "London Chess Club - Strategy & Social",
    description: "Play chess in a friendly, social environment suitable for all skill levels. Whether you're a grandmaster or complete beginner, join us for casual games and tactical discussions. Learn new strategies while meeting fellow chess enthusiasts.",
    location: "The George Inn, 77 Borough High St, London SE1 1NH, UK",
    event_time: "19:00",
    category: "Community",
    end_time: "21:00",
    capacity: 20,
    rundown: "7:00 PM - Arrival and board setup, 7:15 PM - Casual games begin, 7:45 PM - Strategy discussion session, 8:15 PM - Tournament-style pairings, 8:45 PM - Final games and analysis, 9:00 PM - Social drinks and networking"
  },
  {
    title: "Berlin Fashion Workshop - Sustainable Style",
    description: "Discover sustainable fashion practices in this hands-on workshop. Learn about eco-friendly fabrics, upcycling techniques, and ethical fashion choices. Create your own sustainable fashion piece while meeting conscious consumers.",
    location: "Studio 183, Torstraße 183, 10115 Berlin, Germany",
    event_time: "15:00",
    category: "Community",
    end_time: "18:00",
    capacity: 18,
    rundown: "3:00 PM - Introduction to sustainable fashion, 3:30 PM - Fabric selection and design, 4:00 PM - Hands-on creation session, 4:45 PM - Break and inspiration sharing, 5:00 PM - Continue crafting, 5:30 PM - Fashion show and feedback, 5:45 PM - Networking and discussion"
  },
  {
    title: "Barcelona Tech Meetup - AI & Machine Learning",
    description: "Dive deep into artificial intelligence and machine learning with Barcelona's tech community. Learn from industry experts, discover cutting-edge developments, and network with AI professionals and enthusiasts.",
    location: "Pier01 Barcelona, Plaça de Pau Vila, 1, 08039 Barcelona, Spain",
    event_time: "19:00",
    category: "Talk",
    end_time: "21:00",
    capacity: 70,
    rundown: "7:00 PM - Registration and networking, 7:30 PM - AI trends presentation, 8:00 PM - Technical deep dive session, 8:30 PM - Panel discussion, 8:45 PM - Q&A with experts, 9:00 PM - Open networking and drinks"
  },
  {
    title: "Paris Wine & Paint Night - Creative Social",
    description: "Combine wine tasting with painting in this unique social experience. No artistic experience required - follow step-by-step instructions to create your masterpiece while enjoying French wines and meeting creative souls.",
    location: "Artistic Barcelona, Carrer de Balmes, 163, 08008 Barcelona, Spain",
    event_time: "19:00",
    category: "Party & Social",
    end_time: "21:30",
    capacity: 24,
    rundown: "7:00 PM - Welcome wine and canvas setup, 7:15 PM - Artist introduction and first steps, 7:30 PM - Painting session with guidance, 8:15 PM - Wine break and socializing, 8:30 PM - Continue painting, 9:15 PM - Final touches and group photo, 9:30 PM - Artwork takeaway and networking"
  },
  {
    title: "Amsterdam Book Swap - Literature Exchange",
    description: "Bring books you've finished and swap them for new reads at our literary exchange event. Meet fellow book lovers, discover new authors, and enjoy literary discussions in a cozy café setting. Books in all languages welcome.",
    location: "Café de Jaren, Nieuwe Doelenstraat 20-22, 1012 CP Amsterdam, Netherlands",
    event_time: "15:00",
    category: "Community",
    end_time: "17:00",
    capacity: 25,
    rundown: "3:00 PM - Book setup and categorization, 3:20 PM - Introductions and reading preferences, 3:45 PM - Book swapping begins, 4:15 PM - Literary discussions and recommendations, 4:45 PM - Final swaps and contact exchange, 5:00 PM - Coffee and socializing"
  }
]

# ------------------------------------------------------------
# Processing Events
# ------------------------------------------------------------
puts "Creating events..."

# 1. Past 12 events: Jan 2025 to Dec 10 2025
past_events = EVENTS_DATA[0...12]

past_events.each_with_index do |event_data, index|
  year = 2025
  month = index + 1 # 1 to 12
  
  # For December, cap at 10th
  day = if month == 12
          rand(1..10)
        else
          rand(1..28)
        end
  
  date_str = "#{year}-#{month.to_s.rjust(2, '0')}-#{day.to_s.rjust(2, '0')}"
  
  # Combine date and time
  starts_at = Time.zone.parse("#{date_str} #{event_data[:event_time]}")
  
  # Calculate ends_at
  # Note: assuming same day end usually, but if end_time < start_time, it might be next day
  ends_at_time = Time.zone.parse("#{date_str} #{event_data[:end_time]}")
  if ends_at_time < starts_at
    ends_at_time += 1.day
  end

  event = Event.create!(
    organizer: organizers.sample,
    title: event_data[:title],
    description: event_data[:description],
    location: event_data[:location],
    category: event_data[:category],
    starts_at: starts_at,
    ends_at: ends_at_time,
    capacity: event_data[:capacity],
    status: "published",
    registration_open_from: starts_at - 14.days,
    registration_open_until: starts_at - 1.hour
  )

  # Attach random photo
  attach_if_exists(event.photos, EVENT_IMAGES.sample, content_type: "image/jpeg")

  # Process Rundown
  if event_data[:rundown].present?
    # Simple split by comma, hoping description doesn't have commas or we just take broad chunks
    # Better: split by Regex looking for "Time - " pattern if possible, but simpler is splitting by ", "
    items = event_data[:rundown].split(', ')
    items.each_with_index do |item_str, i|
      # Try to split "Time - Description"
      parts = item_str.split(' - ', 2)
      heading = parts[0]
      description = parts[1] || item_str # Fallback
      
      RundownItem.create!(
        event: event,
        heading: heading,
        description: description,
        position: i + 1
      )
    end
  end
  
  puts "Created Past Event: #{event.title} on #{event.starts_at}"
end

# 2. Future events
# Part A: Next 7 Days (Dec 17 - Dec 23) - Force 7 events
upcoming_week_events = EVENTS_DATA[12...19]
upcoming_week_events.each_with_index do |event_data, index|
  date = Date.new(2025, 12, 17) + index.days
  date_str = date.strftime("%Y-%m-%d")

  starts_at = Time.zone.parse("#{date_str} #{event_data[:event_time]}")
  ends_at_time = Time.zone.parse("#{date_str} #{event_data[:end_time]}")
  if ends_at_time < starts_at
    ends_at_time += 1.day
  end

  event = Event.create!(
    organizer: organizers.sample,
    title: event_data[:title],
    description: event_data[:description],
    location: event_data[:location],
    category: event_data[:category],
    starts_at: starts_at,
    ends_at: ends_at_time,
    capacity: event_data[:capacity],
    status: "published",
    registration_open_from: starts_at - 14.days,
    registration_open_until: starts_at - 1.hour
  )

  attach_if_exists(event.photos, EVENT_IMAGES.sample, content_type: "image/jpeg")

  if event_data[:rundown].present?
    items = event_data[:rundown].split(', ')
    items.each_with_index do |item_str, i|
      parts = item_str.split(' - ', 2)
      heading = parts[0]
      description = parts[1] || item_str
      
      RundownItem.create!(
        event: event,
        heading: heading,
        description: description,
        position: i + 1
      )
    end
  end

  puts "Created Force Upcoming Event: #{event.title} on #{event.starts_at}"
end

# Part B: Remaining Future Events (Dec 24 2025 to June 30 2026)
remaining_future_events = EVENTS_DATA[19..-1]
start_range = Date.new(2025, 12, 24)
end_range = Date.new(2026, 6, 30)
date_range = (start_range..end_range).to_a

remaining_future_events.each do |event_data|
  # Pick a random date
  date = date_range.sample
  date_str = date.strftime("%Y-%m-%d")

  starts_at = Time.zone.parse("#{date_str} #{event_data[:event_time]}")
  ends_at_time = Time.zone.parse("#{date_str} #{event_data[:end_time]}")
  if ends_at_time < starts_at
    ends_at_time += 1.day
  end

  event = Event.create!(
    organizer: organizers.sample,
    title: event_data[:title],
    description: event_data[:description],
    location: event_data[:location],
    category: event_data[:category],
    starts_at: starts_at,
    ends_at: ends_at_time,
    capacity: event_data[:capacity],
    status: "published",
    registration_open_from: starts_at - 14.days,
    registration_open_until: starts_at - 1.hour
  )

  attach_if_exists(event.photos, EVENT_IMAGES.sample, content_type: "image/jpeg")

  # Process Rundown
  if event_data[:rundown].present?
    items = event_data[:rundown].split(', ')
    items.each_with_index do |item_str, i|
      parts = item_str.split(' - ', 2)
      heading = parts[0]
      description = parts[1] || item_str
      
      RundownItem.create!(
        event: event,
        heading: heading,
        description: description,
        position: i + 1
      )
    end
  end
  
  puts "Created Future Event: #{event.title} on #{event.starts_at}"
end

# ------------------------------------------------------------
# Registrations
# ------------------------------------------------------------
puts "Creating registrations..."
events = Event.all
events.each do |event|
  # Ensure at least 3 attendees, up to capacity (or 15 if capacity is large/nil)
  max_limit = event.capacity ? [15, event.capacity].min : 15
  # Should not happen given our seeds, but safety first
  max_limit = 3 if max_limit < 3
  
  # Shuffle attendees so we don't always pick the same ones in order
  possible_attendees = attendee_users.shuffle
  
  Faker::Number.between(from: 3, to: max_limit).times do
    attendee = possible_attendees.pop
    break unless attendee # allow breaking if we run out of unique users (unlikely)
    
    next if Registration.exists?(event: event, user: attendee)

    status = %w[registered registered registered checked_in cancelled].sample
    
    # Don't check in if event is in future
    if status == "checked_in" && event.starts_at > Time.current
      status = "registered"
    end

    Registration.create!(
      event: event,
      user: attendee,
      email: attendee.email,
      name: attendee.full_name,
      status: status,
      check_in_at: status == "checked_in" ? Faker::Time.between(from: event.starts_at, to: Time.current) : nil,
      cancelled_at: status == "cancelled" ? Faker::Time.between(from: event.registration_open_from, to: Time.current) : nil
    )
  end
end

puts "✅ SEED DATA CREATED SUCCESSFULLY"
puts "System Users (Organizers): #{organizers.count}"
puts "Attendee Users: #{attendee_users.count}"
puts "Total Users: #{User.count}"
puts "Events: #{Event.count}"
puts "Registrations: #{Registration.count}"
