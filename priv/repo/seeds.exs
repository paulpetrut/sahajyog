# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Sahajyog.Repo.insert!(%Sahajyog.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

import Ecto.Query

alias Sahajyog.Repo
alias Sahajyog.Accounts.User
alias Sahajyog.Content.Video

# Create default admin user
admin_attrs = %{
  email: "paulpetrut@yahoo.com",
  password: "admin123admin",
  role: "admin"
}

case Repo.get_by(User, email: admin_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(admin_attrs, validate_unique: false)
    |> User.password_changeset(admin_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "admin")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created admin user: #{admin_attrs.email}")

  _user ->
    IO.puts("✓ Admin user already exists: #{admin_attrs.email}")
end

# Create test user (formerly "manager" - now simplified to "user" role)
test_user1_attrs = %{
  email: "manager@test.com",
  password: "manager123456",
  role: "user"
}

case Repo.get_by(User, email: test_user1_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(test_user1_attrs, validate_unique: false)
    |> User.password_changeset(test_user1_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "user")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created test user: #{test_user1_attrs.email}")

  _user ->
    IO.puts("✓ Test user already exists: #{test_user1_attrs.email}")
end

# Create test user (formerly "regular" - now simplified to "user" role)
user_attrs = %{
  email: "user@test.com",
  password: "user123456789",
  role: "user"
}

case Repo.get_by(User, email: user_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(user_attrs, validate_unique: false)
    |> User.password_changeset(user_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "user")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created test user: #{user_attrs.email}")

  _user ->
    IO.puts("✓ Test user already exists: #{user_attrs.email}")
end

# Create test admin user
test_admin_attrs = %{
  email: "admin@test.com",
  password: "admin123admin",
  role: "admin"
}

case Repo.get_by(User, email: test_admin_attrs.email) do
  nil ->
    %User{}
    |> User.email_changeset(test_admin_attrs, validate_unique: false)
    |> User.password_changeset(test_admin_attrs, hash_password: true)
    |> Ecto.Changeset.put_change(:role, "admin")
    |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
    |> Repo.insert!()

    IO.puts("✓ Created test admin user: #{test_admin_attrs.email}")

  _user ->
    IO.puts("✓ Test admin user already exists: #{test_admin_attrs.email}")
end

# Note: Sample videos are now imported via production_seeds.exs
# This seeds file only creates default users for development/testing

IO.puts("✓ Basic seeds completed. Run production seeds for video data.")

# Create sample topics
alias Sahajyog.Topics.{Topic, TopicProposal}

admin = Repo.get_by!(User, email: "admin@test.com")

sample_topics = [
  %{
    title: "Understanding the Chakras",
    content: """
    The chakras are energy centers within the subtle body that play a crucial role in our spiritual development. In Sahaja Yoga, we work with seven main chakras, each governing different aspects of our being.

    The Root Chakra (Mooladhara) is the foundation of our spiritual system, representing innocence and wisdom. It is located at the base of the spine and is associated with the color red.

    The Sacral Chakra (Swadisthan) governs creativity and pure knowledge. It is located in the abdomen and is associated with the color yellow.

    The Navel Chakra (Nabhi) represents satisfaction and peace. It is located at the navel and is associated with the color green.

    The Heart Chakra (Anahata) is the center of love and compassion. It is located at the heart and is associated with the color red.

    The Throat Chakra (Vishuddhi) governs communication and collectivity. It is located at the throat and is associated with the color blue.

    The Third Eye Chakra (Agnya) represents forgiveness and humility. It is located at the forehead and is associated with the color white.

    The Crown Chakra (Sahasrara) is the seat of integration and self-realization. It is located at the top of the head and is associated with all colors.
    """,
    status: "published",
    language: "en",
    user_id: admin.id
  },
  %{
    title: "The Practice of Meditation",
    content: """
    Meditation in Sahaja Yoga is a state of thoughtless awareness where we experience the present moment without mental chatter. This practice helps us connect with our inner self and achieve balance.

    To begin meditation, find a quiet space where you won't be disturbed. Sit comfortably with your feet flat on the ground and your hands open on your lap, palms facing upward.

    Close your eyes and bring your attention to the top of your head. Feel the cool breeze of the Kundalini energy flowing through your crown chakra.

    If thoughts arise, simply observe them without judgment and let them pass. The goal is not to suppress thoughts but to transcend them naturally.

    Regular practice, even for just 10-15 minutes daily, can bring profound changes in your life - reduced stress, improved focus, and a deeper sense of peace and joy.
    """,
    status: "published",
    language: "en",
    user_id: admin.id
  },
  %{
    title: "Kundalini Awakening",
    content: """
    The Kundalini is the dormant spiritual energy that resides at the base of the spine. In Sahaja Yoga, this energy is awakened spontaneously through Self-Realization.

    Unlike other practices that may take years of effort, Sahaja Yoga offers a simple and natural way to awaken the Kundalini. This awakening happens through the grace of the Divine and cannot be forced.

    When the Kundalini rises, it passes through each chakra, cleansing and nourishing them. You may feel a cool breeze on your palms or at the top of your head - this is a sign of the Kundalini awakening.

    After awakening, the Kundalini continues to work within us, helping us grow spiritually and overcome our limitations. Regular meditation helps strengthen this connection.
    """,
    status: "published",
    language: "en",
    user_id: admin.id
  }
]

Enum.each(sample_topics, fn topic_attrs ->
  case Repo.get_by(Topic,
         slug: Sahajyog.Topics.Topic.changeset(%Topic{}, topic_attrs).changes.slug
       ) do
    nil ->
      topic_attrs
      |> Map.put(:published_at, DateTime.utc_now(:second))
      |> then(&Topic.changeset(%Topic{}, &1))
      |> Repo.insert!()

      IO.puts("✓ Created topic: #{topic_attrs.title}")

    _topic ->
      IO.puts("✓ Topic already exists: #{topic_attrs.title}")
  end
end)

# Create sample topic proposals
regular_user = Repo.get_by!(User, email: "user@test.com")

sample_proposals = [
  %{
    title: "The Role of Music in Meditation",
    description:
      "Exploring how classical music and bhajans enhance the meditative experience and help in spiritual growth.",
    status: "pending",
    proposed_by_id: regular_user.id
  },
  %{
    title: "Balancing Work and Spiritual Life",
    description:
      "Practical tips on maintaining spiritual practice while managing professional responsibilities and family life.",
    status: "pending",
    proposed_by_id: regular_user.id
  }
]

Enum.each(sample_proposals, fn proposal_attrs ->
  case Repo.get_by(TopicProposal, title: proposal_attrs.title) do
    nil ->
      %TopicProposal{}
      |> TopicProposal.changeset(proposal_attrs)
      |> Repo.insert!()

      IO.puts("✓ Created topic proposal: #{proposal_attrs.title}")

    _proposal ->
      IO.puts("✓ Topic proposal already exists: #{proposal_attrs.title}")
  end
end)

IO.puts("✓ Topic seeds completed.")
