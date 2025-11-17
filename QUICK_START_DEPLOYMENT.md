# Quick Start: Deploy to Render.com

## 1. Generate Secret Key (Run Locally)

```bash
./generate_secret.sh
```

Copy the output - you'll need it for Render.

## 2. Push to Git

```bash
git add .
git commit -m "Add production deployment configuration"
git push origin main
```

## 3. Deploy on Render.com

1. Go to https://dashboard.render.com
2. Click **"New +"** → **"Blueprint"**
3. Connect your Git repository
4. Render detects `render.yaml` automatically
5. Click **"Apply"**

## 4. Set Environment Variables

In your web service on Render, go to **Environment** tab and set:

- `PHX_HOST` = `yourdomain.com` (your Namecheap domain)
- `SECRET_KEY_BASE` = (paste the secret from step 1)

(Other variables are auto-configured by render.yaml)

## 5. Configure Your Domain

### On Render:

1. Go to your web service → **Settings**
2. Scroll to **"Custom Domain"**
3. Click **"Add Custom Domain"**
4. Enter: `yourdomain.com`
5. **Copy the DNS records shown**

### On Namecheap:

1. Log in to Namecheap
2. Go to **Domain List** → **Manage** (your domain)
3. Click **"Advanced DNS"** tab
4. Add these records:

**A Record:**

- Type: A Record
- Host: @
- Value: [IP from Render]
- TTL: Automatic

**CNAME Record:**

- Type: CNAME Record
- Host: www
- Value: [CNAME from Render]
- TTL: Automatic

## 6. Wait & Verify

- DNS propagation: 1-48 hours (usually < 2 hours)
- SSL certificate: Auto-provisioned by Render
- Check your app at: `https://yourdomain.com`

## That's It! 🎉

Your Phoenix app is now live on your custom domain with SSL.

---

**Need help?** See `DEPLOYMENT.md` for detailed instructions and troubleshooting.
