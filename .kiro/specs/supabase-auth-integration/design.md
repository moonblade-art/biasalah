# Design Document - Supabase Authentication Integration

## Overview

Integrasi Supabase untuk sistem autentikasi EcoTrack menggunakan Supabase Auth untuk manajemen user dan PostgreSQL untuk penyimpanan data profil. Sistem ini menggantikan dummy JSON authentication dengan real backend yang aman dan scalable.

**Tech Stack:**
- Supabase Auth untuk authentication
- Supabase PostgreSQL untuk user profiles
- supabase_flutter package untuk Flutter integration
- Shared Preferences untuk session persistence

## Architecture

### Layer Architecture

```
┌─────────────────────────────────────┐
│         UI Layer (Screens)          │
│  - LoginScreen                      │
│  - RegisterPage                     │
│  - ForgotPasswordPage               │
│  - VerifyPage                       │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Service Layer                  │
│  - SupabaseAuthService              │
│  - UserProfileService               │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      Supabase Client                │
│  - Auth API                         │
│  - Database API                     │
└─────────────────────────────────────┘
```

### Authentication Flow

**Registration Flow:**
```
User Input → Validate → Supabase.auth.signUp() 
→ Create Profile Record → Send Verification Email 
→ Navigate to Verify Page
```

**Login Flow:**
```
User Input → Validate → Supabase.auth.signInWithPassword() 
→ Check Email Verified → Fetch Profile 
→ Save Session → Navigate to Home
```

**Password Reset Flow:**
```
User Input Email → Supabase.auth.resetPasswordForEmail() 
→ Send Reset Email → User Clicks Link 
→ Update Password → Navigate to Login
```

## Components and Interfaces

### 1. SupabaseAuthService

Service class untuk mengelola semua operasi autentikasi.

```dart
class SupabaseAuthService {
  final SupabaseClient _supabase;
  
  // Register new user
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  });
  
  // Login user
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });
  
  // Sign out
  Future<void> signOut();
  
  // Send password reset email
  Future<void> resetPassword(String email);
  
  // Update password
  Future<void> updatePassword(String newPassword);
  
  // Get current user
  User? getCurrentUser();
  
  // Check if email is verified
  bool isEmailVerified();
}
```

### 2. UserProfileService

Service class untuk mengelola data profil pengguna.

```dart
class UserProfileService {
  final SupabaseClient _supabase;
  
  // Create user profile after registration
  Future<void> createProfile({
    required String userId,
    required String fullName,
    required String email,
  });
  
  // Get user profile
  Future<UserProfile?> getProfile(String userId);
  
  // Update emission data
  Future<void> updateEmissions({
    required String userId,
    double? emisiOffset,
    double? emisiBelum,
  });
}
```

### 3. UserProfile Model

```dart
class UserProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final double emisiOffset;
  final double emisiBelum;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  UserProfile({...});
  
  factory UserProfile.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

## Data Models

### Database Schema

#### Table: users (profiles)

```sql
CREATE TABLE public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  emisi_offset DECIMAL(10, 2) DEFAULT 0.0,
  emisi_belum DECIMAL(10, 2) DEFAULT 0.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX idx_users_user_id ON public.users(user_id);
CREATE INDEX idx_users_email ON public.users(email);

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Service role can insert profiles
CREATE POLICY "Service role can insert profiles"
  ON public.users
  FOR INSERT
  WITH CHECK (true);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

#### Table: trip_history (untuk tracking emisi)

```sql
CREATE TABLE public.trip_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  vehicle_type TEXT NOT NULL,
  fuel_type TEXT NOT NULL,
  distance DECIMAL(10, 2) NOT NULL,
  emission DECIMAL(10, 2) NOT NULL,
  is_offset BOOLEAN DEFAULT FALSE,
  trip_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX idx_trip_history_user_id ON public.trip_history(user_id);
CREATE INDEX idx_trip_history_trip_date ON public.trip_history(trip_date);

-- Enable Row Level Security
ALTER TABLE public.trip_history ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own trips
CREATE POLICY "Users can read own trips"
  ON public.trip_history
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own trips
CREATE POLICY "Users can insert own trips"
  ON public.trip_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own trips
CREATE POLICY "Users can update own trips"
  ON public.trip_history
  FOR UPDATE
  USING (auth.uid() = user_id);
```

