# Development Dataset for Testing
# This file creates comprehensive test data for development environment only
# DO NOT RUN IN PRODUCTION
#
# Usage: mix run priv/repo/dev_seeds.exs

if Mix.env() == :prod do
  IO.puts("❌ This seed file is for development only. Skipping in production.")
  exit(:normal)
end

import Ecto.Query
alias Sahajyog.Repo

# Import all schemas
alias Sahajyog.Accounts.User
alias Sahajyog.Content.{Video, WeeklyVideoAssignment}
alias Sahajyog.Events.{Event, EventProposal, EventTask, EventTeamMember, EventTransportation, EventCarpool}
alias Sahajyog.Topics.{Topic, TopicProposal}
alias Sahajyog.Resources.Resource
alias Sahajyog.Progress.WatchedVideo
alias Sahajyog.Admin.AccessCode

IO.puts("\n🚀 Creating comprehensive development dataset...\n")

# Clear existing data (development only)
IO.puts("🧹 Clearing existing test data...")
Repo.delete_all(WatchedVideo)
Repo.delete_all(WeeklyVideoAssignment)
Repo.delete_all(AccessCode)
Repo.delete_all(EventCarpool)
Repo.delete_all(EventTransportation)
Repo.delete_all(EventTask)
Repo.delete_all(EventTeamMember)
Repo.delete_all(EventProposal)
Repo.delete_all(Event)
Repo.delete_all(TopicProposal)
Repo.delete_all(Topic)
Repo.delete_all(Resource)
Repo.delete_all(Video)
Repo.delete_all(from(u in User, where: u.email != "paulpetrut@yahoo.com"))

IO.puts("✓ Cleared existing test data")

# Create diverse test users
test_users = [
  %{
    email: "admin@test.com",
    password: "admin123admin",
    role: "admin",
    confirmed_at: DateTime.utc_now(:second)
  },
  %{
    email: "manager@test.com",
    password: "manager123456",
    role: "user",
    confirmed_at: DateTime.utc_now(:second)
  },
  %{
    email: "user@test.com",
    password: "user123456789",
    role: "user",
    confirmed_at: DateTime.utc_now(:second)
  },
  %{
    email: "newbie@test.com",
    password: "newbie123456",
    role: "user",
    confirmed_at: DateTime.utc_now(:second)
  },
  %{
    email: "advanced@test.com",
    password: "advanced123456",
    role: "user",
    confirmed_at: DateTime.utc_now(:second)
  },
  %{
    email: "organizer@test.com",
    password: "organizer123456",
    role: "user",
    confirmed_at: DateTime.utc_now(:second)
  }
]

created_users = Enum.map(test_users, fn user_attrs ->
  case Repo.get_by(User, email: user_attrs.email) do
    nil ->
      {:ok, user} = %User{}
        |> User.email_changeset(user_attrs, validate_unique: false)
        |> User.password_changeset(user_attrs, hash_password: true)
        |> Ecto.Changeset.put_change(:role, user_attrs.role)
        |> Ecto.Changeset.put_change(:confirmed_at, user_attrs.confirmed_at)
        |> Repo.insert()
      IO.puts("✓ Created user: #{user.email}")
      user
    existing ->
      IO.puts("⏭️  User exists: #{existing.email}")
      existing
  end
end)

[admin, manager, regular_user, newbie, advanced_user, organizer] = created_users

