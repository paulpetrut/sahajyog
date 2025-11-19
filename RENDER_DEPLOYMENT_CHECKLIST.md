# Render.com Deployment Checklist

Use this checklist when deploying to Render.com.

## Pre-Deployment

- [ ] Code is committed and pushed to Git repository
- [ ] All tests pass locally (`mix test`)
- [ ] R2 API token created in Cloudflare
- [ ] R2 bucket exists with Level/Type structure
- [ ] Generated `SECRET_KEY_BASE` with `mix phx.gen.secret`

## Render.com Setup

### 1. Create Services

- [ ] PostgreSQL database created
- [ ] Web service created and linked to database
- [ ] Build and deploy successful

### 2. Environment Variables

Go to your web service → Environment tab and add:

#### Required

- [ ] `DATABASE_URL` (auto-populated from linked database)
- [ ] `SECRET_KEY_BASE` (from `mix phx.gen.secret`)
- [ ] `PHX_HOST` (your domain, e.g., `sahajaonline.xyz`)
- [ ] `PHX_SERVER` = `true`
- [ ] `POOL_SIZE` = `10`

#### R2 Configuration

- [ ] `R2_ACCOUNT_ID` (from Cloudflare dashboard)
- [ ] `R2_ACCESS_KEY_ID` (from R2 API token)
- [ ] `R2_SECRET_ACCESS_KEY` (from R2 API token)
- [ ] `R2_BUCKET_NAME` = `sahajaonline`

#### Optional

- [ ] `R2_PUBLIC_URL` (if using custom domain)
- [ ] `RESEND_API_KEY` (for emails)
- [ ] `ECTO_IPV6` = `true` (if needed)

### 3. Custom Domain

- [ ] Custom domain added in Render (Settings → Custom Domain)
- [ ] DNS records configured in Namecheap:
  - [ ] A record for root domain (@)
  - [ ] CNAME record for www subdomain
- [ ] SSL certificate provisioned (automatic after DNS propagation)

## Post-Deployment

### 4. Database Setup

Run these commands in Render Shell (Dashboard → Shell):

```bash
# Run migrations
/app/bin/sahajyog eval "Sahajyog.Release.migrate"

# Or if that doesn't work:
/app/bin/migrate
```

### 5. Sync R2 Resources

If you have existing files in R2, sync them:

```bash
# In Render Shell
/app/bin/sahajyog eval "Mix.Task.run(\"sync_r2_resources\")"
```

Or run locally and let it sync to production database:

```bash
# Locally with production DATABASE_URL
DATABASE_URL="your_production_db_url" mix sync_r2_resources
```

### 6. Create Admin User

In Render Shell:

```bash
/app/bin/sahajyog remote

# Then in IEx:
{:ok, user} = Sahajyog.Accounts.register_user(%{
  email: "your@email.com",
  password: "your_secure_password"
})

# Confirm and make admin
user
|> Ecto.Changeset.change(
  confirmed_at: DateTime.utc_now(),
  role: "admin",
  level: "Level1"
)
|> Sahajyog.Repo.update()
```

### 7. Verify Deployment

- [ ] Visit your domain (https://yourdomain.com)
- [ ] Log in with admin account
- [ ] Test uploading a resource at `/admin/resources`
- [ ] Test downloading a resource at `/resources`
- [ ] Verify level-based access control
- [ ] Check that emails work (if configured)

## Troubleshooting

### Build Fails

- Check build logs in Render dashboard
- Verify Dockerfile is correct
- Ensure all dependencies are in mix.exs

### Database Connection Issues

- Verify `DATABASE_URL` is set correctly
- Check `POOL_SIZE` setting
- Review database logs

### R2 Upload/Download Fails

- Verify all R2 environment variables are set
- Test R2 credentials locally first
- Check R2 API token permissions (should be "Object Read & Write")
- Verify bucket name is correct

### Can't Access Resources

- Check user's level field in database
- Verify resources exist for that level
- Check browser console for errors

### DNS Not Working

- Wait for DNS propagation (up to 48 hours, usually faster)
- Verify DNS records in Namecheap match Render's requirements
- Use `dig yourdomain.com` to check DNS resolution

## Monitoring

- [ ] Set up health checks in Render
- [ ] Monitor error logs in Render dashboard
- [ ] Set up alerts for downtime
- [ ] Monitor database usage
- [ ] Monitor R2 storage usage in Cloudflare

## Maintenance

### Update Application

```bash
git push origin main
# Render auto-deploys on push
```

### Run Migrations

```bash
# In Render Shell
/app/bin/sahajyog eval "Sahajyog.Release.migrate"
```

### Access Production Console

```bash
# In Render Shell
/app/bin/sahajyog remote
```

### Backup Database

Render provides automatic backups for paid plans. For manual backup:

```bash
# Use Render's backup feature or pg_dump
```

## Security Checklist

- [ ] All environment variables are set as secrets (not visible in logs)
- [ ] `SECRET_KEY_BASE` is unique and secure
- [ ] R2 API token has minimal required permissions
- [ ] SSL/HTTPS is enabled
- [ ] Database is not publicly accessible
- [ ] Admin accounts use strong passwords
- [ ] Regular security updates applied

## Cost Optimization

- [ ] Choose appropriate Render plan (Free/Starter/Standard)
- [ ] Monitor R2 storage usage (10GB free tier)
- [ ] Set up database connection pooling (`POOL_SIZE`)
- [ ] Consider CDN for static assets
- [ ] Monitor bandwidth usage

## Support

- Render Docs: https://render.com/docs
- Render Community: https://community.render.com
- Phoenix Deployment: https://hexdocs.pm/phoenix/deployment.html
- Cloudflare R2 Docs: https://developers.cloudflare.com/r2/
