# Google Places Autocomplete Setup

## Overview

The event edit form now includes Google Places autocomplete for the city field. When users start typing a city name, they'll see suggestions from Google Places API, and selecting a location will automatically fill in both the city and country fields.

## Configuration

### 1. Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/apis/credentials)
2. Create a new project or select an existing one
3. Enable the **Places API (New)** - https://console.cloud.google.com/apis/library/places-backend.googleapis.com
4. Enable the **Maps JavaScript API** - https://console.cloud.google.com/apis/library/maps-backend.googleapis.com
5. Create an API key under "Credentials"
6. (Optional but recommended) Restrict the API key:
   - Set application restrictions (HTTP referrers for web)
   - Set API restrictions to only "Places API (New)" and "Maps JavaScript API"

### 2. Add API Key to Environment

Add your API key to the `.env` file:

```bash
GOOGLE_PLACES_API_KEY=your_actual_api_key_here
```

For production (Render.com), add the environment variable in the Render dashboard:

- Go to your service → Environment
- Add `GOOGLE_PLACES_API_KEY` with your production API key

### 3. Restart the Server

After adding the API key, restart your Phoenix server:

```bash
mix phx.server
```

## How It Works

### User Experience

1. Navigate to Event Edit → Location tab
2. Click on the "City" input field
3. Start typing a city name (e.g., "New York", "London", "Tokyo")
4. Google Places will show autocomplete suggestions
5. Select a city from the dropdown
6. Both "City" and "Country" fields are automatically filled

### Technical Implementation

**Frontend (JavaScript Hook)**

- `assets/js/hooks/google_places.js` - Handles Google Places API (New) integration
- Loads the Google Maps JavaScript API with Places library using dynamic import
- Uses `google.maps.importLibrary("places")` for the new API
- Creates Autocomplete instance restricted to cities
- Extracts city and country from selected place
- Sends data to LiveView via `pushEvent`

**Backend (LiveView)**

- `lib/sahajyog_web/live/event_edit_live.ex` - Handles place selection
- `handle_event("place_selected", ...)` receives city/country data
- Updates the form changeset with selected values
- Marks form as changed to enable save button

**Configuration**

- `config/runtime.exs` - Loads API key from environment variable
- `.env` - Stores API key for local development

## API Usage & Costs

Google Places API has a free tier:

- $200 free credit per month
- Autocomplete requests: $2.83 per 1,000 requests
- With free credit: ~70,000 free autocomplete requests per month

For a typical event management app, this should be more than sufficient.

## Fallback Behavior

If the API key is not configured:

- The city field will still work as a regular text input
- Users can manually type city and country names
- No autocomplete suggestions will appear
- A warning will be logged in the browser console

## Testing

To test the autocomplete:

1. Make sure your API key is in `.env`
2. Start the server: `mix phx.server`
3. Log in and create/edit an event
4. Go to the Location tab
5. Click the City field and start typing
6. You should see Google Places suggestions appear

## Troubleshooting

**No suggestions appearing:**

- Check browser console for errors
- Verify API key is set in `.env`
- Ensure Places API is enabled in Google Cloud Console
- Check API key restrictions aren't blocking requests

**"This API key is not authorized" error:**

- Add your domain to API key restrictions in Google Cloud Console
- For local development, add `localhost:4000` to HTTP referrers

**Suggestions appear but fields don't update:**

- Check browser console for JavaScript errors
- Verify LiveView connection is active
- Check that `handle_event("place_selected", ...)` exists in EventEditLive

## Future Enhancements

Possible improvements:

- Add autocomplete to venue name field
- Include latitude/longitude for map integration
- Add autocomplete to address field
- Cache recent searches to reduce API calls