# Create comprehensive video dataset
sample_videos = [
  # Welcome category
  %{
    title: "Welcome to Sahaja Yoga",
    url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
    category: "Welcome",
    description: "An introduction to the practice of Sahaja Yoga meditation and its benefits for modern life.",
    thumbnail_url: "https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg",
    duration: "15:30",
    step_number: 1,
    provider: "youtube",
    in_pool: true,
    pool_position: 1
  },
  %{
    title: "Understanding Self-Realization",
    url: "https://www.youtube.com/watch?v=oHg5SJYRHA0",
    category: "Welcome",
    description: "Learn about the spontaneous awakening of the Kundalini energy and its significance.",
    thumbnail_url: "https://img.youtube.com/vi/oHg5SJYRHA0/maxresdefault.jpg",
    duration: "22:45",
    step_number: 2,
    provider: "youtube",
    in_pool: true,
    pool_position: 2
  },

  # Getting Started category
  %{
    title: "Your First Meditation Experience",
    url: "https://www.youtube.com/watch?v=9bZkp7q19f0",
    category: "Getting Started",
    description: "A guided meditation session for beginners to experience thoughtless awareness.",
    thumbnail_url: "https://img.youtube.com/vi/9bZkp7q19f0/maxresdefault.jpg",
    duration: "18:20",
    step_number: 3,
    provider: "youtube",
    in_pool: true,
    pool_position: 3
  },
  %{
    title: "Understanding the Chakras",
    url: "https://www.youtube.com/watch?v=PSZxmZmBfnU",
    category: "Getting Started",
    description: "Explore the seven energy centers and their role in spiritual development.",
    thumbnail_url: "https://img.youtube.com/vi/PSZxmZmBfnU/maxresdefault.jpg",
    duration: "35:15",
    step_number: 4,
    provider: "youtube",
    in_pool: true,
    pool_position: 4
  },
  %{
    title: "Daily Meditation Practice",
    url: "https://www.youtube.com/watch?v=kJQP7kiw5Fk",
    category: "Getting Started",
    description: "Establishing a regular meditation routine for spiritual growth.",
    thumbnail_url: "https://img.youtube.com/vi/kJQP7kiw5Fk/maxresdefault.jpg",
    duration: "12:30",
    step_number: 5,
    provider: "youtube",
    in_pool: true,
    pool_position: 5
  },

  # Advanced Topics
  %{
    title: "The Subtle System in Detail",
    url: "https://www.youtube.com/watch?v=LsoLEjrDogU",
    category: "Advanced Topics",
    description: "Deep dive into the intricate workings of the subtle energy system.",
    thumbnail_url: "https://img.youtube.com/vi/LsoLEjrDogU/maxresdefault.jpg",
    duration: "45:20",
    step_number: 6,
    provider: "youtube",
    in_pool: true,
    pool_position: 6
  },
  %{
    title: "Collective Consciousness",
    url: "https://www.youtube.com/watch?v=fJ9rUzIMcZQ",
    category: "Advanced Topics",
    description: "Understanding our connection to the collective and universal consciousness.",
    thumbnail_url: "https://img.youtube.com/vi/fJ9rUzIMcZQ/maxresdefault.jpg",
    duration: "38:45",
    step_number: 7,
    provider: "youtube",
    in_pool: true,
    pool_position: 7
  },
  %{
    title: "Balancing Techniques",
    url: "https://vimeo.com/123456789",
    category: "Advanced Topics",
    description: "Advanced methods for chakra balancing and energy harmonization.",
    thumbnail_url: "https://i.vimeocdn.com/video/123456789_640.jpg",
    duration: "28:10",
    step_number: 8,
    provider: "vimeo",
    in_pool: true,
    pool_position: 8
  },

  # Excerpts
  %{
    title: "On Inner Peace",
    url: "https://www.youtube.com/watch?v=Zi_XLOBDo_Y",
    category: "Excerpts",
    description: "Shri Mataji speaks about finding true peace within ourselves.",
    thumbnail_url: "https://img.youtube.com/vi/Zi_XLOBDo_Y/maxresdefault.jpg",
    duration: "8:15",
    provider: "youtube",
    in_pool: true,
    pool_position: 9
  },
  %{
    title: "The Nature of Joy",
    url: "https://www.youtube.com/watch?v=b0p9xVwGJ5w",
    category: "Excerpts",
    description: "Understanding the difference between happiness and true joy.",
    thumbnail_url: "https://img.youtube.com/vi/b0p9xVwGJ5w/maxresdefault.jpg",
    duration: "6:30",
    provider: "youtube",
    in_pool: true,
    pool_position: 10
  },
  %{
    title: "Wisdom and Knowledge",
    url: "https://www.youtube.com/watch?v=NUYvbT6vTPs",
    category: "Excerpts",
    description: "The distinction between intellectual knowledge and inner wisdom.",
    thumbnail_url: "https://img.youtube.com/vi/NUYvbT6vTPs/maxresdefault.jpg",
    duration: "11:45",
    provider: "youtube",
    in_pool: false
  },
  %{
    title: "Love and Compassion",
    url: "https://www.youtube.com/watch?v=2vjPBrBU-TM",
    category: "Excerpts",
    description: "The role of divine love in spiritual transformation.",
    thumbnail_url: "https://img.youtube.com/vi/2vjPBrBU-TM/maxresdefault.jpg",
    duration: "9:20",
    provider: "youtube",
    in_pool: false
  }
]

