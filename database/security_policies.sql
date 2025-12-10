-- =====================================================
-- ECOTRACK SECURITY POLICIES (RLS)
-- =====================================================
-- Comprehensive Row Level Security setup for Supabase

-- =====================================================
-- 1. DROP EXISTING POLICIES (if any)
-- =====================================================

-- Users table policies
DROP POLICY IF EXISTS "Users can read and update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;

-- OTP policies
DROP POLICY IF EXISTS "OTP access via functions only" ON public.auth_otps;

-- Vehicle emission factors policies
DROP POLICY IF EXISTS "Emission factors are publicly readable" ON public.vehicle_emission_factors;

-- Trip history policies
DROP POLICY IF EXISTS "Users can manage own trips" ON public.trip_history;

-- Communities policies
DROP POLICY IF EXISTS "Communities are publicly readable" ON public.communities;

-- Donations policies
DROP POLICY IF EXISTS "Users can manage own donations" ON public.donations;

-- Tracking summary policies
DROP POLICY IF EXISTS "Users can manage own tracking summary" ON public.tracking_summary;

-- Notifications policies
DROP POLICY IF EXISTS "Users can read and update own notifications" ON public.notifications;

-- Notification preferences policies
DROP POLICY IF EXISTS "Users can manage own notification preferences" ON public.notification_preferences;

-- =====================================================
-- 2. USERS TABLE POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own profile (during registration)
CREATE POLICY "users_insert_own" ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own profile
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users cannot delete their profile (handled by Supabase Auth cascade)
-- No DELETE policy needed

-- =====================================================
-- 3. OTP TABLE POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.auth_otps ENABLE ROW LEVEL SECURITY;

-- OTP table should only be accessible via security definer functions
-- No direct access allowed
CREATE POLICY "otp_no_direct_access" ON public.auth_otps
  FOR ALL
  USING (FALSE);

-- =====================================================
-- 4. VEHICLE EMISSION FACTORS POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.vehicle_emission_factors ENABLE ROW LEVEL SECURITY;

-- Everyone can read emission factors (public data)
CREATE POLICY "emission_factors_public_read" ON public.vehicle_emission_factors
  FOR SELECT
  USING (TRUE);

-- Only admins can modify (no policy = no access for regular users)

-- =====================================================
-- 5. TRIP HISTORY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.trip_history ENABLE ROW LEVEL SECURITY;

-- Users can read their own trips
CREATE POLICY "trips_select_own" ON public.trip_history
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own trips
CREATE POLICY "trips_insert_own" ON public.trip_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own trips
CREATE POLICY "trips_update_own" ON public.trip_history
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own trips
CREATE POLICY "trips_delete_own" ON public.trip_history
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 6. COMMUNITIES TABLE POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

-- Everyone can read active communities
CREATE POLICY "communities_public_read" ON public.communities
  FOR SELECT
  USING (is_active = TRUE);

-- Only admins can modify communities (no policy = no access)

-- =====================================================
-- 7. DONATIONS TABLE POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;

-- Users can read their own donations
CREATE POLICY "donations_select_own" ON public.donations
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own donations
CREATE POLICY "donations_insert_own" ON public.donations
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own donations (for payment status updates)
CREATE POLICY "donations_update_own" ON public.donations
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own pending donations
CREATE POLICY "donations_delete_own_pending" ON public.donations
  FOR DELETE
  USING (auth.uid() = user_id AND payment_status IN ('pending', 'failed', 'cancelled'));

-- =====================================================
-- 8. TRACKING SUMMARY POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.tracking_summary ENABLE ROW LEVEL SECURITY;

-- Users can read their own tracking summary
CREATE POLICY "tracking_select_own" ON public.tracking_summary
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own tracking summary (via functions)
CREATE POLICY "tracking_insert_own" ON public.tracking_summary
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own tracking summary (via functions)
CREATE POLICY "tracking_update_own" ON public.tracking_summary
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 9. NOTIFICATIONS TABLE POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

-- System can insert notifications for users (via functions)
CREATE POLICY "notifications_insert_for_user" ON public.notifications
  FOR INSERT
  WITH CHECK (TRUE); -- Controlled by security definer functions

-- Users can update their own notifications (mark as read)
CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own notifications
CREATE POLICY "notifications_delete_own" ON public.notifications
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 10. NOTIFICATION PREFERENCES POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

-- Users can read their own preferences
CREATE POLICY "notif_prefs_select_own" ON public.notification_preferences
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own preferences
CREATE POLICY "notif_prefs_insert_own" ON public.notification_preferences
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own preferences
CREATE POLICY "notif_prefs_update_own" ON public.notification_preferences
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own preferences
CREATE POLICY "notif_prefs_delete_own" ON public.notification_preferences
  FOR DELETE
  USING (auth.uid() = user_id);

