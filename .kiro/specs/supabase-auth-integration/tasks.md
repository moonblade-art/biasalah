# Implementation Plan - Supabase Authentication Integration

- [x] 1. Setup Supabase Configuration


  - Add supabase_flutter package to pubspec.yaml
  - Create config file with Supabase URL and API key
  - Initialize Supabase client in main.dart
  - _Requirements: 5.1, 5.2, 5.5_

- [ ] 2. Create Database Schema in Supabase
  - Execute SQL script to create users table with RLS policies
  - Execute SQL script to create trip_history table with RLS policies
  - Verify tables and policies in Supabase dashboard
  - Enable Email authentication in Supabase dashboard
  - _Requirements: 4.1, 4.5_




- [ ] 3. Implement Core Service Classes
  - [ ] 3.1 Create SupabaseAuthService class
    - Implement signUp method with email verification
    - Implement signIn method with session management
    - Implement signOut method
    - Implement resetPassword method

    - Implement getCurrentUser and isEmailVerified helpers
    - _Requirements: 1.1, 2.1, 3.1, 5.2_

  - [ ] 3.2 Create UserProfileService class
    - Implement createProfile method
    - Implement getProfile method

    - Implement updateEmissions method
    - Add error handling for database operations
    - _Requirements: 4.1, 4.2, 4.3, 5.3_




  - [ ] 3.3 Update UserProfile model
    - Add userId field for Supabase auth reference
    - Update fromJson to handle Supabase response format
    - Add validation methods
    - _Requirements: 4.1, 4.5_

- [x] 4. Update Authentication Screens

  - [ ] 4.1 Update RegisterPage
    - Replace dummy registration with SupabaseAuthService.signUp
    - Add loading state during registration
    - Handle registration errors with user-friendly messages
    - Create user profile after successful registration
    - Navigate to verify page after registration
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_


  - [ ] 4.2 Update LoginScreen
    - Replace dummy JSON login with SupabaseAuthService.signIn
    - Add email verification check
    - Fetch user profile after successful login
    - Store session data

    - Handle login errors with user-friendly messages
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

  - [ ] 4.3 Update ForgotPasswordPage
    - Implement password reset with SupabaseAuthService.resetPassword
    - Add email validation before sending reset

    - Show success message after email sent
    - Handle errors (email not found, network issues)
    - _Requirements: 3.1, 3.2, 3.5_

  - [x] 4.4 Update VerifyPage for email verification

    - Add UI to inform user to check email
    - Add resend verification email button
    - Add check verification status functionality
    - Navigate to login after verification
    - _Requirements: 1.2, 1.5_


  - [ ] 4.5 Update ResetPasswordPage
    - Implement new password form
    - Add password confirmation validation
    - Update password using Supabase
    - Navigate to login after successful reset
    - _Requirements: 3.3, 3.4_


- [ ] 5. Implement Session Management
  - Create session persistence using SharedPreferences
  - Add auto-login check on app startup
  - Implement logout functionality across app
  - Clear session data on logout


  - _Requirements: 2.1, 2.2, 5.4_

- [ ] 6. Add Error Handling and Loading States
  - Create AuthException class with user-friendly messages
  - Add loading indicators to all auth operations
  - Implement network error detection
  - Add retry mechanism for failed requests
  - _Requirements: 2.5, 5.3, 5.4_

- [ ] 7. Update Navigation Flow
  - Update main.dart to check authentication state on startup
  - Redirect to home if user is already logged in
  - Redirect to login if session expired
  - Update all navigation routes to use new auth flow
  - _Requirements: 2.2, 5.4_

- [ ] 8. Remove Dummy Authentication
  - Remove dummy_login.json file
  - Remove dummy user model references
  - Clean up unused imports
  - Update README with new setup instructions
  - _Requirements: 5.1_

- [ ] 9. Checkpoint - Test Complete Authentication Flow
  - Ensure all tests pass, ask the user if questions arise
  - Test registration → email verification → login flow
  - Test login with correct and incorrect credentials
  - Test forgot password → reset → login flow
  - Test session persistence across app restarts
  - Verify database records are created correctly
  - _Requirements: All_