created_videos = Enum.map(sample_videos, fn video_attrs ->
  {:ok, video} = %Video{}
    |> Video.changeset(video_attrs)
    |> Repo.insert()
  IO.puts("✓ Created video: #{video.title}")
  video
end)

# Create weekly video assignments for current year
current_year = Date.utc_today().year
pool_videos = Enum.filter(created_videos, & &1.in_pool)

weekly_assignments = Enum.with_index(pool_videos, 1)
  |> Enum.map(fn {video, week} ->
    %{
      year: current_year,
      week_number: week,
      video_id: video.id
    }
  end)

Enum.each(weekly_assignments, fn assignment_attrs ->
  {:ok, _assignment} = %WeeklyVideoAssignment{}
    |> WeeklyVideoAssignment.changeset(assignment_attrs)
    |> Repo.insert()
  IO.puts("✓ Created weekly assignment: Week #{assignment_attrs.week_number}")
end)

# Create comprehensive topics dataset
sample_topics = [
  %{
    title: "Understanding the Chakras",
    content: """
    <h2>The Seven Main Chakras</h2>
    <p>The chakras are energy centers within the subtle body that play a crucial role in our spiritual development. In Sahaja Yoga, we work with seven main chakras, each governing different aspects of our being.</p>

    <h3>1. Mooladhara Chakra (Root Chakra)</h3>
    <p>Located at the base of the spine, this chakra represents innocence and wisdom. It is associated with the color red and governs our foundation and sense of security.</p>

    <h3>2. Swadisthan Chakra (Sacral Chakra)</h3>
    <p>Located in the abdomen, this chakra governs creativity and pure knowledge. It is associated with the color yellow and influences our creative expression.</p>

    <h3>3. Nabhi Chakra (Solar Plexus)</h3>
    <p>Located at the navel, this chakra represents satisfaction and peace. It is associated with the color green and governs our sense of fulfillment.</p>

    <h3>4. Anahata Chakra (Heart Chakra)</h3>
    <p>Located at the heart, this is the center of love and compassion. It is associated with the color red and governs our capacity for love.</p>

    <h3>5. Vishuddhi Chakra (Throat Chakra)</h3>
    <p>Located at the throat, this chakra governs communication and collectivity. It is associated with the color blue and influences our expression.</p>

    <h3>6. Agnya Chakra (Third Eye)</h3>
    <p>Located at the forehead, this chakra represents forgiveness and humility. It is associated with the color white and governs our mental clarity.</p>

    <h3>7. Sahasrara Chakra (Crown Chakra)</h3>
    <p>Located at the top of the head, this is the seat of integration and self-realization. It is associated with all colors and represents our connection to the divine.</p>
    """,
    status: "published",
    language: "en",
    user_id: admin.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "The Practice of Meditation",
    content: """
    <h2>Thoughtless Awareness</h2>
    <p>Meditation in Sahaja Yoga is a state of thoughtless awareness where we experience the present momenthout mental chatter. This practice helps us connect with our inner self and achieve balance.</p>

    <h3>Getting Started</h3>
    <p>To begin meditation, find a quiet space where you won't be disturbed. Sit comfortably with your feet flat on the ground and your hands open on your lap, palms facing upward.</p>

    <h3>The Process</h3>
    <ol>
      <li>Close your eyes and bring your attention to the top of your head</li>
      <li>Feel the cool breeze of the Kundalini energy flowing through your crown chakra</li>
      <li>If thoughts arise, simply observe them without judgment and let them pass</li>
      <li>The goal is not to suppress thoughts but to transcend them naturally</li>
    </ol>

    <h3>Benefits</h3>
    <p>Regular practice, even for just 10-15 minutes daily, can bring profound changes in your life:</p>
    <ul>
      <li>Reduced stress and anxiety</li>
      <li>Improved focus and concentration</li>
      <li>A deeper sense of peace and joy</li>
      <li>Enhanced emotional balance</li>
    </ul>
    """,
    status: "published",
    language: "en",
    user_id: admin.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "Kundalini Awakening",
    content: """
    <h2>The Dormant Spiritual Energy</h2>
    <p>The Kundalini is the dormant spiritual energy that resides at the base of the spine. In Sahaja Yoga, this energy is awakened spontaneously through Self-Realization.</p>

    <h3>Natural Awakening</h3>
    <p>Unlike other practices that may take years of effort, Sahaja Yoga offers a simple and natural way to awaken the Kundalini. This awakening happens through the grace of the Divine and cannot be forced.</p>

    <h3>The Process</h3>
    <p>When the Kundalini rises, it passes through each chakra, cleansing and nourishing them. You may feel a cool breeze on your palms or at the top of your head - this is a sign of the Kundalini awakening.</p>

    <h3>Ongoing Growth</h3>
    <p>After awakening, the Kundalini continues to work within us, helping us grow spiritually and overcome our limitations. Regular meditation helps strengthen this connection.</p>
    """,
    status: "published",
    language: "en",
    user_id: manager.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "Balancing Work and Spiritual Life",
    content: """
    <h2>Integration in Daily Life</h2>
    <p>One of the beautiful aspects of Sahaja Yoga is how it integrates seamlessly into our daily lives, helping us maintain spiritual awareness while fulfilling our worldly responsibilities.</p>

    <h3>Morning Practice</h3>
    <p>Start your day with a short meditation session. Even 10 minutes can set a positive tone for the entire day and help you maintain your center throughout various challenges.</p>

    <h3>Workplace Awareness</h3>
    <p>Maintain awareness of your chakras during work. If you feel stressed or overwhelmed, take a moment to check your energy centers and apply simple balancing techniques.</p>

    <h3>Evening Reflection</h3>
    <p>End your day with gratitude and a brief meditation to clear any accumulated stress and prepare for restful sleep.</p>
    """,
    status: "published",
    language: "en",
    user_id: advanced_user.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "The Role of Music in Meditation",
    content: """
    <h2>Vibrational Healing</h2>
    <p>Music plays a profound role in Sahaja Yoga meditation, helping to elevate our consciousness and deepen our spiritual experience.</p>

    <h3>Classical Music</h3>
    <p>Classical music, particularly Indian ragas and Western classical compositions, can help balance our chakras and create the right atmosphere for meditation.</p>

    <h3>Bhajans and Mantras</h3>
    <p>Devotional songs and mantras carry special vibrations that can help awaken and nourish our spiritual centers.</p>
    """,
    status: "draft",
    language: "en",
    user_id: regular_user.id
  }
]

