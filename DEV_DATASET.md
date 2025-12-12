# Development Dataset Documentation

This document describes the comprehensive test dataset created for development and testing of the Sahaja Yoga application.

## ⚠️ Important Notice

**This dataset is for DEVELOPMENT ENVIRONMENT ONLY**

- Never run in production
- Contains test data with predictable passwords
- Includes mock resources and placeholder content

## Quick Setup

```bash
# Run the setup script
./scripts/setup_dev_data.sh

# Or manually
export MIX_ENV=dev
mix ecto.setup
mix run priv/repo/dev_seeds.exs
```

## Test Accounts

| Role  | Email              | Password        | Purpose                       |
| ----- | ------------------ | --------------- | ----------------------------- |
| Admin | admin@test.com     | admin123admin   | Full admin access             |
| User  | manager@test.com   | manager123456   | Content management            |
| User  | user@test.com      | user123456789   | Regular user                  |
| User  | newbie@test.com    | newbie123456    | New user (minimal progress)   |
| User  | advanced@test.com  | advanced123456  | Advanced user (high progress) |
| User  | organizer@test.com | organizer123456 | Event organizer               |

## Dataset Contents

### 👥 Users (6 total)

- 1 Admin with full permissions
- 5 Users with different experience levels and content

### 🎥 Videos (12 total)

- **Welcome** (2 videos): Introduction and Self-Realization
- **Getting Started** (3 videos): First meditation, chakras, daily practice
- **Advanced Topics** (3 videos): Subtle system, consciousness, balancing
- **Excerpts** (4 videos): Peace, joy, wisdom, love
- 10 videos in weekly pool, 2 additional videos

### 📅 Weekly Video Assignments

- Current year assignments for pool videos
- Week 1-10 mapped to pool videos

### 📚 Topics (5 total)

- 4 Published topics with rich HTML content
- 1 Draft topic
- Topics cover: chakras, meditation, kundalini, work-life balance, music

### 💡 Topic Proposals (3 total)

- Pending: Children's meditation, negative emotions, meditation science
- 1 Approved proposal

### 🎪 Events (5 total)

- **Summer Retreat 2025** (Public): 3-day retreat in Italy
- **Winter Solstice** (Public): Evening celebration in Romania
- **Spring Workshop** (Draft): 1-day workshop in Austria
- **Weekend Camp** (Public): 2-day camp in Germany
- **Monthly Circle** (Public): Regular meeting in Prague

### 📝 Event Management

- **Event Proposals** (3): Autumn weekend, New Year marathon, Youth workshop
- **Tasks** (7): Venue booking, catering, materials, sound setup
- **Transportation** (3): Public transport and shuttle options
- **Carpools** (3): Ride sharing from different cities

### 🎫 Access Codes (4 total)

- Event-specific codes: SUMMER2025, WINTER2025, SPRING2025
- General code: GENERAL2025

### 📁 Resources (5 total)

- **Level 1**: Beginner's guide (PDF), Chakra music (MP3)
- **Level 2**: Retreat photos (ZIP), Bhajan collection (PDF)
- **Level 3**: Advanced techniques (PDF)
- Mock file data with realistic sizes and types

### 👁️ Progress Tracking

- **Newbie**: 2 videos watched (just started)
- **Regular User**: 5 videos watched (moderate progress)
- **Advanced User**: 8 videos watched (experienced)
- **Manager**: 4 videos watched (some experience)

## Test Scenarios

### User Journey Testing

1. **New User Experience**: Login as newbie@test.com

   - Limited video progress
   - Can propose topics and events
   - Basic access to public content

2. **Regular User Experience**: Login as user@test.com

   - Moderate progress through video series
   - Can access most content
   - Can participate in events

3. **Advanced User Experience**: Login as advanced@test.com
   - High progress through content
   - Can access advanced resources
   - Active in community features

### Admin Testing

1. **Content Management**: Login as admin@test.com

   - Manage videos and weekly assignments
   - Approve/reject topic proposals
   - Manage events and resources

2. **Event Management**: Login as organizer@test.com
   - Create and manage events
   - Handle tasks and logistics
   - Manage access codes

### Feature Testing

#### Video System

- Weekly video pool management
- Progress tracking across users
- Different video categories and providers

#### Event System

- Public vs draft events
- Event proposals and approval workflow
- Task management and assignment
- Transportation and carpool coordination
- Access code system

#### Content System

- Topic creation and publishing
- Proposal system with approval workflow
- Resource management with different levels
- Multi-language support (en)

#### Community Features

- User roles and permissions
- Progress tracking and achievements
- Collaborative event planning
- Resource sharing

## Database Reset

To reset and recreate the development dataset:

```bash
# Drop and recreate database
mix ecto.drop
mix ecto.create
mix ecto.migrate

# Recreate dataset
mix run priv/repo/dev_seeds.exs
```

## Customization

To modify the dataset:

1. Edit `priv/repo/dev_seeds.exs`
2. Add/modify sample data as needed
3. Run `mix run priv/repo/dev_seeds.exs` to apply changes

## Production Safety

The seed file includes multiple safety checks:

- Environment check prevents running in production
- Clear warnings in output
- Separate from production seeds

## Troubleshooting

### Common Issues

1. **Database connection errors**

   ```bash
   mix ecto.setup
   ```

2. **Existing data conflicts**

   ```bash
   mix ecto.drop && mix ecto.setup
   mix run priv/repo/dev_seeds.exs
   ```

3. **Permission errors**
   ```bash
   chmod +x scripts/setup_dev_data.sh
   ```

### Verification

After running the seeds, verify the data:

```bash
# Check user count
mix run -e "IO.inspect(Sahajyog.Repo.aggregate(Sahajyog.Accounts.User, :count))"

# Check video count
mix run -e "IO.inspect(Sahajyog.Repo.aggregate(Sahajyog.Content.Video, :count))"

# Check event count
mix run -e "IO.inspect(Sahajyog.Repo.aggregate(Sahajyog.Events.Event, :count))"
```

## Contributing

When adding new features that require test data:

1. Add sample data to `priv/repo/dev_seeds.exs`
2. Update this documentation
3. Test with the new dataset
4. Ensure production safety checks remain in place