### Supabase Configuration

**Environment Variables:**
```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String supabaseUrl = 'https://yfisgogkoewxllkhupka.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8';
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Registration creates both auth user and profile

*For any* valid registration data (email, password, name), successful registration should create both an auth.users record and a public.users profile record with matching user_id
**Validates: Requirements 1.1, 4.1**

### Property 2: Login requires verified email

*For any* user account, attempting to login should only succeed if the email_confirmed_at field in auth.users is not null
**Validates: Requirements 2.4**

### Property 3: Profile data persistence

*For any* user profile update operation, the updated_at timestamp should be automatically updated to the current time
**Validates: Requirements 4.2, 4.3**

### Property 4: Password reset email validation

*For any* email address provided to password reset, the system should only send reset email if the email exists in auth.users table
**Validates: Requirements 3.1, 3.5**

### Property 5: Session persistence

*For any* successful login, the session token should be stored and remain valid until explicit logout or token expiration
**Validates: Requirements 2.1, 2.2**

### Property 6: Initial emission values

*For any* newly created user profile, both emisi_offset and emisi_belum should be initialized to 0.0
**Validates: Requirements 4.1**

### Property 7: Row Level Security enforcement

*For any* database query on users or trip_history tables, users should only be able to access their own data based on auth.uid()
**Validates: Requirements 4.2**

## Error Handling

### Error Categories

1. **Network Errors**
   - No internet connection
   - Timeout
   - Server unavailable

2. **Authentication Errors**
   - Invalid credentials
   - Email already registered
   - Email not verified
   - Weak password

3. **Database Errors**
   - Profile creation failed
   - Data fetch failed
   - Update failed

### Error Handling Strategy

```dart
class AuthException implements Exception {
  final String message;
  final String code;
  
  AuthException(this.message, this.code);
  
  static String getUserFriendlyMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-not-found':
        return 'Email tidak terdaftar';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak-password':
        return 'Password terlalu lemah (minimal 6 karakter)';
      case 'network-request-failed':
        return 'Tidak ada koneksi internet';
      default:
        return 'Terjadi kesalahan. Silakan coba lagi';
    }
  }
}
```

## Testing Strategy

### Unit Tests

1. **SupabaseAuthService Tests**
   - Test successful registration
   - Test registration with existing email
   - Test successful login
   - Test login with wrong credentials
   - Test password reset flow

2. **UserProfileService Tests**
   - Test profile creation
   - Test profile fetch
   - Test emission updates

3. **Model Tests**
   - Test UserProfile.fromJson()
   - Test UserProfile.toJson()
   - Test data validation

### Integration Tests

1. **End-to-End Registration Flow**
   - Register → Verify Email → Login → Fetch Profile

2. **End-to-End Login Flow**
   - Login → Fetch Profile → Navigate to Home

3. **End-to-End Password Reset Flow**
   - Request Reset → Receive Email → Update Password → Login

### Property-Based Tests

Property-based testing will use the `test` package with custom generators for:
- Random valid emails
- Random passwords (valid and invalid)
- Random user data

Each property test should run a minimum of 100 iterations.

## Implementation Notes

### Supabase Dashboard Setup

1. **Enable Email Auth:**
   - Go to Authentication → Providers
   - Enable Email provider
   - Configure email templates (optional)

2. **Email Templates:**
   - Customize confirmation email
   - Customize password reset email
   - Use Indonesian language

3. **Security Settings:**
   - Set minimum password length to 6
   - Enable email confirmation
   - Set JWT expiry to 3600 seconds (1 hour)

### Migration from Dummy JSON

1. Keep dummy_login.json as fallback during development
2. Add feature flag to switch between dummy and Supabase
3. Migrate existing test users to Supabase
4. Remove dummy authentication after testing

### Performance Considerations

1. Cache user profile data locally using SharedPreferences
2. Implement offline-first approach for profile data
3. Use Supabase realtime for emission updates (future enhancement)
4. Implement retry logic for failed requests

## Security Considerations

1. **Never store passwords in plain text** - Supabase handles this
2. **Use Row Level Security** for all tables
3. **Validate input** on client side before sending to Supabase
4. **Use HTTPS only** for all API calls
5. **Implement rate limiting** for auth endpoints (Supabase default)
6. **Store sensitive config** in environment variables (not in code)