created_topics = Enum.map(sample_topics, fn topic_attrs ->
  {:ok, topic} = %Topic{}
    |> Topic.changeset(topic_attrs)
    |> Repo.insert()
  IO.puts("✓ Created topic: #{topic.title}")
  topic
end)

# Create topic proposals
sample_topic_proposals = [
  %{
    title: "Meditation for Children",
    description: "How to introduce young children to meditation in an age-appropriate way, focusing on simple techniques and playful approaches.",
    status: "pending",
    proposed_by_id: regular_user.id
  },
  %{
    title: "Dealing with Negative Emotions",
    description: "Practical guidance on using Sahaja Yoga techniques to transform anger, fear, and other challenging emotions.",
    status: "approved",
    proposed_by_id: newbie.id
  },
  %{
    title: "The Science Behind Meditation",
    description: "Exploring the scientific research that validates the benefits of meditation and spiritual practices.",
    status: "pending",
    proposed_by_id: advanced_user.id
  }
]

Enum.each(sample_topic_proposals, fn proposal_attrs ->
  {:ok, _proposal} = %TopicProposal{}
    |> TopicProposal.changeset(proposal_attrs)
    |> Repo.insert()
  IO.puts("✓ Created topic proposal: #{proposal_attrs.title}")
end)

# Create comprehensive events dataset
sample_events = [
  %{
    title: "Summer Meditation Retreat 2025",
    description: """
    <h2>Transform Your Summer</h2>
    <p>Join us for a transformative weekend of meditation and spiritual growth in the beautiful Italian countryside.</p>

    <h3>What's Included:</h3>
    <ul>
      <li>Daily group meditations at sunrise and sunset</li>
      <li>Chakra balancing workshops</li>
      <li>Nature walks and outdoor activities</li>
      <li>Vegetarian meals prepared with love</li>
      <li>Cultural program with music and dance</li>
    </ul>

    <h3>Accommodation:</h3>
    <p>Comfortable shared rooms in a peaceful retreat center surrounded by nature.</p>
    """,
    status: "public",
    event_date: ~D[2025-07-15],
    event_time: ~T[09:00:00],
    end_date: ~D[2025-07-17],
    end_time: ~T[18:00:00],
    estimated_participants: 50,
    city: "Rome",
    country: "Italy",
    address: "Via della Spiritualità 42, 00100 Roma",
    venue_name: "Centro Meditazione Roma",
    venue_website: "https://example.com/centro-roma",
    google_maps_link: "https://maps.google.com/?q=Rome,Italy",
    budget_total: Decimal.new("5000.00"),
    budget_notes: "Venue rental: €2000\nFood & catering: €2000\nMaterials: €500\nMiscellaneous: €500",
    resources_required: "Meditation cushions, sound system, projector, microphone",
    banking_name: "Sahaja Yoga Italia",
    banking_iban: "IT60X0542811101000000123456",
    banking_swift: "BPPIITRRXXX",
    banking_notes: "Please use 'Summer Retreat 2025' as payment reference",
    user_id: admin.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "Winter Solstice Celebration",
    description: """
    <h2>Celebrate the Light Within</h2>
    <p>Join us for a special evening of collective meditation and traditional bhajans to celebrate the winter solstice.</p>

    <h3>Program:</h3>
    <ul>
      <li>Group meditation (18:00 - 19:00)</li>
      <li>Bhajan singing (19:00 - 20:30)</li>
      <li>Light refreshments (20:30 - 21:00)</li>
      <li>Closing meditation (21:00 - 22:00)</li>
    </ul>
    """,
    status: "public",
    event_date: ~D[2025-12-21],
    event_time: ~T[18:00:00],
    end_time: ~T[22:00:00],
    estimated_participants: 30,
    city: "Bucharest",
    country: "Romania",
    address: "Strada Meditației 15, București",
    venue_name: "Casa Sahaja",
    budget_total: Decimal.new("500.00"),
    user_id: organizer.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "Spring Awakening Workshop",
    description: """
    <h2>Renew Your Spirit</h2>
    <p>A one-day workshop focused on chakra awakening and inner balance, perfect for beginners and experienced practitioners alike.</p>
    """,
    status: "draft",
    event_date: ~D[2025-03-21],
    event_time: ~T[10:00:00],
    end_time: ~T[17:00:00],
    estimated_participants: 25,
    city: "Vienna",
    country: "Austria",
    address: "Friedensstraße 7, 1010 Wien",
    venue_name: "Yoga Zentrum Wien",
    user_id: manager.id
  },
  %{
    title: "Weekend Meditation Camp",
    description: """
    <h2>Immerse in Nature</h2>
    <p>Two days of intensive meditation practice in the beautiful Bavarian countryside.</p>
    """,
    status: "public",
    event_date: ~D[2025-05-10],
    event_time: ~T[08:00:00],
    end_date: ~D[2025-05-11],
    end_time: ~T[18:00:00],
    estimated_participants: 40,
    city: "Munich",
    country: "Germany",
    address: "Waldweg 23, 80331 München",
    venue_name: "Naturcamp Bayern",
    budget_total: Decimal.new("3000.00"),
    user_id: admin.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "Monthly Meditation Circle",
    description: """
    <h2>Regular Practice</h2>
    <p>Join our monthly meditation circle for collective meditation and spiritual sharing.</p>
    """,
    status: "public",
    event_date: ~D[2025-02-15],
    event_time: ~T[19:00:00],
    end_time: ~T[21:00:00],
    estimated_participants: 15,
    city: "Prague",
    country: "Czech Republic",
    address: "Náměstí Míru 10, Praha",
    venue_name: "Community Center",
    user_id: regular_user.id,
    published_at: DateTime.utc_now(:second)
  }
]

