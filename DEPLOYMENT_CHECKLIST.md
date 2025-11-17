# Production Deployment Checklist

## Pre-Deployment

- [ ] Generate SECRET_KEY_BASE: `mix phx.gen.secret`
- [ ] Push code to Git repository
- [ ] Review and test locally with `MIX_ENV=prod mix release`

## Render.com Setup

- [ ] Create Render.com account
- [ ] Connect Git repository to Render
- [ ] Deploy using Blueprint (render.yaml) or manual setup
- [ ] Create PostgreSQL database
- [ ] Create web service

## Environment Variables (on Render)

- [ ] `DATABASE_URL` (auto-populated from database)
- [ ] `SECRET_KEY_BASE` (from `mix phx.gen.secret`)
- [ ] `PHX_HOST` (your domain, e.g., `yourdomain.com`)
- [ ] `PHX_SERVER` = `true`
- [ ] `POOL_SIZE` = `10`

## Domain Configuration

### On Render:

- [ ] Add custom domain in service settings
- [ ] Note the DNS records provided by Render

### On Namecheap:

- [ ] Log in to Namecheap
- [ ] Go to Domain List → Manage → Advanced DNS
- [ ] Add A Record: Host=`@`, Value=[Render IP]
- [ ] Add CNAME Record: Host=`www`, Value=[Render CNAME]
- [ ] Wait for DNS propagation (up to 48 hours)

## Post-Deployment

- [ ] Verify app loads at Render URL
- [ ] Verify app loads at custom domain (after DNS propagation)
- [ ] Test user registration
- [ ] Test user login
- [ ] Check SSL certificate is active (https://)
- [ ] Review application logs
- [ ] Set up monitoring/alerts

## Optional but Recommended

- [ ] Enable automatic database backups on Render
- [ ] Set up staging environment
- [ ] Configure email service (Swoosh adapter)
- [ ] Add health check endpoint
- [ ] Set up error tracking (e.g., Sentry)
- [ ] Configure CDN for static assets (optional)

## Quick Commands

Generate secret key:

```bash
mix phx.gen.secret
```

Test production build locally:

```bash
MIX_ENV=prod mix release
```

Deploy updates:

```bash
git add .
git commit -m "Update message"
git push origin main
```
