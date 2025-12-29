#!/usr/bin/env elixir

# Script to seed 100 test store items with various options
# Run with: mix run seed_store_items.exs

import Ecto.Query

alias Sahajyog.Repo
alias Sahajyog.Accounts.User
alias Sahajyog.Store.StoreItem

# Get or create test users
users =
  case Repo.all(User) do
    [] ->
      IO.puts("No users found. Please create at least one user first.")
      System.halt(1)

    users ->
      users
  end

IO.puts("Found #{length(users)} users. Creating 100 test store items...")

# Item categories with sample names
categories = [
  # Books & Media
  %{
    names: [
      "Meditation Guide Book",
      "Sahaja Yoga Handbook",
      "Spiritual Journey Diary",
      "Kundalini Awakening Book",
      "Chakra Healing Guide",
      "Ancient Wisdom Collection"
    ],
    descriptions: [
      "Comprehensive guide to meditation practices and techniques.",
      "Essential handbook for understanding Sahaja Yoga principles.",
      "Beautiful journal for documenting your spiritual journey.",
      "In-depth exploration of kundalini energy and awakening."
    ]
  },
  # Meditation Accessories
  %{
    names: [
      "Meditation Cushion",
      "Yoga Mat Premium",
      "Incense Holder Set",
      "Singing Bowl",
      "Prayer Beads Mala",
      "Meditation Timer"
    ],
    descriptions: [
      "Comfortable cushion for extended meditation sessions.",
      "High-quality, eco-friendly yoga mat with excellent grip.",
      "Handcrafted incense holder with beautiful design.",
      "Traditional singing bowl for meditation and healing."
    ]
  },
  # Clothing & Accessories
  %{
    names: [
      "Cotton Meditation Shawl",
      "Comfortable Yoga Pants",
      "Organic Cotton T-Shirt",
      "Meditation Scarf",
      "Traditional Kurta",
      "Handwoven Blanket"
    ],
    descriptions: [
      "Soft, breathable shawl perfect for meditation.",
      "Comfortable pants designed for yoga and meditation.",
      "Eco-friendly cotton shirt with spiritual motifs.",
      "Lightweight scarf for meditation practice."
    ]
  },
  # Art & Decor
  %{
    names: [
      "Chakra Wall Art",
      "Mandala Tapestry",
      "Buddha Statue",
      "Crystal Collection Set",
      "Himalayan Salt Lamp",
      "Zen Garden Kit"
    ],
    descriptions: [
      "Beautiful chakra artwork for meditation space.",
      "Hand-painted mandala tapestry for wall decoration.",
      "Peaceful Buddha statue for your altar.",
      "Collection of healing crystals with guide."
    ]
  },
  # Wellness Products
  %{
    names: [
      "Essential Oil Set",
      "Herbal Tea Collection",
      "Natural Incense Sticks",
      "Aromatherapy Diffuser",
      "Organic Soap Set",
      "Healing Crystal Bracelet"
    ],
    descriptions: [
      "Premium essential oils for aromatherapy and meditation.",
      "Curated selection of calming herbal teas.",
      "Natural incense made from pure ingredients.",
      "Ultrasonic diffuser for essential oils."
    ]
  },
  # Handcrafted Items
  %{
    names: [
      "Handmade Pottery Bowl",
      "Woven Basket Set",
      "Carved Wooden Box",
      "Embroidered Cushion Cover",
      "Hand-painted Coasters",
      "Macrame Wall Hanging"
    ],
    descriptions: [
      "Beautiful handcrafted pottery for your home.",
      "Set of woven baskets for storage and decoration.",
      "Intricately carved wooden box for treasures.",
      "Handmade cushion cover with traditional embroidery."
    ]
  }
]

# Pricing options
pricing_types = ["fixed_price", "accepts_donation"]
currencies = ["EUR", "USD", "GBP", "INR"]
# More approved items
statuses = ["approved", "approved", "approved", "pending"]