created_events = Enum.map(sample_events, fn event_attrs ->
  {:ok, event} = %Event{}
    |> Event.changeset(event_attrs)
    |> Repo.insert()
  IO.puts("✓ Created event: #{event.title}")
  event
end)

[summer_retreat, winter_solstice, spring_workshop, weekend_camp, monthly_circle] = created_events

# Create event proposals
sample_event_proposals = [
  %{
    title: "Autumn Meditation Weekend",
    description: "A weekend retreat in the countryside to celebrate the autumn season with meditation and nature walks.",
    event_date: ~D[2025-10-15],
    city: "Prague",
    country: "Czech Republic",
    status: "pending",
    proposed_by_id: regular_user.id
  },
  %{
    title: "New Year Meditation Marathon",
    description: "24-hour meditation marathon to welcome the new year with a collective spiritual experience.",
    event_date: ~D[2025-12-31],
    city: "Paris",
    country: "France",
    status: "approved",
    proposed_by_id: newbie.id
  },
  %{
    title: "Youth Meditation Workshop",
    description: "Special workshop designed for young adults (18-30) to explore meditation and spirituality.",
    event_date: ~D[2025-04-20],
    city: "Berlin",
    country: "Germany",
    status: "pending",
    proposed_by_id: advanced_user.id
  }
]

