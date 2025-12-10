# EcoTrack Database Deployment Guide for Supabase

## 📋 Overview
This guide will help you deploy the complete EcoTrack database schema to Supabase with all required tables, functions, security policies, and sample data.

## 🗂️ File Structure
```
database/
├── ecotrack_complete_schema.sql    # Main database schema
├── ecotrack_functions.sql          # Business logic functions
├── security_policies.sql           # Row Level Security policies
├── api_endpoints.sql               # API functions for Flutter
├── sample_data.sql                 # Test data (optional)
└── DEPLOYMENT_GUIDE.md            # This file
```

## 🚀 Deployment Steps

### Step 1: Access Supabase SQL Editor
1. Go to your Supabase project dashboard
2. Navigate to **SQL Editor** in the left sidebar
3. Create a new query

### Step 2: Deploy Main Schema
1. Copy and paste the contents of `ecotrack_complete_schema.sql`
2. Click **Run** to execute
3. Verify all tables are created successfully

### Step 3: Deploy Business Logic Functions
1. Copy and paste the contents of `ecotrack_functions.sql`
2. Click **Run** to execute
3. Verify all functions are created

### Step 4: Deploy Security Policies
1. Copy and paste the contents of `security_policies.sql`
2. Click **Run** to execute
3. Verify RLS is enabled on all tables

### Step 5: Deploy API Endpoints
1. Copy and paste the contents of `api_endpoints.sql`
2. Click **Run** to execute
3. Verify all API functions are created

### Step 6: Deploy Sample Data (Optional)
1. Copy and paste the contents of `sample_data.sql`
2. Click **Run** to execute
3. This creates test users, trips, and donations for development

## 🔧 Configuration

### Environment Variables for Flutter
Add these to your Flutter app's environment:
```dart
// lib/config/supabase_config.dart
class SupabaseConfig {
  static const String url = 'YOUR_SUPABASE_URL';
  static const String anonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String serviceRoleKey = 'YOUR_SUPABASE_SERVICE_ROLE_KEY'; // For admin functions
}
```

### Supabase Auth Settings
1. Go to **Authentication** > **Settings**
2. Enable **Email confirmations** if using email OTP
3. Configure **SMS** provider if using phone OTP
4. Set up **Custom SMTP** for email notifications (optional)

### Storage Setup (for profile photos)
1. Go to **Storage**
2. Create a bucket named `profile-photos`
3. Set bucket policy to allow authenticated users to upload

## 📊 Database Schema Overview

### Core Tables
- **users**: User profiles and carbon tracking data
- **trip_history**: Individual trip records with emissions
- **communities**: Carbon offset communities/projects
- **donations**: User donations to communities
- **notifications**: In-app notifications
- **tracking_summary**: Aggregated user statistics

### Supporting Tables
- **auth_otps**: OTP codes for authentication
- **vehicle_emission_factors**: CO2 emission rates by vehicle type
- **notification_preferences**: User notification settings

### Key Features
- **OTP Authentication**: 6-digit codes for login/registration
- **Emission Calculation**: Based on vehicle CC and distance
- **Carbon Offset Tracking**: Donations and tree planting
- **Real-time Notifications**: Trip completion, donation success
- **Row Level Security**: Secure data access per user

## 🔐 Security Features

### Row Level Security (RLS)
- All tables have RLS enabled
- Users can only access their own data
- Public data (communities, emission factors) is readable by all
- Admin functions for management

### API Security
- All API functions use `SECURITY DEFINER`
- Authentication required for user-specific operations
- Input validation on all parameters
- SQL injection protection

## 🧪 Testing the Deployment

### 1. Test OTP System
```sql
-- Generate OTP
SELECT api_request_otp('test@example.com', 'email');

-- Verify OTP (use the code from above)
SELECT api_verify_otp_and_auth('test@example.com', 'email', '123456', 'Test User');
```

### 2. Test Emission Calculation
```sql
-- Calculate trip emission
SELECT api_calculate_trip_emission(25.5, 'car', 1500, 'gasoline');
```

### 3. Test Communities
```sql
-- Get all communities
SELECT api_get_communities();
```

### 4. Test with Sample Data
If you deployed sample data, test with existing users:
```sql
-- Get user dashboard (requires auth.uid())
SELECT api_get_dashboard();
```

## 📱 Flutter Integration

### Supabase Client Setup
```dart
import 'package:supabase_flutter/supabase_flutter.dart';

await Supabase.initialize(
  url: SupabaseConfig.url,
  anonKey: SupabaseConfig.anonKey,
);

final supabase = Supabase.instance.client;
```

### API Function Calls
```dart
// Request OTP
final response = await supabase.rpc('api_request_otp', {
  'p_identifier': 'user@example.com',
  'p_identifier_type': 'email',
});

// Add trip
final tripResponse = await supabase.rpc('api_add_trip', {
  'p_start_location': 'Home',
  'p_end_location': 'Office',
  'p_distance_km': 15.5,
  'p_vehicle_type': 'car',
  'p_vehicle_cc': 1500,
});

// Get communities
final communities = await supabase.rpc('api_get_communities');
```

## 🔄 Maintenance

### Regular Cleanup
Run these functions periodically (can be automated):
```sql
-- Clean expired OTPs (run daily)
SELECT cleanup_expired_otps();

-- Clean expired donations (run daily)
SELECT cleanup_expired_donations();
```

### Monitoring
Monitor these views for insights:
- `user_statistics`: User engagement and carbon data
- `community_statistics`: Community performance
- `audit_log`: Security and usage tracking (if enabled)

## 🐛 Troubleshooting

### Common Issues

1. **RLS Policy Errors**
   - Ensure user is authenticated before calling functions
   - Check that `auth.uid()` returns a valid UUID

2. **Function Not Found**
   - Verify all SQL files were executed in order
   - Check for syntax errors in the SQL editor

3. **Permission Denied**
   - Ensure RLS policies are correctly configured
   - Check that functions are marked as `SECURITY DEFINER`

4. **Sample Data Issues**
   - Sample data uses hardcoded UUIDs
   - In production, use actual Supabase Auth user IDs

### Debugging Queries
```sql
-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- Check existing policies
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';

-- Check functions
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE 'api_%';
```

## 📈 Performance Optimization

### Indexes
All necessary indexes are created automatically:
- User lookups by email/phone
- Trip history by user and date
- Donations by user and community
- Notifications by user and read status

### Query Optimization
- Use pagination for large datasets
- Filter by date ranges for trip history
- Cache community data in Flutter app

## 🔒 Production Considerations

### Security Checklist
- [ ] Remove sample data in production
- [ ] Set up proper SMTP for email notifications
- [ ] Configure SMS provider for phone OTP
- [ ] Enable audit logging if required
- [ ] Set up database backups
- [ ] Monitor API usage and performance

### Scaling
- Database can handle thousands of users
- Consider read replicas for heavy read workloads
- Monitor connection pool usage
- Implement caching for frequently accessed data

## 📞 Support

If you encounter issues:
1. Check the Supabase logs in the dashboard
2. Verify all SQL files were executed successfully
3. Test individual functions in the SQL editor
4. Check Flutter app logs for client-side errors

---

**Deployment Complete!** 🎉

Your EcoTrack database is now ready for production use with:
- ✅ Complete schema with all tables
- ✅ Business logic functions
- ✅ Security policies (RLS)
- ✅ API endpoints for Flutter
- ✅ Sample data for testing
- ✅ Comprehensive documentation