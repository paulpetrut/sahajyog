# Production Readiness Checklist

## ✅ Completed Items

### Code Quality

- [x] All tests passing (195 tests, 0 failures)
- [x] 0 Credo issues
- [x] All debugging console.log statements removed
- [x] Error handling in place for critical operations
- [x] Service Worker properly configured

### Security

- [x] No hardcoded secrets in codebase
- [x] All sensitive data in environment variables
- [x] `.env` file in `.gitignore`
- [x] CORS properly configured in `runtime.exs`
- [x] SSL/TLS configured for database connections

### Performance

- [x] Database connection pooling configured (POOL_SIZE=10)
- [x] Service Worker caching for offline support
- [x] Image optimization with R2 storage
- [x] Lazy loading for videos and images

## 🔧 Required: Environment Variables on Render.com

You **MUST** add these environment variables in your Render.com dashboard:

### 1. Google Places API (NEW - Required)

```
GOOGLE_PLACES_API_KEY=your_actual_api_key_here
```

**Where to add:** Render.com Dashboard → Your Service → Environment → Add Environment Variable

**How to get:**

1. Go to https://console.cloud.google.com/apis/credentials
2. Create or use existing API key
3. Enable "Places API (New)" - NOT the legacy Places API
4. Copy the API key

### 2. Cloudflare R2 (Already configured?)

```
R2_ACCOUNT_ID=your_account_id
R2_ACCESS_KEY_ID=your_access_key
R2_SECRET_ACCESS_KEY=your_secret_key
R2_BUCKET_NAME=sahajaonline
R2_PUBLIC_URL=your_public_url (optional)
```

### 3. Email Configuration (Optional but recommended)

**Option A: Resend (Recommended)**

```
RESEND_API_KEY=your_resend_api_key
```

**Option B: SMTP**

```
SMTP_HOST=smtp.example.com
SMTP_USERNAME=your_username
SMTP_PASSWORD=your_password
SMTP_PORT=587
SMTP_SSL=false
```

### 4. Already Configured in render.yaml

These are automatically set by Render:

- ✅ `DATABASE_URL` - from database connection
- ✅ `SECRET_KEY_BASE` - auto-generated
- ✅ `PHX_HOST` - needs to be set manually to your domain
- ✅ `POOL_SIZE` - set to 10
- ✅ `PHX_SERVER` - set to true

## 📋 Pre-Deployment Steps

### 1. Update render.yaml

Add the Google Places API key to your `render.yaml`:

```yaml
envVars:
  # ... existing vars ...
  - key: GOOGLE_PLACES_API_KEY
    sync: false
```

### 2. Set PHX_HOST

In Render.com dashboard, set `PHX_HOST` to your actual domain:

```
PHX_HOST=www.sahajaonline.xyz
```

### 3. Verify R2 Configuration

Ensure all R2 environment variables are set in Render.com dashboard.

### 4. Test Email Configuration (Optional)

If using email features, test with Resend or SMTP credentials.

## 🚀 Deployment Process

### Option 1: Automatic Deployment (Recommended)

1. Push to your main branch
2. Render will automatically build and deploy
3. Monitor the deployment logs in Render dashboard

### Option 2: Manual Deployment

1. Go to Render.com dashboard
2. Click "Manual Deploy" → "Deploy latest commit"
3. Monitor deployment logs

## ✅ Post-Deployment Verification

### 1. Health Check

Visit: `https://your-domain.com/`

- Should return 200 OK

### 2. Test Google Places Autocomplete

1. Go to any event edit page
2. Try typing in Country field (e.g., "Spain")
3. Try typing in City field (e.g., "Madrid")
4. Verify dropdowns appear with suggestions

### 3. Test Service Worker

1. Open browser DevTools → Application → Service Workers
2. Verify service worker is registered
3. Check for any errors in console

### 4. Test PWA Installation

1. On mobile/tablet, visit your site
2. Look for "Add to Home Screen" prompt
3. Install and verify it works standalone

### 5. Test R2 Storage

1. Upload an image or video
2. Verify it appears correctly
3. Check R2 bucket for the file

### 6. Test Database

1. Create a test event
2. Verify it saves correctly
3. Check that data persists after refresh

## 🔍 Monitoring

### Check Logs

```bash
# In Render.com dashboard
Logs → View logs
```

### Common Issues

#### Google Places not working

- ✅ Verify `GOOGLE_PLACES_API_KEY` is set in Render
- ✅ Verify Places API (New) is enabled in Google Cloud Console
- ✅ Check browser console for API errors
- ✅ Verify API key has no IP/domain restrictions (or add your domain)

#### Service Worker not registering

- ✅ Verify HTTPS is enabled (required for service workers)
- ✅ Check browser console for errors
- ✅ Clear browser cache and reload

#### Images not loading

- ✅ Verify all R2 environment variables are set
- ✅ Check R2 bucket permissions
- ✅ Verify R2_PUBLIC_URL is correct

#### Database connection errors

- ✅ Verify DATABASE_URL is set correctly
- ✅ Check database is running in Render dashboard
- ✅ Verify POOL_SIZE is appropriate for your plan

## 📊 Performance Optimization (Optional)

### Already Implemented

- ✅ Database connection pooling
- ✅ Service Worker caching
- ✅ Image lazy loading
- ✅ Video lazy loading
- ✅ R2 CDN for static assets

### Future Improvements (Optional)

- [ ] Add Redis for session storage
- [ ] Implement rate limiting
- [ ] Add monitoring (e.g., AppSignal, Sentry)
- [ ] Set up CDN for main site (e.g., Cloudflare)
- [ ] Implement database query optimization

## 🔒 Security Checklist

### Already Implemented

- ✅ HTTPS enforced
- ✅ CORS configured
- ✅ SQL injection protection (Ecto)
- ✅ XSS protection (Phoenix)
- ✅ CSRF protection (Phoenix)
- ✅ Secure password hashing (bcrypt)
- ✅ SSL/TLS for database connections

### Recommended (Optional)

- [ ] Set up security headers (CSP, HSTS, etc.)
- [ ] Implement rate limiting for API endpoints
- [ ] Add monitoring for suspicious activity
- [ ] Regular security audits
- [ ] Keep dependencies updated

## 📝 Summary

### Critical Actions Required:

1. **Add `GOOGLE_PLACES_API_KEY` to Render.com environment variables**
2. **Set `PHX_HOST` to your actual domain**
3. **Verify R2 environment variables are set**
4. **Deploy and test**

### Optional but Recommended:

- Set up email configuration (Resend or SMTP)
- Add monitoring/logging service
- Set up custom domain SSL

### Current Status:

- ✅ Code is production-ready
- ✅ All tests passing
- ✅ No security issues
- ⚠️ Needs environment variables configured on Render.com
- ⚠️ Needs deployment and testing

---

**Next Steps:**

1. Go to Render.com dashboard
2. Add `GOOGLE_PLACES_API_KEY` environment variable
3. Verify `PHX_HOST` is set correctly
4. Deploy
5. Test all features
6. Monitor logs for any issues