Enum.each(sample_event_proposals, fn proposal_attrs ->
  {:ok, _proposal} = %EventProposal{}
    |> EventProposal.changeset(proposal_attrs)
    |> Repo.insert()
  IO.puts("✓ Created event proposal: #{proposal_attrs.title}")
end)

# Create event tasks for multiple events
summer_retreat_tasks = [
  %{
    title: "Book venue",
    description: "Confirm reservation and pay deposit for the retreat center",
    status: "completed",
    due_date: ~D[2025-06-01],
    estimated_expense: Decimal.new("2000.00"),
    actual_expense: Decimal.new("2000.00"),
    event_id: summer_retreat.id,
    assigned_user_id: admin.id,
    position: 1
  },
  %{
    title: "Arrange catering",
    description: "Contact vegetarian caterer for 50 people, confirm menu and dietary requirements",
    status: "in_progress",
    due_date: ~D[2025-06-15],
    estimated_expense: Decimal.new("2000.00"),
    event_id: summer_retreat.id,
    assigned_user_id: organizer.id,
    position: 2
  },
  %{
    title: "Prepare materials",
    description: "Print schedules, prepare meditation materials, create welcome packages",
    status: "pending",
    due_date: ~D[2025-07-01],
    estimated_expense: Decimal.new("500.00"),
    event_id: summer_retreat.id,
    assigned_user_id: manager.id,
    position: 3
  },
  %{
    title: "Set up sound system",
    description: "Test and configure audio equipment for meditation sessions and bhajans",
    status: "pending",
    due_date: ~D[2025-07-14],
    event_id: summer_retreat.id,
    assigned_user_id: advanced_user.id,
    position: 4
  }
]

winter_solstice_tasks = [
  %{
    title: "Reserve venue",
    description: "Book Casa Sahaja for the evening event",
    status: "completed",
    due_date: ~D[2025-11-01],
    event_id: winter_solstice.id,
    assigned_user_id: organizer.id,
    position: 1
  },
  %{
    title: "Organize bhajan singers",
    description: "Coordinate with local musicians for the bhajan session",
    status: "in_progress",
    due_date: ~D[2025-12-01],
    event_id: winter_solstice.id,
    assigned_user_id: regular_user.id,
    position: 2
  },
  %{
    title: "Prepare refreshments",
    description: "Arrange light vegetarian snacks and herbal teas",
    status: "pending",
    due_date: ~D[2025-12-15],
    estimated_expense: Decimal.new("200.00"),
    event_id: winter_solstice.id,
    position: 3
  }
]

all_tasks = summer_retreat_tasks ++ winter_solstice_tasks

Enum.each(all_tasks, fn task_attrs ->
  {:ok, _task} = %EventTask{}
    |> EventTask.changeset(task_attrs)
    |> Repo.insert()
  IO.puts("✓ Created task: #{task_attrs.title}")
end)

# Create transportation options
sample_transportation = [
  %{
    transport_type: "public",
    title: "From Rome Termini Station",
    description: "Take Metro Line A to Flaminio, then bus 32 to the venue (approx 45 min)",
    departure_location: "Roma Termini",
    event_id: summer_retreat.id,
    position: 1
  },
  %{
    transport_type: "bus",
    title: "Event Shuttle Bus",
    description: "Free shuttle service from Rome city center",
    departure_location: "Piazza del Popolo",
    departure_time: ~T[08:00:00],
    estimated_cost: Decimal.new("0.00"),
    contact_info: "shuttle@example.com",
    event_id: summer_retreat.id,
    position: 2
  },
  %{
    transport_type: "public",
    title: "From Bucharest North Station",
    description: "Take Metro Line M2 to Piața Victoriei, then tram 1 to venue (30 min)",
    departure_location: "Gara de Nord",
    event_id: winter_solstice.id,
    position: 1
  }
]

