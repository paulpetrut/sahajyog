# Test Scrolling Fix

## What Was Fixed

The loading bar (topbar) was appearing on every scroll because:

- Infinite scroll triggers LiveView events (`pushEvent("load_more")`)
- TopBar was configured to show on ALL `phx:page-loading-start` events
- This included background loading, not just navigation

## The Fix

Modified `assets/js/app.js` to only show topbar for actual page navigation:

- Only shows for `kind: "initial"` or `kind: "redirect"`
- Ignores patch events and background loading
- Added 200ms delay to prevent flashing on quick loads

## Testing Locally

1. **Start server**:

   ```bash
   mix phx.server
   ```

2. **Visit talks page**: `http://localhost:4000/talks`

3. **Scroll down slowly**:

   - Loading bar should NOT appear
   - Content should load smoothly
   - Only a subtle loading indicator (if any)

4. **Click a navigation link**:
   - Loading bar SHOULD appear briefly
   - This is expected for page navigation

## Testing on Production

After deploying:

1. **Clear browser cache** (important!)
2. **Visit your site**
3. **Scroll on talks page**:
   - Should be smooth
   - No loading bar
4. **Click navigation links**:
   - Loading bar should appear (this is good)

## If Loading Bar Still Appears

1. **Hard refresh**: Ctrl+Shift+R (Cmd+Shift+R)
2. **Clear service worker**:
   ```javascript
   // In browser console
   navigator.serviceWorker.getRegistrations().then((regs) => {
     regs.forEach((reg) => reg.unregister())
   })
   // Then refresh page
   ```
3. **Clear all site data**:
   - DevTools → Application → Clear storage
   - Check all boxes
   - Click "Clear site data"

## Deploy

```bash
git add .
git commit -m "Fix: Prevent loading bar on scroll, only show for navigation"
git push
```

Wait 5-10 minutes for Render to deploy, then test!
