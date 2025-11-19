# Testing the Resources System

## Prerequisites

1. Set your R2 environment variables in `.env`:

   ```bash
   export R2_ACCOUNT_ID=your_account_id
   export R2_ACCESS_KEY_ID=your_access_key
   export R2_SECRET_ACCESS_KEY=your_secret_key
   export R2_BUCKET_NAME=sahajaonline
   ```

2. Load them:
   ```bash
   source .env
   ```

## Step 1: Sync Existing Files

```bash
# Preview what will be synced
mix sync_r2_resources --dry-run

# Sync files from R2 to database
mix sync_r2_resources
```

This will create database records for all files in your R2 bucket that match the Level/Type structure.

## Step 2: Create Test Users at Different Levels

```elixir
# Start console
iex -S mix

# Create Level1 user
{:ok, user1} = Sahajyog.Accounts.register_user(%{
  email: "level1@test.com",
  password: "testpassword123"
})
Ecto.Changeset.change(user1, level: "Level1", confirmed_at: DateTime.utc_now())
|> Sahajyog.Repo.update()

# Create Level2 user
{:ok, user2} = Sahajyog.Accounts.register_user(%{
  email: "level2@test.com",
  password: "testpassword123"
})
Ecto.Changeset.change(user2, level: "Level2", confirmed_at: DateTime.utc_now())
|> Sahajyog.Repo.update()

# Create Level3 user
{:ok, user3} = Sahajyog.Accounts.register_user(%{
  email: "level3@test.com",
  password: "testpassword123"
})
Ecto.Changeset.change(user3, level: "Level3", confirmed_at: DateTime.utc_now())
|> Sahajyog.Repo.update()
```

## Step 3: Test Level-Based Access

### Test in Console

```elixir
# Get users
user1 = Sahajyog.Repo.get_by(Sahajyog.Accounts.User, email: "level1@test.com")
user2 = Sahajyog.Repo.get_by(Sahajyog.Accounts.User, email: "level2@test.com")

# Check what each user can see
level1_resources = Sahajyog.Resources.list_resources_for_user(user1)
level2_resources = Sahajyog.Resources.list_resources_for_user(user2)

IO.puts("Level1 user sees #{length(level1_resources)} resources")
IO.puts("Level2 user sees #{length(level2_resources)} resources")

# They should see different resources!
```

### Test in Browser

1. Start server:

   ```bash
   mix phx.server
   ```

2. Log in as `level1@test.com` / `testpassword123`
3. Visit http://localhost:4000/resources
4. You should only see Level1 resources
5. Log out and log in as `level2@test.com`
6. Visit http://localhost:4000/resources
7. You should only see Level2 resources

## Step 4: Test Admin Upload

1. Log in as admin (paulpetrut@yahoo.com or admin@test.com)
2. Visit http://localhost:4000/admin/resources
3. Click "Upload New Resource"
4. Fill in:
   - Title: "Test Book"
   - Level: Level1
   - Type: Books
   - Upload a test file
5. Click Save
6. Verify it appears in the list
7. Log in as a Level1 user and verify they can see and download it

## Step 5: Test Access Control

Try to access a resource from a different level:

1. Log in as Level1 user
2. Note a resource ID from Level2 (check admin panel or database)
3. Try to access: http://localhost:4000/resources/{level2_resource_id}/download
4. You should be redirected with an error message

## Step 6: Test Filtering

1. Log in as any user
2. Visit http://localhost:4000/resources
3. Click filter buttons (Photos, Books, Music)
4. Verify only resources of that type are shown
5. Verify you still only see your level's resources

## Verification Queries

```elixir
# Count resources by level
import Ecto.Query
alias Sahajyog.Repo
alias Sahajyog.Resources.Resource

Repo.all(from r in Resource,
  group_by: r.level,
  select: {r.level, count(r.id)})

# Count resources by type
Repo.all(from r in Resource,
  group_by: r.resource_type,
  select: {r.resource_type, count(r.id)})

# Count resources by level and type
Repo.all(from r in Resource,
  group_by: [r.level, r.resource_type],
  select: {r.level, r.resource_type, count(r.id)})
  |> Enum.sort()
```

## Expected Results

✅ Users only see resources from their assigned level
✅ Filtering works within their level
✅ Download URLs are generated and work
✅ Access to other levels is blocked
✅ Admin can upload to any level
✅ Download counter increments

## Troubleshooting

### No resources showing up

```elixir
# Check if resources exist
Sahajyog.Repo.aggregate(Sahajyog.Resources.Resource, :count)

# Check user level
user = Sahajyog.Repo.get_by(Sahajyog.Accounts.User, email: "level1@test.com")
IO.inspect(user.level)

# Check resources for that level
Sahajyog.Resources.list_resources(%{level: user.level})
```

### Upload fails

- Check R2 credentials are set
- Verify bucket name is correct
- Check file size (max 500MB)
- Look at server logs for errors

### Download fails

- Check R2 credentials
- Verify the file exists in R2
- Check presigned URL generation

## Production Checklist

Before deploying:

- [ ] R2 environment variables set in production
- [ ] Database migrated
- [ ] Existing files synced with `mix sync_r2_resources`
- [ ] Test users created at each level
- [ ] Access control tested
- [ ] Download functionality tested
- [ ] Admin upload tested
- [ ] Error handling verified