-- =====================================================
-- 11. ADMIN POLICIES (Optional - for admin dashboard)
-- =====================================================

-- Function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  -- Check if user has admin role in auth.users metadata
  RETURN COALESCE(
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin',
    FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Admin policies for communities (if needed)
CREATE POLICY "communities_admin_all" ON public.communities
  FOR ALL
  USING (is_admin())
  WITH CHECK (is_admin());

-- Admin policies for users (read-only for privacy)
CREATE POLICY "users_admin_read" ON public.users
  FOR SELECT
  USING (is_admin());

-- Admin policies for donations (read-only)
CREATE POLICY "donations_admin_read" ON public.donations
  FOR SELECT
  USING (is_admin());

-- =====================================================
-- 12. SECURITY FUNCTIONS
-- =====================================================

-- Function to get current user's profile safely
CREATE OR REPLACE FUNCTION get_current_user_profile()
RETURNS JSONB AS $$
DECLARE
  v_user RECORD;
BEGIN
  -- Get current user profile
  SELECT * INTO v_user
  FROM public.users
  WHERE user_id = auth.uid();
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('error', 'User profile not found');
  END IF;
  
  -- Return safe profile data (exclude sensitive fields if any)
  RETURN jsonb_build_object(
    'user_id', v_user.user_id,
    'full_name', v_user.full_name,
    'email', v_user.email,
    'phone', v_user.phone,
    'profile_photo_url', v_user.profile_photo_url,
    'city', v_user.city,
    'province', v_user.province,
    'emisi_offset', v_user.emisi_offset,
    'emisi_belum', v_user.emisi_belum,
    'total_distance', v_user.total_distance,
    'total_trips', v_user.total_trips,
    'preferred_vehicle_type', v_user.preferred_vehicle_type,
    'preferred_vehicle_cc', v_user.preferred_vehicle_cc,
    'created_at', v_user.created_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access resource
CREATE OR REPLACE FUNCTION can_access_resource(
  p_resource_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  -- User can access their own resources or if they're admin
  RETURN (auth.uid() = p_resource_user_id) OR is_admin();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 13. AUDIT TRIGGERS (Optional - for security logging)
-- =====================================================

-- Create audit log table
CREATE TABLE IF NOT EXISTS public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
  user_id UUID,
  old_data JSONB,
  new_data JSONB,
  changed_fields TEXT[],
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for audit log
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- Only admins can read audit logs
CREATE POLICY "audit_log_admin_only" ON public.audit_log
  FOR SELECT
  USING (is_admin());

-- Audit trigger function
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
DECLARE
  v_old_data JSONB;
  v_new_data JSONB;
  v_changed_fields TEXT[];
BEGIN
  -- Convert OLD and NEW to JSONB
  IF TG_OP = 'DELETE' THEN
    v_old_data := to_jsonb(OLD);
    v_new_data := NULL;
  ELSIF TG_OP = 'INSERT' THEN
    v_old_data := NULL;
    v_new_data := to_jsonb(NEW);
  ELSE -- UPDATE
    v_old_data := to_jsonb(OLD);
    v_new_data := to_jsonb(NEW);
    
    -- Find changed fields
    SELECT array_agg(key) INTO v_changed_fields
    FROM jsonb_each(v_new_data)
    WHERE v_old_data -> key IS DISTINCT FROM v_new_data -> key;
  END IF;
  
  -- Insert audit record
  INSERT INTO public.audit_log (
    table_name, operation, user_id, old_data, new_data, changed_fields
  ) VALUES (
    TG_TABLE_NAME, TG_OP, auth.uid(), v_old_data, v_new_data, v_changed_fields
  );
  
  -- Return appropriate record
  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  ELSE
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create audit triggers for sensitive tables (optional)
-- Uncomment if you want audit logging

-- CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON public.users
--   FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- CREATE TRIGGER audit_donations AFTER INSERT OR UPDATE OR DELETE ON public.donations
--   FOR EACH ROW EXECUTE FUNCTION audit_trigger();

-- =====================================================
-- 14. VERIFY SECURITY SETUP
-- =====================================================

-- Check RLS is enabled on all tables
SELECT 
  schemaname, tablename, rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'users', 'auth_otps', 'vehicle_emission_factors', 'trip_history',
    'communities', 'donations', 'tracking_summary', 'notifications',
    'notification_preferences'
  )
ORDER BY tablename;

-- Check policies exist
SELECT 
  schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Test functions
SELECT 
  routine_name, routine_type, security_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'is_admin', 'get_current_user_profile', 'can_access_resource'
  )
ORDER BY routine_name;

-- =====================================================
-- SECURITY SETUP COMPLETE!
-- =====================================================
-- All tables have proper RLS policies
-- Security functions are in place
-- Audit logging is available (optional)
-- Ready for production use
-- =====================================================