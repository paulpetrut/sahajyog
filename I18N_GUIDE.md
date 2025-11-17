# Internationalization Guide

The website now supports 6 languages:

- English (en) - Default
- Romanian (ro)
- Italian (it)
- German (de)
- Spanish (es)
- French (fr)

## How It Works

### For Users

- A language selector dropdown appears in the top navigation bar
- Select your preferred language from the dropdown
- The interface will immediately update to show content in the selected language
- Your language preference is saved in the session

### For Developers

#### Adding New Translatable Text

1. Wrap text in `gettext()` function:

   ```elixir
   <h1>{gettext("Welcome to Sahaja Yoga")}</h1>
   ```

2. Extract new translations:

   ```bash
   mix gettext.extract --merge
   ```

3. Add translations in `priv/gettext/{locale}/LC_MESSAGES/default.po`:

   ```po
   msgid "Welcome to Sahaja Yoga"
   msgstr "Bine ai venit la Sahaja Yoga"  # Romanian translation
   ```

4. Compile and test:
   ```bash
   mix compile
   ```

#### Adding a New Language

1. Add the locale code to `config/config.exs`:

   ```elixir
   config :sahajyog, SahajyogWeb.Gettext,
     default_locale: "en",
     locales: ~w(en ro it de es fr pt)  # Added Portuguese
   ```

2. Create translation files:

   ```bash
   mix gettext.merge priv/gettext --locale pt
   ```

3. Add the language to the locale switcher in `lib/sahajyog_web/components/locale_switcher.ex`:

   ```elixir
   locales = %{
     "en" => "English",
     "ro" => "Română",
     "it" => "Italiano",
     "de" => "Deutsch",
     "es" => "Español",
     "fr" => "Français",
     "pt" => "Português"  # Added Portuguese
   }
   ```

4. Translate all messages in `priv/gettext/pt/LC_MESSAGES/default.po`

## Architecture

- **Plug**: `SahajyogWeb.Plugs.Locale` - Sets locale from URL params or session
- **LiveView Hook**: `SahajyogWeb.LocaleLive` - Maintains locale across LiveView navigation
- **Component**: `SahajyogWeb.LocaleSwitcher` - Language selector dropdown
- **Translation Files**: `priv/gettext/{locale}/LC_MESSAGES/*.po`

## Current Translations

All user-facing text in the following pages has been translated:

- Welcome page
- Steps/Learning page
- Talks page
- Error messages
- Navigation elements

## Testing

To test different languages:

1. Build assets: `mix assets.build`
2. Start the server: `mix phx.server`
3. Visit http://localhost:4000
4. Use the language dropdown in the top navigation
5. The page will reload with the selected language
6. Navigate between pages to verify translations persist

## How Language Selection Works

When you select a language from the dropdown:

1. JavaScript hook (`LocaleSelector`) captures the change event
2. Page reloads with `?locale=XX` parameter in URL
3. `SahajyogWeb.Plugs.Locale` reads the locale from URL params
4. Locale is saved to session for persistence
5. `Gettext.put_locale/2` sets the active locale
6. All `gettext()` calls now return translations in the selected language
7. `SahajyogWeb.LocaleLive` hook maintains locale across LiveView navigation

## Troubleshooting

**Language not changing:**

- Check browser console for JavaScript errors
- Verify assets are compiled: `mix assets.build`
- Ensure the locale parameter appears in URL after selection
- Check that translation files exist in `priv/gettext/{locale}/LC_MESSAGES/`

**Translations showing as English:**

- Run `mix gettext.extract --merge` to update translation files
- Verify `msgstr` values are filled in the `.po` files
- Check that `Gettext.put_locale/2` is being called with correct locale

**Locale not persisting:**

- Verify session is working (check other session-based features)
- Ensure `SahajyogWeb.Plugs.Locale` is in the browser pipeline
- Check that `SahajyogWeb.LocaleLive` hook is in all `live_session` blocks
