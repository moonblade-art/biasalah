-- =====================================================
-- ECOTRACK SECURE RLS POLICIES (AUTHENTICATED ONLY)
-- =====================================================
-- This file updates RLS policies to explicitly use the 'authenticated' role
-- instead of 'public' for better security.
--
-- WHY USE 'authenticated' INSTEAD OF 'public'?
-- 1. Explicit Whitelisting: 'public' includes anonymous users. Even with
--    "auth.uid() = user_id", it's safer to explicitly deny anonymous access
--    at the role level.
-- 2. Defense in Depth: If a WHERE clause has a bug, the role check acts as
--    a second layer of defense.
-- 3. Clarity: It clearly signals that these tables are for logged-in users only.

-- =====================================================
-- 1. DROP EXISTING POLICIES
-- =====================================================

-- Users
DROP POLICY IF EXISTS "users_select_own" ON public.users;
DROP POLICY IF EXISTS "users_insert_own" ON public.users;
DROP POLICY IF EXISTS "users_update_own" ON public.users;
DROP POLICY IF EXISTS "Users can read and update own profile" ON public.users;

-- Trip History
DROP POLICY IF EXISTS "trips_select_own" ON public.trip_history;
DROP POLICY IF EXISTS "trips_insert_own" ON public.trip_history;
DROP POLICY IF EXISTS "trips_update_own" ON public.trip_history;
DROP POLICY IF EXISTS "trips_delete_own" ON public.trip_history;
DROP POLICY IF EXISTS "Users can manage own trips" ON public.trip_history;

-- Donations
DROP POLICY IF EXISTS "donations_select_own" ON public.donations;
DROP POLICY IF EXISTS "donations_insert_own" ON public.donations;
DROP POLICY IF EXISTS "donations_update_own" ON public.donations;
DROP POLICY IF EXISTS "donations_delete_own_pending" ON public.donations;
DROP POLICY IF EXISTS "Users can manage own donations" ON public.donations;

-- Tracking Summary
DROP POLICY IF EXISTS "tracking_select_own" ON public.tracking_summary;
DROP POLICY IF EXISTS "tracking_insert_own" ON public.tracking_summary;
DROP POLICY IF EXISTS "tracking_update_own" ON public.tracking_summary;
DROP POLICY IF EXISTS "Users can manage own tracking summary" ON public.tracking_summary;

-- Notifications
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_for_user" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own" ON public.notifications;
DROP POLICY IF EXISTS "Users can read and update own notifications" ON public.notifications;

-- Notification Preferences
DROP POLICY IF EXISTS "notif_prefs_select_own" ON public.notification_preferences;
DROP POLICY IF EXISTS "notif_prefs_insert_own" ON public.notification_preferences;
DROP POLICY IF EXISTS "notif_prefs_update_own" ON public.notification_preferences;
DROP POLICY IF EXISTS "notif_prefs_delete_own" ON public.notification_preferences;
DROP POLICY IF EXISTS "Users can manage own notification preferences" ON public.notification_preferences;

-- =====================================================
-- 2. USERS TABLE (Authenticated Only)
-- =====================================================

-- Read: Only authenticated users can read their own profile
CREATE POLICY "users_select_own" ON public.users
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Insert: Authenticated users can insert their own profile
-- Note: When signing up, the user is authenticated with the new UID
CREATE POLICY "users_insert_own" ON public.users
  AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- Update: Authenticated users can update their own profile
CREATE POLICY "users_update_own" ON public.users
  AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 3. TRIP HISTORY (Authenticated Only)
-- =====================================================

CREATE POLICY "trips_select_own" ON public.trip_history
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "trips_insert_own" ON public.trip_history
  AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "trips_update_own" ON public.trip_history
  AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "trips_delete_own" ON public.trip_history
  AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- 4. DONATIONS (Authenticated Only)
-- =====================================================

CREATE POLICY "donations_select_own" ON public.donations
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "donations_insert_own" ON public.donations
  AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "donations_update_own" ON public.donations
  AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "donations_delete_own_pending" ON public.donations
  AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id AND payment_status IN ('pending', 'failed', 'cancelled'));

-- =====================================================
-- 5. TRACKING SUMMARY (Authenticated Only)
-- =====================================================

CREATE POLICY "tracking_select_own" ON public.tracking_summary
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "tracking_insert_own" ON public.tracking_summary
  AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "tracking_update_own" ON public.tracking_summary
  AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 6. NOTIFICATIONS (Authenticated Only)
-- =====================================================

CREATE POLICY "notifications_select_own" ON public.notifications
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- Note: Insert is usually done by system/triggers (service_role),
-- but if we allow users to create notifications (unlikely), we'd use 'authenticated'.
-- For now, we keep it restricted or allow via function only.
-- If we need to allow inserts from client (e.g. testing):
-- CREATE POLICY "notifications_insert_own" ... TO authenticated ...

CREATE POLICY "notifications_update_own" ON public.notifications
  AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notifications_delete_own" ON public.notifications
  AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- 7. NOTIFICATION PREFERENCES (Authenticated Only)
-- =====================================================

CREATE POLICY "notif_prefs_select_own" ON public.notification_preferences
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "notif_prefs_insert_own" ON public.notification_preferences
  AS PERMISSIVE FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notif_prefs_update_own" ON public.notification_preferences
  AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notif_prefs_delete_own" ON public.notification_preferences
  AS PERMISSIVE FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- =====================================================
-- 8. PUBLIC TABLES (Keep as Public)
-- =====================================================
-- These tables are meant to be read by everyone (including anonymous users
-- if you have a public landing page), or just authenticated users.
-- If you want strict privacy, change TO public -> TO authenticated.
-- Assuming Communities and Emission Factors are public reference data:

-- Communities: Public Read
DROP POLICY IF EXISTS "communities_public_read" ON public.communities;
CREATE POLICY "communities_public_read" ON public.communities
  AS PERMISSIVE FOR SELECT
  TO public -- Intentionally public
  USING (is_active = TRUE);

-- Emission Factors: Public Read
DROP POLICY IF EXISTS "emission_factors_public_read" ON public.vehicle_emission_factors;
CREATE POLICY "emission_factors_public_read" ON public.vehicle_emission_factors
  AS PERMISSIVE FOR SELECT
  TO public -- Intentionally public
  USING (TRUE);

-- =====================================================
-- 9. ADMIN ACCESS (Optional)
-- =====================================================
-- If you have an admin role, you can add policies for them here.
-- Example:
-- CREATE POLICY "admin_all" ON public.users TO authenticated USING (is_admin());
