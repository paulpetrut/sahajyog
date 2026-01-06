# Quick Deployment Guide

## 🚀 Deploy in 3 Steps

### Step 1: Add Environment Variable on Render.com

1. Go to https://dashboard.render.com
2. Select your `sahajyog` service
3. Click **Environment** in the left sidebar
4. Click **Add Environment Variable**
5. Add:
   ```
   Key: GOOGLE_PLACES_API_KEY
   Value: AIzaSyAxjLgb9t2Vg0ibQkW-U7n8SQgfg4VHx54
   ```
6. Click **Save Changes**

### Step 2: Verify PHX_HOST

1. In the same Environment section
2. Find `PHX_HOST` variable
3. Set it to your domain:
   ```
   PHX_HOST=www.sahajaonline.xyz
   ```
   (or whatever your actual domain is)
4. Click **Save Changes**

### Step 3: Deploy

**Option A: Automatic (Recommended)**

```bash
git add .
git commit -m "Add Google Places API and mobile dropdown fixes"
git push origin main
```

Render will automatically deploy.

**Option B: Manual**

1. Go to Render dashboard
2. Click **Manual Deploy** → **Deploy latest commit**

## ✅ Verify Deployment

After deployment completes (5-10 minutes):

1. **Visit your site**: https://www.sahajaonline.xyz
2. **Test Google Places**:
   - Go to any event edit page
   - Type in Country field → should see suggestions
   - Type in City field → should see suggestions
3. **Test mobile dropdowns**:
   - Open on mobile/tablet
   - Go to Events list page
   - Check Duration/Countries/Cities dropdowns position correctly

## 🔍 Troubleshooting

### Google Places not working?

- Check browser console for errors
- Verify API key is correct in Render environment variables
- Verify "Places API (New)" is enabled in Google Cloud Console
- Check API key has no restrictions (or add your domain to allowed domains)

### Dropdowns still misaligned on mobile?

- Hard refresh the page (Ctrl+Shift+R or Cmd+Shift+R)
- Clear browser cache
- Check if service worker is caching old CSS (disable in DevTools)

### Need help?

Check the full guide: `PRODUCTION_READINESS_CHECKLIST.md`

---

## 📊 Current Status

✅ **Code Quality**

- All tests passing (195 tests)
- 0 Credo issues
- All debug logs removed

✅ **Features Ready**

- Google Places autocomplete for Country/City
- Mobile dropdown positioning fixed
- Service Worker configured
- PWA ready

⚠️ **Action Required**

- Add `GOOGLE_PLACES_API_KEY` to Render.com
- Verify `PHX_HOST` is set correctly
- Deploy and test

**You're ready to deploy! 🎉**