Enum.each(sample_transportation, fn trans_attrs ->
  {:ok, _trans} = %EventTransportation{}
    |> EventTransportation.changeset(trans_attrs)
    |> Repo.insert()
  IO.puts("✓ Created transport: #{trans_attrs.title}")
end)

# Create carpools
sample_carpools = [
  %{
    departure_location: "Milan Central Station",
    departure_time: ~T[06:00:00],
    available_seats: 3,
    contact_phone: "+39 123 456 7890",
    notes: "Will stop for breakfast on the way. Non-smoking car.",
    status: "open",
    event_id: summer_retreat.id,
    driver_user_id: advanced_user.id
  },
  %{
    departure_location: "Florence Train Station",
    departure_time: ~T[07:30:00],
    available_seats: 2,
    contact_phone: "+39 987 654 3210",
    notes: "Direct route, comfortable car with AC",
    status: "open",
    event_id: summer_retreat.id,
    driver_user_id: manager.id
  },
  %{
    departure_location: "Constanța City Center",
    departure_time: ~T[16:00:00],
    available_seats: 4,
    contact_phone: "+40 123 456 789",
    notes: "Returning to Constanța after the event",
    status: "open",
    event_id: winter_solstice.id,
    driver_user_id: regular_user.id
  }
]

Enum.each(sample_carpools, fn carpool_attrs ->
  {:ok, _carpool} = %EventCarpool{}
    |> EventCarpool.changeset(carpool_attrs)
    |> Repo.insert()
  IO.puts("✓ Created carpool from: #{carpool_attrs.departure_location}")
end)

# Create access codes
sample_access_codes = [
  %{
    code: "SUMMER2025",
    max_uses: 50,
    event_id: summer_retreat.id,
    created_by_id: admin.id
  },
  %{
    code: "WINTER2025",
    max_uses: 30,
    event_id: winter_solstice.id,
    created_by_id: organizer.id
  },
  %{
    code: "SPRING2025",
    max_uses: 25,
    event_id: spring_workshop.id,
    created_by_id: manager.id
  },
  %{
    code: "GENERAL2025",
    max_uses: 100,
    created_by_id: admin.id
  }
]

Enum.each(sample_access_codes, fn code_attrs ->
  {:ok, _code} = %AccessCode{}
    |> AccessCode.changeset(code_attrs)
    |> Repo.insert()
  IO.puts("✓ Created access code: #{code_attrs.code}")
end)

# Create sample resources (mock data since we can't upload real files)
sample_resources = [
  %{
    title: "Beginner's Guide to Sahaja Yoga",
    description: "A comprehensive PDF guide covering the basics of Sahaja Yoga meditation practice.",
    file_name: "beginners_guide.pdf",
    file_size: 2_500_000,
    content_type: "application/pdf",
    r2_key: "resources/beginners_guide_#{:rand.uniform(10000)}.pdf",
    level: "Level1",
    resource_type: "Books",
    language: "en",
    user_id: admin.id
  },
  %{
    title: "Chakra Meditation Music",
    description: "Soothing instrumental music designed to balance and harmonize the chakras.",
    file_name: "chakra_music.mp3",
    file_size: 15_000_000,
    content_type: "audio/mpeg",
    r2_key: "resources/chakra_music_#{:rand.uniform(10000)}.mp3",
    level: "Level1",
    resource_type: "Music",
    language: "en",
    user_id: admin.id
  },
  %{
    title: "Retreat Photos 2024",
    description: "Beautiful photos from our annual meditation retreat in the mountains.",
    file_name: "retreat_photos_2024.zip",
    file_size: 45_000_000,
    content_type: "application/zip",
    r2_key: "resources/retreat_photos_#{:rand.uniform(10000)}.zip",
    level: "Level2",
    resource_type: "Photos",
    language: "en",
    user_id: organizer.id
  },
  %{
    title: "Advanced Meditation Techniques",
    description: "In-depth guide to advanced meditation practices and subtle system understanding.",
    file_name: "advanced_techniques.pdf",
    file_size: 5_200_000,
    content_type: "application/pdf",
    r2_key: "resources/advanced_techniques_#{:rand.uniform(10000)}.pdf",
    level: "Level3",
    resource_type: "Books",
    language: "en",
    user_id: advanced_user.id
  },
  %{
    title: "Bhajan Collection",
    description: "Traditional devotional songs in multiple languages with lyrics and translations.",
    file_name: "bhajan_collection.pdf",
    file_size: 3_800_000,
    content_type: "application/pdf",
    r2_key: "resources/bhajan_collection_#{:rand.uniform(10000)}.pdf",
    level: "Level2",
    resource_type: "Music",
    language: "en",
    user_id: manager.id
  }
]

