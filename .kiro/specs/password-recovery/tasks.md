# Implementation Plan

- [x] 1. Add token verification for password reset

  - [x] 1.1 Add `verify_reset_password_token_query/1` function to `UserToken` module
    - Add `@reset_password_validity_in_minutes 60` constant
    - Implement token verification query similar to `verify_magic_link_token_query/1`
    - Use "reset_password" as the context
    - _Requirements: 2.4, 3.1, 3.2, 3.3_
  - [x] 1.2 Write property test for token verification
    - **Property 4: Valid token grants form access**
    - **Validates: Requirements 3.1**

- [x] 2. Add password reset context functions

  - [x] 2.1 Add `get_user_by_reset_password_token/1` to Accounts context
    - Use `UserToken.verify_reset_password_token_query/1`
    - Return user if token valid, nil otherwise
    - _Requirements: 3.1, 3.2, 3.3_
  - [x] 2.2 Add `deliver_password_reset_instructions/3` to Accounts context
    - Check if user exists and has a password
    - Generate token using `UserToken.build_email_token/2` with "reset_password" context
    - Delete any existing reset_password tokens for the user before creating new one
    - Call `UserNotifier.deliver_password_reset_instructions/3`
    - Return `{:ok, :no_op}` if user doesn't exist or has no password
    - _Requirements: 1.3, 1.4, 2.1, 2.2, 2.3, 4.2_
  - [x] 2.3 Add `reset_user_password/2` to Accounts context
    - Validate and update password using `User.password_changeset/2`
    - Delete all tokens for the user (sessions and reset tokens)
    - _Requirements: 3.4, 3.5, 4.1, 4.3_
  - [x] 2.4 Write property tests for Accounts password reset functions
    - **Property 1: Token generation for password users creates valid, hashed tokens**
    - **Property 2: Email enumeration prevention**
    - **Property 6: Password reset invalidates all sessions**
    - **Property 7: Token single-use enforcement**
    - **Property 8: New reset request invalidates previous tokens**
    - **Validates: Requirements 1.3, 1.4, 2.1, 2.2, 2.3, 3.5, 4.1, 4.2, 4.3**

- [x] 3. Add email notification for password reset

  - [x] 3.1 Add `deliver_password_reset_instructions/3` to UserNotifier
    - Create email template with reset URL
    - Support locale parameter for i18n
    - Use existing `deliver/3` helper
    - _Requirements: 2.2, 5.2_
  - [x] 3.2 Write property test for email locale
    - **Property 9: Email content respects locale**
    - **Validates: Requirements 5.2**

- [x] 4. Checkpoint - Ensure all tests pass

  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Create ForgotPasswordLive

  - [x] 5.1 Create `lib/sahajyog_web/live/user_live/forgot_password.ex`
    - Implement email form with validation
    - Handle "send_instructions" event
    - Display same success message regardless of email existence
    - Support i18n for all text
    - _Requirements: 1.2, 1.3, 1.4, 1.5, 5.1_
  - [x] 5.2 Write property test for invalid email rejection
    - **Property 3: Invalid email format rejection**
    - **Validates: Requirements 1.5**
  - [x] 5.3 Write LiveView tests for ForgotPasswordLive
    - Test form rendering
    - Test successful submission
    - Test validation errors
    - _Requirements: 1.2, 1.3, 1.4, 1.5_

- [x] 6. Create ResetPasswordLive

  - [x] 6.1 Create `lib/sahajyog_web/live/user_live/reset_password.ex`
    - Verify token on mount, redirect if invalid
    - Implement password form with live validation
    - Handle "validate" and "reset" events
    - Redirect to login with success message on completion
    - Support i18n for all text
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 5.3, 5.4_
  - [x] 6.2 Write property test for password validation
    - **Property 5: Password validation enforcement**
    - **Validates: Requirements 3.4**
  - [x] 6.3 Write LiveView tests for ResetPasswordLive
    - Test valid token shows form
    - Test invalid token redirects
    - Test password validation
    - Test successful reset
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

- [x] 7. Add routes and update login page

  - [x] 7.1 Add routes to router
    - Add `/users/forgot-password` route to `:current_user` live_session
    - Add `/users/reset-password/:token` route to `:current_user` live_session
    - _Requirements: 1.1, 3.1_
  - [x] 7.2 Add "Forgot password?" link to login page
    - Update `UserLive.Login` to include link to forgot password
    - _Requirements: 1.1_

- [x] 8. Add i18n translations

  - [x] 8.1 Add Gettext translations for password recovery
    - Add translations for forgot password form
    - Add translations for reset password form
    - Add translations for email content
    - Add translations for flash messages
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [x] 9. Final Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
