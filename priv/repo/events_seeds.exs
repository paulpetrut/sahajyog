# Events seed data for testing
# Run with: mix run priv/repo/events_seeds.exs

alias Sahajyog.Repo
alias Sahajyog.Accounts.User
alias Sahajyog.Events.{Event, EventProposal, EventTeamMember, EventTask, EventTransportation, EventCarpool}

IO.puts("\n🎉 Seeding Events data...\n")

# Get existing users
admin = Repo.get_by!(User, email: "admin@test.com")
regular_user = Repo.get_by(User, email: "user@test.com") || admin

# Sample Events
sample_events = [
  %{
    title: "Summer Meditation Retreat 2025",
    slug: "summer-meditation-retreat-2025",
    description: """
    <p>Join us for a transformative weekend of meditation and spiritual growth in the beautiful Italian countryside.</p>
    <p>This retreat includes:</p>
    <ul>
      <li>Daily group meditations</li>
      <li>Chakra balancing sessions</li>
      <li>Nature walks</li>
      <li>Vegetarian meals</li>
    </ul>
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
    slug: "winter-solstice-celebration",
    description: """
    <p>Celebrate the winter solstice with meditation, music, and community.</p>
    <p>A special evening of collective meditation and traditional bhajans.</p>
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
    user_id: admin.id,
    published_at: DateTime.utc_now(:second)
  },
  %{
    title: "Spring Awakening Workshop",
    slug: "spring-awakening-workshop",
    description: "<p>A one-day workshop focused on chakra awakening and inner balance.</p>",
    status: "draft",
    event_date: ~D[2025-03-21],
    event_time: ~T[10:00:00],
    end_time: ~T[17:00:00],
    estimated_participants: 25,
    city: "Vienna",
    country: "Austria",
    address: "Friedensstraße 7, 1010 Wien",
    venue_name: "Yoga Zentrum Wien",
    user_id: regular_user.id
  },
  %{
    title: "Weekend Meditation Camp",
    slug: "weekend-meditation-camp",
    description: "<p>Two days of intensive meditation practice in nature.</p>",
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
  }
]

created_events = Enum.map(sample_events, fn event_attrs ->
  case Repo.get_by(Event, slug: event_attrs.slug) do
    nil ->
      {:ok, event} = %Event{}
        |> Event.changeset(event_attrs)
        |> Repo.insert()
      IO.puts("✓ Created event: #{event.title}")
      event
    existing ->
      IO.puts("⏭️  Event already exists: #{existing.title}")
      existing
  end
end)

[summer_retreat | _] = created_events

# Sample Event Proposals
sample_proposals = [
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
    status: "pending",
    proposed_by_id: regular_user.id
  }
]

Enum.each(sample_proposals, fn proposal_attrs ->
  case Repo.get_by(EventProposal, title: proposal_attrs.title) do
    nil ->
      {:ok, _proposal} = %EventProposal{}
        |> EventProposal.changeset(proposal_attrs)
        |> Repo.insert()
      IO.puts("✓ Created proposal: #{proposal_attrs.title}")
    _existing ->
      IO.puts("⏭️  Proposal already exists: #{proposal_attrs.title}")
  end
end)

# Sample Tasks for Summer Retreat
sample_tasks = [
  %{
    title: "Book venue",
    description: "Confirm reservation and pay deposit",
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
    description: "Contact vegetarian caterer for 50 people",
    status: "in_progress",
    due_date: ~D[2025-06-15],
    estimated_expense: Decimal.new("2000.00"),
    event_id: summer_retreat.id,
    assigned_user_id: admin.id,
    position: 2
  },
  %{
    title: "Prepare materials",
    description: "Print schedules, prepare meditation materials",
    status: "pending",
    due_date: ~D[2025-07-01],
    estimated_expense: Decimal.new("500.00"),
    event_id: summer_retreat.id,
    position: 3
  },
  %{
    title: "Set up sound system",
    description: "Test and configure audio equipment",
    status: "pending",
    due_date: ~D[2025-07-14],
    event_id: summer_retreat.id,
    position: 4
  }
]

Enum.each(sample_tasks, fn task_attrs ->
  case Repo.get_by(EventTask, title: task_attrs.title, event_id: task_attrs.event_id) do
    nil ->
      {:ok, _task} = %EventTask{}
        |> EventTask.changeset(task_attrs)
        |> Repo.insert()
      IO.puts("✓ Created task: #{task_attrs.title}")
    _existing ->
      IO.puts("⏭️  Task already exists: #{task_attrs.title}")
  end
end)

# Sample Transportation
sample_transport = [
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
  }
]

Enum.each(sample_transport, fn trans_attrs ->
  case Repo.get_by(EventTransportation, title: trans_attrs.title, event_id: trans_attrs.event_id) do
    nil ->
      {:ok, _trans} = %EventTransportation{}
        |> EventTransportation.changeset(trans_attrs)
        |> Repo.insert()
      IO.puts("✓ Created transport: #{trans_attrs.title}")
    _existing ->
      IO.puts("⏭️  Transport already exists: #{trans_attrs.title}")
  end
end)

# Sample Carpools
sample_carpools = [
  %{
    departure_location: "Milan Central Station",
    departure_time: ~T[06:00:00],
    available_seats: 3,
    contact_phone: "+39 123 456 7890",
    notes: "Will stop for breakfast on the way",
    status: "open",
    event_id: summer_retreat.id,
    driver_user_id: admin.id
  }
]

Enum.each(sample_carpools, fn carpool_attrs ->
  import Ecto.Query
  existing = Repo.one(from c in EventCarpool,
    where: c.event_id == ^carpool_attrs.event_id and c.driver_user_id == ^carpool_attrs.driver_user_id,
    limit: 1)

  if is_nil(existing) do
    {:ok, _carpool} = %EventCarpool{}
      |> EventCarpool.changeset(carpool_attrs)
      |> Repo.insert()
    IO.puts("✓ Created carpool from: #{carpool_attrs.departure_location}")
  else
    IO.puts("⏭️  Carpool already exists from: #{carpool_attrs.departure_location}")
  end
end)

IO.puts("\n✅ Events seeding complete!")
IO.puts("\nCreated:")
IO.puts("  - 4 sample events (2 public, 1 draft, 1 public)")
IO.puts("  - 2 pending proposals")
IO.puts("  - 4 tasks for Summer Retreat")
IO.puts("  - 2 transportation options")
IO.puts("  - 1 carpool offer")
IO.puts("\nVisit /events to see the events listing!")
