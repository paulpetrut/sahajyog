# Demo Events seed data for development - 25 events
# Run with: mix run priv/repo/demo_events_seeds.exs

alias Sahajyog.Repo
alias Sahajyog.Accounts.User
alias Sahajyog.Events.Event

IO.puts("\n🎉 Seeding 25 Demo Events...\n")

# Get existing users
admin = Repo.get_by!(User, email: "admin@test.com")
regular_user = Repo.get_by(User, email: "user@test.com") || admin

# Sample data pools
cities_countries = [
  {"Rome", "Italy"},
  {"Bucharest", "Romania"},
  {"Vienna", "Austria"},
  {"Munich", "Germany"},
  {"Prague", "Czech Republic"},
  {"Paris", "France"},
  {"London", "United Kingdom"},
  {"Berlin", "Germany"},
  {"Madrid", "Spain"},
  {"Barcelona", "Spain"},
  {"Amsterdam", "Netherlands"},
  {"Zurich", "Switzerland"},
  {"Geneva", "Switzerland"},
  {"Milan", "Italy"},
  {"Florence", "Italy"},
  {"Venice", "Italy"},
  {"Lisbon", "Portugal"},
  {"Porto", "Portugal"},
  {"Dublin", "Ireland"},
  {"Edinburgh", "United Kingdom"},
  {"Athens", "Greece"},
  {"Stockholm", "Sweden"},
  {"Copenhagen", "Denmark"},
  {"Oslo", "Norway"},
  {"Helsinki", "Finland"}
]

event_types = [
  "Meditation Retreat",
  "Spiritual Workshop",
  "Yoga Session",
  "Meditation Camp",
  "Chakra Balancing",
  "Inner Peace Seminar",
  "Mindfulness Workshop",
  "Spiritual Celebration",
  "Meditation Marathon",
  "Yoga Retreat",
  "Spiritual Journey",
  "Meditation Weekend",
  "Consciousness Workshop",
  "Spiritual Gathering",
  "Meditation Intensive"
]

statuses = ["public", "draft", "public", "public", "draft"] # More public for visibility

# Generate 25 events
sample_events = Enum.map(1..25, fn i ->
  {city, country} = Enum.at(cities_countries, rem(i-1, length(cities_countries)))
  event_type = Enum.at(event_types, rem(i-1, length(event_types)))
  status = Enum.at(statuses, rem(i-1, length(statuses)))
  user = if rem(i, 3) == 0, do: regular_user, else: admin

  # Generate dates spread over 2025-2026
  base_date = Date.new!(2025, 1, 1)
  days_offset = (i - 1) * 15  # Spread every 15 days
  event_date = Date.add(base_date, days_offset)

  # Some events are past, some future
  event_date = if rem(i, 4) == 0, do: Date.add(Date.utc_today(), -30 + i), else: event_date

  %{
    title: "#{event_type} #{i}",
    slug: "#{String.downcase(String.replace(event_type, " ", "-"))}-#{i}",
    description: "<p>A wonderful #{String.downcase(event_type)} in #{city}, #{country}. Join us for spiritual growth and meditation.</p>",
    status: status,
    event_date: event_date,
    event_time: ~T[10:00:00],
    end_time: ~T[17:00:00],
    estimated_participants: 20 + rem(i, 50),  # 20-69 participants
    city: city,
    country: country,
    address: "#{city} Spiritual Center #{i}",
    venue_name: "#{city} Meditation Hall",
    user_id: user.id,
    published_at: if(status == "public", do: DateTime.utc_now(:second), else: nil)
  }
end)

# Insert events
{created_count, _} = Enum.reduce(sample_events, {0, nil}, fn event_attrs, {count, _} ->
  case Repo.get_by(Event, slug: event_attrs.slug) do
    nil ->
      {:ok, _event} = %Event{}
        |> Event.changeset(event_attrs)
        |> Repo.insert()
      IO.puts("✓ Created event: #{event_attrs.title}")
      {count + 1, nil}
    _existing ->
      IO.puts("⏭️  Event already exists: #{event_attrs.title}")
      {count, nil}
  end
end)

# Additional 20 events for user@test.com
IO.puts("\n🎉 Creating 20 additional events for user@test.com...\n")

user_events = Enum.map(26..45, fn i ->
  {city, country} = Enum.at(cities_countries, rem(i-1, length(cities_countries)))
  event_type = Enum.at(event_types, rem(i-1, length(event_types)))
  status = Enum.at(statuses, rem(i-1, length(statuses)))

  # Generate dates spread over 2025-2026, starting from where we left off
  base_date = Date.new!(2025, 1, 1)
  days_offset = (i - 1) * 12  # Spread every 12 days for more density
  event_date = Date.add(base_date, days_offset)

  %{
    title: "User #{event_type} #{i}",
    slug: "user-#{String.downcase(String.replace(event_type, " ", "-"))}-#{i}",
    description: "<p>A community-organized #{String.downcase(event_type)} in #{city}, #{country}. Open to all seekers.</p>",
    status: status,
    event_date: event_date,
    event_time: ~T[14:00:00],
    end_time: ~T[18:00:00],
    estimated_participants: 15 + rem(i, 30),  # Smaller events, 15-44 participants
    city: city,
    country: country,
    address: "#{city} Community Center #{i}",
    venue_name: "#{city} Community Space",
    user_id: regular_user.id,
    published_at: if(status == "public", do: DateTime.utc_now(:second), else: nil)
  }
end)

# Insert user events
{user_created_count, _} = Enum.reduce(user_events, {0, nil}, fn event_attrs, {count, _} ->
  case Repo.get_by(Event, slug: event_attrs.slug) do
    nil ->
      {:ok, _event} = %Event{}
        |> Event.changeset(event_attrs)
        |> Repo.insert()
      IO.puts("✓ Created user event: #{event_attrs.title}")
      {count + 1, nil}
    _existing ->
      IO.puts("⏭️  User event already exists: #{event_attrs.title}")
      {count, nil}
  end
end)

IO.puts("\n✅ Demo events seeding complete!")
IO.puts("Created #{created_count} admin events + #{user_created_count} user events")
IO.puts("Total events in database: #{Repo.aggregate(Event, :count, :id)}")
IO.puts("\nVisit /events to see the events listing!")
