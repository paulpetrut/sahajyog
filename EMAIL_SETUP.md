# Email Configuration for Production

This guide explains how to configure email sending for your SahajYog application in production.

## Option 1: Resend (Recommended)

Resend is simple, reliable, and has a generous free tier (100 emails/day, 3,000/month).

### Setup Steps:

1. **Sign up for Resend**

   - Go to https://resend.com
   - Create a free account
   - Verify your email

2. **Get your API Key**

   - Go to API Keys section
   - Create a new API key
   - Copy the key (starts with `re_`)

3. **Add Domain (Optional but recommended)**

   - Go to Domains section
   - Add your domain (e.g., `sahajaonline.xyz`)
   - Add the DNS records they provide to your domain
   - Wait for verification (usually a few minutes)

4. **Configure on Render**

   - Go to your Render dashboard
   - Select your web service
   - Go to Environment tab
   - Add environment variables:
     ```
     RESEND_API_KEY=re_your_api_key_here
     FROM_EMAIL=noreply@sahajaonline.xyz
     FROM_NAME=SahajYog
     ```
   - If you haven't verified a domain yet, use `FROM_EMAIL=onboarding@resend.dev` for testing
   - Save changes (this will trigger a redeploy)

5. **Set From Email**
   - If you verified a domain, use: `noreply@sahajaonline.xyz`
   - If not, use: `onboarding@resend.dev` (for testing only)
   - Update in `lib/sahajyog/accounts/user_notifier.ex`

## Option 2: SMTP (Gmail, Outlook, etc.)

If you prefer to use an existing email account:

### Using Gmail:

1. **Enable 2-Factor Authentication** on your Google account

2. **Create an App Password**

   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and your device
   - Copy the 16-character password

3. **Configure on Render**
   Add these environment variables:
   ```
   SMTP_HOST=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=your-email@gmail.com
   SMTP_PASSWORD=your-16-char-app-password
   SMTP_SSL=false
   ```

### Using Outlook/Hotmail:

```
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
SMTP_SSL=false
```

## Option 3: Other Providers

### Mailgun

```elixir
# In runtime.exs, replace Resend config with:
config :sahajyog, Sahajyog.Mailer,
  adapter: Swoosh.Adapters.Mailgun,
  api_key: System.get_env("MAILGUN_API_KEY"),
  domain: System.get_env("MAILGUN_DOMAIN")
```

Environment variables:

```
MAILGUN_API_KEY=your-api-key
MAILGUN_DOMAIN=mg.yourdomain.com
```

### SendGrid

```elixir
config :sahajyog, Sahajyog.Mailer,
  adapter: Swoosh.Adapters.Sendgrid,
  api_key: System.get_env("SENDGRID_API_KEY")
```

Environment variables:

```
SENDGRID_API_KEY=your-api-key
```

## Testing Email Configuration

After configuring, test by:

1. Go to your production site
2. Try to register a new account
3. Try the "Magic link" login option
4. Check if emails are received

## Troubleshooting

### Emails not sending?

1. **Check Render logs**

   ```bash
   # In Render dashboard, go to Logs tab
   # Look for errors related to Swoosh or Mailer
   ```

2. **Verify environment variables**

   - Make sure all required variables are set
   - Check for typos in variable names
   - Ensure no extra spaces in values

3. **Check email provider limits**

   - Resend free tier: 100/day, 3,000/month
   - Gmail: 500/day
   - Make sure you haven't exceeded limits

4. **Check spam folder**
   - Emails might be marked as spam initially
   - Add your domain's SPF and DKIM records

### Dev mode still showing?

The dev mode warning only shows when using `Swoosh.Adapters.Local`. Once you configure a production adapter (Resend or SMTP), it will automatically disappear.

## Recommended: Resend

For most users, we recommend Resend because:

- ✅ Simple setup (just one API key)
- ✅ Generous free tier
- ✅ Good deliverability
- ✅ Easy domain verification
- ✅ Nice dashboard to track emails
- ✅ No credit card required for free tier

## Next Steps

After setting up email:

1. Test registration flow
2. Test magic link login
3. Test password reset (if implemented)
4. Monitor email delivery in your provider's dashboard
5. Consider adding SPF/DKIM records for better deliverability
