# Email Configuration for Production

This guide explains how to configure email sending for your SahajYog application in production.

## Option 1: Resend (Recommended)

Resend is simple, reliable, and has a generous free tier (100 emails/day, 3,000/month).

### Setup Steps:

1. **Sign up for Resend**

   - Go to https://resend.com
   - Create a free account (you already have one!)
   - Verify your email

2. **Get your API Key**

   - Go to https://resend.com/api-keys
   - Create a new API key or use your existing one
   - Copy the key (starts with `re_`)

3. **Add Domain (Optional but recommended)**

   - Go to https://resend.com/domains
   - Add your domain (e.g., `sahajaonline.xyz`)
   - Add the DNS records they provide to your domain
   - Wait for verification (usually a few minutes)

4. **Configure on Render**

   - Go to your Render dashboard: https://dashboard.render.com
   - Select your `sahajyog` web service
   - Click on **Environment** tab
   - Add these environment variables:
     ```
     RESEND_API_KEY=re_your_api_key_here
     FROM_EMAIL=noreply@sahajaonline.xyz
     FROM_NAME=SahajYog
     ```
   - If you haven't verified a domain yet, use `FROM_EMAIL=onboarding@resend.dev` for testing
   - Click **Save Changes** (this will trigger a redeploy)

5. **Test It**
   - After deployment completes, visit your site
   - Try to register a new account
   - Check if you receive the confirmation email
   - The "Dev mode" warning should be gone

## Option 2: Gmail (Alternative)

Gmail is free, reliable, and easy to set up.

### Setup Steps:

1. **Enable 2-Factor Authentication** on your Google account

   - Go to https://myaccount.google.com/security
   - Enable 2-Step Verification

2. **Create an App Password**

   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and your device
   - Click "Generate"
   - Copy the 16-character password (remove spaces)

3. **Configure on Render**

   - Go to your Render dashboard: https://dashboard.render.com
   - Select your `sahajyog` web service
   - Click on **Environment** tab
   - Add these environment variables:
     ```
     SMTP_HOST=smtp.gmail.com
     SMTP_PORT=587
     SMTP_USERNAME=your-email@gmail.com
     SMTP_PASSWORD=your-16-char-app-password
     SMTP_SSL=false
     FROM_EMAIL=your-email@gmail.com
     FROM_NAME=SahajYog
     ```
   - Click **Save Changes** (this will trigger a redeploy)

4. **Test It**
   - After deployment completes, visit your site
   - Try to register a new account
   - Check if you receive the confirmation email
   - The "Dev mode" warning should be gone

## Alternative: Outlook/Hotmail

If you prefer Outlook:

```
SMTP_HOST=smtp-mail.outlook.com
SMTP_PORT=587
SMTP_USERNAME=your-email@outlook.com
SMTP_PASSWORD=your-password
SMTP_SSL=false
FROM_EMAIL=your-email@outlook.com
FROM_NAME=SahajYog
```

## Alternative: SendGrid SMTP

SendGrid offers 100 emails/day free:

1. Sign up at https://sendgrid.com
2. Create an API key
3. Configure:
   ```
   SMTP_HOST=smtp.sendgrid.net
   SMTP_PORT=587
   SMTP_USERNAME=apikey
   SMTP_PASSWORD=your-sendgrid-api-key
   SMTP_SSL=false
   FROM_EMAIL=noreply@sahajaonline.xyz
   FROM_NAME=SahajYog
   ```

## Alternative: Mailgun SMTP

Mailgun offers 5,000 emails/month free:

1. Sign up at https://mailgun.com
2. Verify your domain
3. Get SMTP credentials
4. Configure:
   ```
   SMTP_HOST=smtp.mailgun.org
   SMTP_PORT=587
   SMTP_USERNAME=postmaster@your-domain.mailgun.org
   SMTP_PASSWORD=your-mailgun-password
   SMTP_SSL=false
   FROM_EMAIL=noreply@sahajaonline.xyz
   FROM_NAME=SahajYog
   ```

## Testing Email Configuration

After configuring, test by:

1. Go to your production site
2. Try to register a new account
3. Try the "Magic link" login option
4. Check if emails are received
5. Check spam folder if not in inbox

## Troubleshooting

### Emails not sending?

1. **Check Render logs**

   - In Render dashboard, go to Logs tab
   - Look for errors related to Swoosh or SMTP

2. **Verify environment variables**

   - Make sure all required variables are set
   - Check for typos in variable names
   - Ensure no extra spaces in values
   - For Gmail, make sure you're using the App Password, not your regular password

3. **Check email provider limits**

   - Gmail: 500 emails/day
   - SendGrid free: 100 emails/day
   - Mailgun free: 5,000 emails/month

4. **Check spam folder**

   - Emails might be marked as spam initially
   - Consider adding SPF and DKIM records to your domain

5. **Test SMTP connection**
   - Make sure the SMTP host and port are correct
   - Verify username and password are correct
   - Check if your email provider requires app-specific passwords

### Dev mode still showing?

The dev mode warning only shows when using `Swoosh.Adapters.Local`. Once you configure SMTP with the environment variables above, it will automatically disappear.

### Gmail "Less secure app" error?

Gmail no longer supports "less secure apps". You MUST use an App Password:

1. Enable 2-Factor Authentication first
2. Then create an App Password
3. Use the App Password (not your regular password) in SMTP_PASSWORD

## Recommended: Gmail

For most users, we recommend Gmail because:

- ✅ Free and reliable
- ✅ Easy setup with App Password
- ✅ 500 emails/day limit (plenty for most apps)
- ✅ Good deliverability
- ✅ No credit card required
- ✅ Works immediately

## Important Security Notes

⚠️ **Never commit passwords or API keys to Git!**

- Always use environment variables on Render
- Never hardcode credentials in your code
- If you accidentally commit a password, change it immediately

## Next Steps

After setting up email:

1. Test registration flow
2. Test magic link login
3. Monitor email delivery
4. Consider adding SPF/DKIM records for better deliverability
5. Monitor your email provider's dashboard for delivery stats