# Delivery method combinations
delivery_combinations = [
  ["shipping"],
  ["express_delivery"],
  ["local_pickup"],
  ["in_person"],
  ["shipping", "local_pickup"],
  ["express_delivery", "local_pickup"],
  ["shipping", "express_delivery"],
  ["in_person", "local_pickup"],
  ["shipping", "express_delivery", "local_pickup"],
  ["shipping", "local_pickup", "in_person"]
]

# Shipping regions
shipping_regions_options = [
  "Europe",
  "Worldwide",
  "EU only",
  "North America and Europe",
  "Asia and Europe",
  "Local area only"
]

# Meeting locations
meeting_locations = [
  "Community Center, Main Street",
  "Yoga Studio Downtown",
  "Public Library Meeting Room",
  "Park Entrance",
  "Meditation Center",
  "Coffee Shop on 5th Avenue"
]

# Generate 100 items
Enum.reduce(1..100, %{created: 0, errors: 0}, fn i, acc ->
  # Pick random category
  category = Enum.random(categories)
  name = "#{Enum.random(category.names)} ##{i}"
  description = Enum.random(category.descriptions)

  # Random user
  user = Enum.random(users)

  # Random pricing
  pricing_type = Enum.random(pricing_types)
  currency = Enum.random(currencies)

  price =
    if pricing_type == "fixed_price" do
      Decimal.new(Enum.random(5..500))
    else
      nil
    end

  production_cost =
    if pricing_type == "fixed_price" and :rand.uniform() > 0.5 do
      Decimal.div(price, Decimal.new(2))
    else
      nil
    end

  # Random delivery methods
  delivery_methods = Enum.random(delivery_combinations)

  # Shipping details (if shipping is included)
  {shipping_cost, shipping_regions} =
    if "shipping" in delivery_methods or "express_delivery" in delivery_methods do
      {Decimal.new(Enum.random(5..50)), Enum.random(shipping_regions_options)}
    else
      {nil, nil}
    end

  # Meeting location (if in_person or local_pickup)
  meeting_location =
    if "in_person" in delivery_methods or "local_pickup" in delivery_methods do
      Enum.random(meeting_locations)
    else
      nil
    end

  # Random quantity
  quantity = Enum.random(1..20)

  # Random status (mostly approved for testing)
  status = Enum.random(statuses)

  # Phone visibility
  phone_visible = Enum.random([true, false])

  attrs = %{
    name: name,
    description: description,
    quantity: quantity,
    production_cost: production_cost,
    price: price,
    pricing_type: pricing_type,
    currency: currency,
    status: status,
    delivery_methods: delivery_methods,
    shipping_cost: shipping_cost,
    shipping_regions: shipping_regions,
    meeting_location: meeting_location,
    phone_visible: phone_visible,
    user_id: user.id
  }

  case Repo.insert(StoreItem.changeset(%StoreItem{}, attrs)) do
    {:ok, _item} ->
      if rem(acc.created + 1, 10) == 0 do
        IO.write(".")
      end

      %{acc | created: acc.created + 1}

    {:error, changeset} ->
      IO.puts("\nError creating item #{i}: #{inspect(changeset.errors)}")
      %{acc | errors: acc.errors + 1}
  end
end)
|> then(fn result ->
  IO.puts("\n\n✅ Successfully created #{result.created} store items!")

  if result.errors > 0 do
    IO.puts("⚠️  #{result.errors} items failed to create.")
  end

  result
end)

# Print summary
approved_count = Repo.aggregate(from(i in StoreItem, where: i.status == "approved"), :count)
pending_count = Repo.aggregate(from(i in StoreItem, where: i.status == "pending"), :count)

IO.puts("\nSummary:")
IO.puts("  - Approved items: #{approved_count}")
IO.puts("  - Pending items: #{pending_count}")
IO.puts("  - Total items: #{Repo.aggregate(StoreItem, :count)}")
