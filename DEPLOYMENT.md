# Deployment Guide for Render.com

This guide will help you deploy your Sahajyog Phoenix application to Render.com with your Namecheap domain.

## Prerequisites

- A Render.com account (sign up at https://render.com)
- A Namecheap domain
- Your code pushed to a Git repository (GitHub, GitLab, or Bitbucket)

## Step 1: Push Your Code to Git

Make sure all the new deployment files are committed and pushed:

```bash
git add .
git commit -m "Add production deployment configuration"
git push origin main
```

## Step 2: Deploy to Render.com

### Option A: Using render.yaml (Recommended)

1. Go to https://dashboard.render.com
2. Click "New +" → "Blueprint"
3. Connect your Git repository
4. Render will automatically detect the `render.yaml` file
5. Review the services that will be created:
   - Web Service (sahajyog)
   - PostgreSQL Database (sahajyog-db)
6. Click "Apply" to create the services

### Option B: Manual Setup

1. **Create PostgreSQL Database:**

   - Go to https://dashboard.render.com
   - Click "New +" → "PostgreSQL"
   - Name: `sahajyog-db`
   - Database: `sahajyog`
   - Plan: Choose your plan (Starter is fine for testing)
   - Click "Create Database"

2. **Create Web Service:**
   - Click "New +" → "Web Service"
   - Connect your Git repository
   - Name: `sahajyog`
   - Runtime: Docker
   - Plan: Choose your plan (Starter is fine for testing)
   - Click "Create Web Service"

## Step 3: Configure Environment Variables

After creating the web service, go to the service's "Environment" tab and add:

### Required Variables:

- `DATABASE_URL` - Auto-populated if you linked the database
- `SECRET_KEY_BASE` - Generate with: `mix phx.gen.secret` (run locally)
- `PHX_HOST` - Your domain (e.g., `yourdomain.com`)
- `PHX_SERVER` - Set to `true`
- `POOL_SIZE` - Set to `10` (or adjust based on your database plan)

### Optional Variables:

- `ECTO_IPV6` - Set to `true` if you need IPv6 support

## Step 4: Configure Custom Domain on Render

1. In your Render web service dashboard, go to "Settings"
2. Scroll to "Custom Domain" section
3. Click "Add Custom Domain"
4. Enter your domain: `yourdomain.com`
5. Render will provide you with DNS records to configure

## Step 5: Configure DNS on Namecheap

1. Log in to your Namecheap account
2. Go to "Domain List" and click "Manage" on your domain
3. Go to "Advanced DNS" tab
4. Add the following records (use the values provided by Render):

### For Root Domain (yourdomain.com):

- **Type:** A Record
- **Host:** @
- **Value:** [IP address provided by Render]
- **TTL:** Automatic

### For www Subdomain (www.yourdomain.com):

- **Type:** CNAME Record
- **Host:** www
- **Value:** [CNAME provided by Render, e.g., yourapp.onrender.com]
- **TTL:** Automatic

**Note:** DNS propagation can take up to 48 hours, but usually completes within a few hours.

## Step 6: Enable SSL/HTTPS

Render automatically provisions SSL certificates for custom domains using Let's Encrypt. Once your DNS is configured and propagated:

1. Render will automatically detect the DNS changes
2. SSL certificate will be provisioned automatically
3. Your site will be accessible via HTTPS

## Step 7: Run Database Migrations

Migrations will run automatically on each deploy via the `buildCommand` in render.yaml.

If you need to run migrations manually:

1. Go to your web service in Render dashboard
2. Click "Shell" tab
3. Run: `/app/bin/migrate`

## Step 8: Verify Deployment

1. Visit your Render URL: `https://sahajyog.onrender.com`
2. Once DNS propagates, visit your custom domain: `https://yourdomain.com`
3. Check that the application loads correctly
4. Test user registration and login

## Troubleshooting

### Check Logs

- Go to your web service in Render dashboard
- Click "Logs" tab to see application logs

### Common Issues

**Database Connection Errors:**

- Verify `DATABASE_URL` is set correctly
- Check that SSL is enabled in `config/runtime.exs`

**Application Won't Start:**

- Verify `SECRET_KEY_BASE` is set
- Check that `PHX_SERVER=true` is set
- Review logs for specific errors

**Domain Not Working:**

- Verify DNS records are correct
- Wait for DNS propagation (can take up to 48 hours)
- Check Render's custom domain status

**Build Failures:**

- Check that all dependencies are in `mix.exs`
- Verify `assets/` directory has all necessary files
- Review build logs in Render dashboard

## Updating Your Application

To deploy updates:

```bash
git add .
git commit -m "Your update message"
git push origin main
```

Render will automatically detect the push and redeploy your application.

## Scaling

To scale your application:

1. Go to your web service settings
2. Upgrade your plan for more resources
3. Adjust `POOL_SIZE` environment variable based on your database plan
4. Consider adding multiple instances for high availability

## Monitoring

- Use Render's built-in metrics and logs
- Consider adding Phoenix LiveDashboard for production monitoring
- Set up health checks and alerts in Render

## Cost Optimization

- Start with Starter plans ($7/month for web service, $7/month for database)
- Monitor usage and scale as needed
- Use Render's free tier for staging environments

## Security Checklist

- ✅ SSL enabled (automatic with Render)
- ✅ Database SSL enabled (configured in runtime.exs)
- ✅ SECRET_KEY_BASE is unique and secure
- ✅ Environment variables are not committed to Git
- ✅ Database credentials are managed by Render
- ⚠️ Consider setting up a firewall/WAF for production
- ⚠️ Review and configure rate limiting if needed
- ⚠️ Set up regular database backups (available in Render)

## Additional Resources

- [Render Documentation](https://render.com/docs)
- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)
- [Render + Phoenix Guide](https://render.com/docs/deploy-phoenix)