created_resources = Enum.map(sample_resources, fn resource_attrs ->
  {:ok, resource} = %Resource{}
    |> Resource.changeset(resource_attrs)
    |> Repo.insert()
  IO.puts("✓ Created resource: #{resource.title}")
  resource
end)

# Create watched video progress for users
# Simulate different users at different stages of their journey
watched_videos_data = [
  # Newbie - just started, watched welcome videos
  {newbie.id, Enum.take(created_videos, 2)},
  # Regular user - moderate progress
  {regular_user.id, Enum.take(created_videos, 5)},
  # Advanced user - watched most videos
  {advanced_user.id, Enum.take(created_videos, 8)},
  # Manager - watched some videos
  {manager.id, Enum.take(created_videos, 4)}
]

Enum.each(watched_videos_data, fn {user_id, videos} ->
  Enum.with_index(videos)
  |> Enum.each(fn {video, index} ->
    days_ago = length(videos) - index
    watched_at = DateTime.utc_now(:second) |> DateTime.add(-days_ago * 24 * 60 * 60, :second)

    {:ok, _watched} = %WatchedVideo{}
      |> WatchedVideo.changeset(%{
        user_id: user_id,
        video_id: video.id,
        watched_at: watched_at
      })
      |> Repo.insert()
  end)

  user = Repo.get!(User, user_id)
  IO.puts("✓ Created watch history for: #{user.email} (#{length(videos)} videos)")
end)

# Add some download counts to resources
Enum.each(created_resources, fn resource ->
  download_count = :rand.uniform(50)
  resource
  |> Ecto.Changeset.change(downloads_count: download_count)
  |> Repo.update!()
end)

IO.puts("\n🎉 Development dataset creation complete!\n")

IO.puts("📊 Created:")
IO.puts("  👥 Users: #{length(created_users)} (#{Enum.count(created_users, & &1.role == "admin")} admins, #{Enum.count(created_users, & &1.role == "user")} users)")
IO.puts("  🎥 Videos: #{length(created_videos)} (#{Enum.count(created_videos, & &1.in_pool)} in weekly pool)")
IO.puts("  📅 Weekly Assignments: #{length(weekly_assignments)} for #{current_year}")
IO.puts("  📚 Topics: #{length(created_topics)} (#{Enum.count(created_topics, & &1.status == "published")} published)")
IO.puts("  💡 Topic Proposals: #{length(sample_topic_proposals)}")
IO.puts("  🎪 Events: #{length(created_events)} (#{Enum.count(created_events, & &1.status == "public")} public)")
IO.puts("  📝 Event Proposals: #{length(sample_event_proposals)}")
IO.puts("  ✅ Event Tasks: #{length(all_tasks)}")
IO.puts("  🚌 Transportation: #{length(sample_transportation)} options")
IO.puts("  🚗 Carpools: #{length(sample_carpools)} offers")
IO.puts("  🎫 Access Codes: #{length(sample_access_codes)}")
IO.puts("  📁 Resources: #{length(created_resources)}")
IO.puts("  👁️  Watch History: Created for #{length(watched_videos_data)} users")

IO.puts("\n🔐 Test Login Credentials:")
IO.puts("  Admin: admin@test.com / admin123admin")
IO.puts("  Manager: manager@test.com / manager123456")
IO.puts("  User: user@test.com / user123456789")
IO.puts("  Newbie: newbie@test.com / newbie123456")
IO.puts("  Advanced: advanced@test.com / advanced123456")
IO.puts("  Organizer: organizer@test.com / organizer123456")

IO.puts("\n🎯 Test Scenarios Available:")
IO.puts("  • User progression tracking (different users at different stages)")
IO.puts("  • Event management (drafts, public events, proposals)")
IO.puts("  • Content management (videos, topics, resources)")
IO.puts("  • Access control (codes for events)")
IO.puts("  • Community features (carpools, transportation)")
IO.puts("  • Admin workflows (task management, approvals)")

IO.puts("\n⚠️  Note: This is DEVELOPMENT DATA ONLY - do not use in production!")
