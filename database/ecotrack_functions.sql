-- =====================================================
-- ECOTRACK BUSINESS LOGIC FUNCTIONS
-- =====================================================
-- All stored procedures and functions for EcoTrack app
-- Run this AFTER the main schema file

-- =====================================================
-- 1. OTP AUTHENTICATION FUNCTIONS
-- =====================================================

-- Function to generate and send OTP
CREATE OR REPLACE FUNCTION generate_otp(
  p_identifier TEXT,
  p_identifier_type TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_otp_code TEXT;
  v_expires_at TIMESTAMP WITH TIME ZONE;
  v_existing_otp RECORD;
BEGIN
  -- Validate identifier type
  IF p_identifier_type NOT IN ('email', 'phone') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid identifier type');
  END IF;
  
  -- Check for existing valid OTP
  SELECT * INTO v_existing_otp
  FROM public.auth_otps
  WHERE identifier = p_identifier
    AND identifier_type = p_identifier_type
    AND expires_at > NOW()
    AND used = FALSE
    AND attempts < max_attempts;
  
  -- If valid OTP exists and was created less than 1 minute ago, don't create new one
  IF FOUND AND v_existing_otp.created_at > (NOW() - INTERVAL '1 minute') THEN
    RETURN jsonb_build_object(
      'success', false, 
      'error', 'OTP already sent. Please wait before requesting again.',
      'retry_after', EXTRACT(EPOCH FROM (v_existing_otp.created_at + INTERVAL '1 minute' - NOW()))
    );
  END IF;
  
  -- Generate 6-digit OTP
  v_otp_code := LPAD(FLOOR(RANDOM() * 1000000)::TEXT, 6, '0');
  v_expires_at := NOW() + INTERVAL '5 minutes';
  
  -- Invalidate existing OTPs for this identifier
  UPDATE public.auth_otps
  SET used = TRUE
  WHERE identifier = p_identifier AND identifier_type = p_identifier_type;
  
  -- Insert new OTP
  INSERT INTO public.auth_otps (identifier, identifier_type, otp_code, expires_at)
  VALUES (p_identifier, p_identifier_type, v_otp_code, v_expires_at);
  
  -- Return success (in production, you'd send the OTP via email/SMS here)
  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP sent successfully',
    'expires_in', 300, -- 5 minutes in seconds
    'otp_code', v_otp_code -- Remove this in production!
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to verify OTP
CREATE OR REPLACE FUNCTION verify_otp(
  p_identifier TEXT,
  p_identifier_type TEXT,
  p_otp_code TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_otp RECORD;
  v_user_exists BOOLEAN;
  v_user_id UUID;
BEGIN
  -- Find the OTP
  SELECT * INTO v_otp
  FROM public.auth_otps
  WHERE identifier = p_identifier
    AND identifier_type = p_identifier_type
    AND otp_code = p_otp_code
    AND used = FALSE
  ORDER BY created_at DESC
  LIMIT 1;
  
  -- Check if OTP exists
  IF NOT FOUND THEN
    -- Increment attempts for any matching identifier
    UPDATE public.auth_otps
    SET attempts = attempts + 1
    WHERE identifier = p_identifier
      AND identifier_type = p_identifier_type
      AND used = FALSE
      AND expires_at > NOW();
    
    RETURN jsonb_build_object('success', false, 'error', 'Invalid OTP code');
  END IF;
  
  -- Check if OTP is expired
  IF v_otp.expires_at <= NOW() THEN
    RETURN jsonb_build_object('success', false, 'error', 'OTP has expired');
  END IF;
  
  -- Check attempts
  IF v_otp.attempts >= v_otp.max_attempts THEN
    RETURN jsonb_build_object('success', false, 'error', 'Too many attempts. Please request a new OTP');
  END IF;
  
  -- Mark OTP as used
  UPDATE public.auth_otps
  SET used = TRUE, attempts = attempts + 1
  WHERE id = v_otp.id;
  
  -- Check if user already exists
  SELECT EXISTS(
    SELECT 1 FROM public.users WHERE email = p_identifier OR phone = p_identifier
  ) INTO v_user_exists;
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'OTP verified successfully',
    'user_exists', v_user_exists,
    'identifier', p_identifier,
    'identifier_type', p_identifier_type
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. EMISSION CALCULATION FUNCTIONS
-- =====================================================

-- Function to get emission factor for vehicle
CREATE OR REPLACE FUNCTION get_emission_factor(
  p_vehicle_type TEXT,
  p_vehicle_cc INTEGER,
  p_fuel_type TEXT DEFAULT 'gasoline'
)
RETURNS DECIMAL(6, 4) AS $$
DECLARE
  v_emission_factor DECIMAL(6, 4);
BEGIN
  -- Get emission factor based on vehicle specs
  SELECT emission_factor_avg INTO v_emission_factor
  FROM public.vehicle_emission_factors
  WHERE vehicle_type = p_vehicle_type
    AND fuel_type = p_fuel_type
    AND cc_min <= p_vehicle_cc
    AND (cc_max IS NULL OR cc_max >= p_vehicle_cc)
  ORDER BY cc_min DESC
  LIMIT 1;
  
  -- If no specific factor found, use default based on vehicle type
  IF v_emission_factor IS NULL THEN
    IF p_vehicle_type = 'car' THEN
      v_emission_factor := 0.18; -- Average car emission
    ELSIF p_vehicle_type = 'motorcycle' THEN
      v_emission_factor := 0.08; -- Average motorcycle emission
    ELSE
      v_emission_factor := 0.15; -- Default fallback
    END IF;
  END IF;
  
  RETURN v_emission_factor;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate CO2 emission for a trip
CREATE OR REPLACE FUNCTION calculate_trip_emission(
  p_distance_km DECIMAL(10, 2),
  p_vehicle_type TEXT,
  p_vehicle_cc INTEGER,
  p_fuel_type TEXT DEFAULT 'gasoline'
)
RETURNS JSONB AS $$
DECLARE
  v_emission_factor DECIMAL(6, 4);
  v_co2_emission DECIMAL(10, 2);
BEGIN
  -- Get emission factor
  v_emission_factor := get_emission_factor(p_vehicle_type, p_vehicle_cc, p_fuel_type);
  
  -- Calculate total emission
  v_co2_emission := p_distance_km * v_emission_factor;
  
  RETURN jsonb_build_object(
    'distance_km', p_distance_km,
    'emission_factor', v_emission_factor,
    'co2_emission', v_co2_emission,
    'vehicle_type', p_vehicle_type,
    'vehicle_cc', p_vehicle_cc,
    'fuel_type', p_fuel_type
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. TRIP TRACKING FUNCTIONS
-- =====================================================

-- Function to add a new trip
CREATE OR REPLACE FUNCTION add_trip(
  p_user_id UUID,
  p_start_location TEXT,
  p_end_location TEXT,
  p_start_latitude DECIMAL(10, 8) DEFAULT NULL,
  p_start_longitude DECIMAL(11, 8) DEFAULT NULL,
  p_end_latitude DECIMAL(10, 8) DEFAULT NULL,
  p_end_longitude DECIMAL(11, 8) DEFAULT NULL,
  p_distance_km DECIMAL(10, 2),
  p_vehicle_type TEXT,
  p_vehicle_cc INTEGER,
  p_fuel_type TEXT DEFAULT 'gasoline',
  p_trip_duration_minutes INTEGER DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_trip_id UUID;
  v_emission_factor DECIMAL(6, 4);
  v_co2_emission DECIMAL(10, 2);
  v_calculation JSONB;
BEGIN
  -- Calculate emission
  v_calculation := calculate_trip_emission(p_distance_km, p_vehicle_type, p_vehicle_cc, p_fuel_type);
  v_emission_factor := (v_calculation->>'emission_factor')::DECIMAL(6, 4);
  v_co2_emission := (v_calculation->>'co2_emission')::DECIMAL(10, 2);
  
  -- Insert trip
  INSERT INTO public.trip_history (
    user_id, start_location, end_location,
    start_latitude, start_longitude, end_latitude, end_longitude,
    distance_km, vehicle_type, vehicle_cc, fuel_type,
    emission_factor, co2_emission, trip_duration_minutes, notes
  ) VALUES (
    p_user_id, p_start_location, p_end_location,
    p_start_latitude, p_start_longitude, p_end_latitude, p_end_longitude,
    p_distance_km, p_vehicle_type, p_vehicle_cc, p_fuel_type,
    v_emission_factor, v_co2_emission, p_trip_duration_minutes, p_notes
  ) RETURNING id INTO v_trip_id;
  
  -- Update user statistics
  UPDATE public.users
  SET 
    emisi_belum = emisi_belum + v_co2_emission,
    total_distance = total_distance + p_distance_km,
    total_trips = total_trips + 1
  WHERE user_id = p_user_id;
  
  -- Update or create tracking summary
  PERFORM update_tracking_summary(p_user_id);
  
  -- Create notification
  PERFORM create_notification(
    p_user_id,
    'trip_completed',
    'Perjalanan Tercatat!',
    'Perjalanan sejauh ' || p_distance_km || ' km telah tercatat dengan emisi ' || v_co2_emission || ' kg CO₂.',
    jsonb_build_object(
      'trip_id', v_trip_id,
      'distance_km', p_distance_km,
      'co2_emission', v_co2_emission
    )
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'trip_id', v_trip_id,
    'distance_km', p_distance_km,
    'co2_emission', v_co2_emission,
    'emission_factor', v_emission_factor
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. TRACKING SUMMARY FUNCTIONS
-- =====================================================

-- Function to update tracking summary
CREATE OR REPLACE FUNCTION update_tracking_summary(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_current_month INTEGER := EXTRACT(MONTH FROM NOW());
  v_current_year INTEGER := EXTRACT(YEAR FROM NOW());
  v_monthly_stats RECORD;
  v_yearly_stats RECORD;
  v_total_stats RECORD;
  v_offset_stats RECORD;
BEGIN
  -- Calculate monthly statistics
  SELECT 
    COUNT(*) as trip_count,
    COALESCE(SUM(distance_km), 0) as total_distance,
    COALESCE(SUM(co2_emission), 0) as total_emissions
  INTO v_monthly_stats
  FROM public.trip_history
  WHERE user_id = p_user_id
    AND EXTRACT(MONTH FROM trip_date) = v_current_month
    AND EXTRACT(YEAR FROM trip_date) = v_current_year;
  
  -- Calculate yearly statistics
  SELECT 
    COUNT(*) as trip_count,
    COALESCE(SUM(distance_km), 0) as total_distance,
    COALESCE(SUM(co2_emission), 0) as total_emissions
  INTO v_yearly_stats
  FROM public.trip_history
  WHERE user_id = p_user_id
    AND EXTRACT(YEAR FROM trip_date) = v_current_year;
  
  -- Calculate total statistics
  SELECT 
    COUNT(*) as trip_count,
    COALESCE(SUM(distance_km), 0) as total_distance,
    COALESCE(SUM(co2_emission), 0) as total_emissions
  INTO v_total_stats
  FROM public.trip_history
  WHERE user_id = p_user_id;
  
  -- Calculate offset statistics
  SELECT 
    COALESCE(SUM(carbon_amount), 0) as total_offset,
    COALESCE(SUM(tree_count), 0) as trees_planted
  INTO v_offset_stats
  FROM public.donations
  WHERE user_id = p_user_id AND payment_status = 'success';
  
  -- Insert or update tracking summary
  INSERT INTO public.tracking_summary (
    user_id, current_month, current_year,
    monthly_trips, monthly_distance, monthly_emissions,
    yearly_trips, yearly_distance, yearly_emissions,
    total_trips, total_distance, total_emissions, total_offset,
    trees_planted, co2_saved, last_updated
  ) VALUES (
    p_user_id, v_current_month, v_current_year,
    v_monthly_stats.trip_count, v_monthly_stats.total_distance, v_monthly_stats.total_emissions,
    v_yearly_stats.trip_count, v_yearly_stats.total_distance, v_yearly_stats.total_emissions,
    v_total_stats.trip_count, v_total_stats.total_distance, v_total_stats.total_emissions, v_offset_stats.total_offset,
    v_offset_stats.trees_planted, v_offset_stats.total_offset, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    current_month = v_current_month,
    current_year = v_current_year,
    monthly_trips = v_monthly_stats.trip_count,
    monthly_distance = v_monthly_stats.total_distance,
    monthly_emissions = v_monthly_stats.total_emissions,
    yearly_trips = v_yearly_stats.trip_count,
    yearly_distance = v_yearly_stats.total_distance,
    yearly_emissions = v_yearly_stats.total_emissions,
    total_trips = v_total_stats.trip_count,
    total_distance = v_total_stats.total_distance,
    total_emissions = v_total_stats.total_emissions,
    total_offset = v_offset_stats.total_offset,
    trees_planted = v_offset_stats.trees_planted,
    co2_saved = v_offset_stats.total_offset,
    last_updated = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. DONATION FUNCTIONS
-- =====================================================

-- Function to calculate donation details
CREATE OR REPLACE FUNCTION calculate_donation_details(
  p_amount DECIMAL(15, 2),
  p_community_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_community RECORD;
  v_carbon_amount DECIMAL(10, 2);
  v_tree_count INTEGER;
  v_co2_per_tree DECIMAL(5, 2) := 21.00; -- kg CO2 per tree per year
  v_rupiah_per_tree DECIMAL(10, 2) := 10000.00; -- Rp 10,000 per tree
BEGIN
  -- Get community details
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = p_community_id AND is_active = TRUE;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Community not found');
  END IF;
  
  -- Calculate carbon offset amount
  v_carbon_amount := p_amount / v_community.carbon_price_per_kg;
  
  -- Calculate tree count
  v_tree_count := FLOOR(p_amount / v_rupiah_per_tree);
  
  RETURN jsonb_build_object(
    'success', true,
    'amount', p_amount,
    'carbon_amount', v_carbon_amount,
    'tree_count', v_tree_count,
    'co2_per_tree', v_co2_per_tree,
    'total_co2_offset', v_tree_count * v_co2_per_tree,
    'community_name', v_community.name,
    'carbon_price_per_kg', v_community.carbon_price_per_kg
  );
END;
$$ LANGUAGE plpgsql;

-- Function to create donation
CREATE OR REPLACE FUNCTION create_donation(
  p_user_id UUID,
  p_community_id UUID,
  p_amount DECIMAL(15, 2),
  p_donor_name TEXT DEFAULT NULL,
  p_donor_message TEXT DEFAULT NULL,
  p_is_anonymous BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
  v_donation_id UUID;
  v_community RECORD;
  v_carbon_amount DECIMAL(10, 2);
  v_midtrans_order_id TEXT;
BEGIN
  -- Get community details
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = p_community_id AND is_active = TRUE;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Community not found');
  END IF;
  
  -- Calculate carbon amount
  v_carbon_amount := p_amount / v_community.carbon_price_per_kg;
  
  -- Generate unique order ID
  v_midtrans_order_id := 'ECO-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' || UPPER(SUBSTRING(gen_random_uuid()::TEXT, 1, 8));
  
  -- Create donation record
  INSERT INTO public.donations (
    user_id, community_id, amount, carbon_amount,
    donor_name, donor_message, is_anonymous,
    midtrans_order_id, payment_status
  ) VALUES (
    p_user_id, p_community_id, p_amount, v_carbon_amount,
    p_donor_name, p_donor_message, p_is_anonymous,
    v_midtrans_order_id, 'pending'
  ) RETURNING id INTO v_donation_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'donation_id', v_donation_id,
    'midtrans_order_id', v_midtrans_order_id,
    'amount', p_amount,
    'carbon_amount', v_carbon_amount,
    'community_name', v_community.name
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to process successful donation
CREATE OR REPLACE FUNCTION process_successful_donation(
  p_donation_id UUID,
  p_transaction_id TEXT,
  p_payment_type TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_donation RECORD;
  v_community_name TEXT;
BEGIN
  -- Get donation details with community info
  SELECT d.*, c.name as community_name
  INTO v_donation
  FROM public.donations d
  JOIN public.communities c ON d.community_id = c.id
  WHERE d.id = p_donation_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Donation not found');
  END IF;
  
  -- Update donation status
  UPDATE public.donations
  SET 
    payment_status = 'success',
    midtrans_transaction_id = p_transaction_id,
    midtrans_payment_type = p_payment_type,
    paid_at = NOW()
  WHERE id = p_donation_id;
  
  -- Update user's carbon offset
  UPDATE public.users
  SET 
    emisi_offset = emisi_offset + v_donation.carbon_amount,
    emisi_belum = GREATEST(0, emisi_belum - v_donation.carbon_amount)
  WHERE user_id = v_donation.user_id;
  
  -- Update community statistics
  UPDATE public.communities
  SET 
    total_donations = total_donations + v_donation.amount,
    total_carbon_offset = total_carbon_offset + v_donation.carbon_amount,
    total_trees_planted = total_trees_planted + v_donation.tree_count
  WHERE id = v_donation.community_id;
  
  -- Update tracking summary
  PERFORM update_tracking_summary(v_donation.user_id);
  
  -- Create success notification
  PERFORM create_notification(
    v_donation.user_id,
    'donation_success',
    'Donasi Berhasil! 🌱',
    'Donasi Anda sebesar Rp ' || TO_CHAR(v_donation.amount, 'FM999,999,999') || ' untuk ' || v_donation.community_name || ' telah berhasil diproses. Anda telah menanam ' || v_donation.tree_count || ' pohon!',
    jsonb_build_object(
      'donation_id', p_donation_id,
      'amount', v_donation.amount,
      'carbon_amount', v_donation.carbon_amount,
      'tree_count', v_donation.tree_count,
      'community_name', v_donation.community_name
    )
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Donation processed successfully',
    'carbon_offset', v_donation.carbon_amount,
    'trees_planted', v_donation.tree_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. NOTIFICATION FUNCTIONS
-- =====================================================

-- Function to create notification
CREATE OR REPLACE FUNCTION create_notification(
  p_user_id UUID,
  p_type TEXT,
  p_title TEXT,
  p_message TEXT,
  p_data JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_notification_id UUID;
  v_preferences RECORD;
BEGIN
  -- Get user notification preferences
  SELECT * INTO v_preferences
  FROM public.notification_preferences
  WHERE user_id = p_user_id;
  
  -- Create default preferences if not exists
  IF NOT FOUND THEN
    INSERT INTO public.notification_preferences (user_id)
    VALUES (p_user_id);
    
    -- Set default values
    v_preferences.trip_notifications := TRUE;
    v_preferences.donation_notifications := TRUE;
    v_preferences.profile_notifications := TRUE;
    v_preferences.weekly_reminders := TRUE;
    v_preferences.monthly_summaries := TRUE;
    v_preferences.achievement_notifications := TRUE;
    v_preferences.community_updates := TRUE;
  END IF;
  
  -- Check if user wants this type of notification
  IF (p_type = 'trip_completed' AND NOT v_preferences.trip_notifications) OR
     (p_type IN ('donation_success', 'donation_failed') AND NOT v_preferences.donation_notifications) OR
     (p_type = 'profile_updated' AND NOT v_preferences.profile_notifications) OR
     (p_type = 'weekly_reminder' AND NOT v_preferences.weekly_reminders) OR
     (p_type = 'monthly_summary' AND NOT v_preferences.monthly_summaries) OR
     (p_type = 'achievement_unlocked' AND NOT v_preferences.achievement_notifications) OR
     (p_type = 'community_update' AND NOT v_preferences.community_updates) THEN
    RETURN NULL; -- Don't create notification if user disabled it
  END IF;
  
  -- Create notification
  INSERT INTO public.notifications (user_id, type, title, message, data)
  VALUES (p_user_id, p_type, p_title, p_message, p_data)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(
  p_notification_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.notifications
  SET is_read = TRUE
  WHERE id = p_notification_id AND user_id = p_user_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(p_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM public.notifications
  WHERE user_id = p_user_id AND is_read = FALSE;
  
  RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. USER PROFILE FUNCTIONS
-- =====================================================

-- Function to create or update user profile
CREATE OR REPLACE FUNCTION upsert_user_profile(
  p_user_id UUID,
  p_full_name TEXT,
  p_email TEXT,
  p_phone TEXT DEFAULT NULL,
  p_profile_photo_url TEXT DEFAULT NULL,
  p_date_of_birth DATE DEFAULT NULL,
  p_gender TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_province TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
BEGIN
  -- Insert or update user profile
  INSERT INTO public.users (
    user_id, full_name, email, phone, profile_photo_url,
    date_of_birth, gender, address, city, province
  ) VALUES (
    p_user_id, p_full_name, p_email, p_phone, p_profile_photo_url,
    p_date_of_birth, p_gender, p_address, p_city, p_province
  )
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    profile_photo_url = COALESCE(EXCLUDED.profile_photo_url, users.profile_photo_url),
    date_of_birth = COALESCE(EXCLUDED.date_of_birth, users.date_of_birth),
    gender = COALESCE(EXCLUDED.gender, users.gender),
    address = COALESCE(EXCLUDED.address, users.address),
    city = COALESCE(EXCLUDED.city, users.city),
    province = COALESCE(EXCLUDED.province, users.province),
    updated_at = NOW();
  
  -- Create notification for profile update
  PERFORM create_notification(
    p_user_id,
    'profile_updated',
    'Profil Diperbarui',
    'Profil Anda telah berhasil diperbarui.',
    jsonb_build_object('updated_fields', jsonb_build_array('profile'))
  );
  
  RETURN jsonb_build_object(
    'success', true,
    'message', 'Profile updated successfully'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. REPORTING AND ANALYTICS FUNCTIONS
-- =====================================================

-- Function to get user dashboard data
CREATE OR REPLACE FUNCTION get_user_dashboard(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_user RECORD;
  v_tracking RECORD;
  v_recent_trips JSONB;
  v_recent_donations JSONB;
  v_unread_notifications INTEGER;
BEGIN
  -- Get user basic info
  SELECT * INTO v_user
  FROM public.users
  WHERE user_id = p_user_id;
  
  -- Get tracking summary
  SELECT * INTO v_tracking
  FROM public.tracking_summary
  WHERE user_id = p_user_id;
  
  -- Get recent trips (last 5)
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'start_location', start_location,
      'end_location', end_location,
      'distance_km', distance_km,
      'co2_emission', co2_emission,
      'trip_date', trip_date,
      'vehicle_type', vehicle_type
    )
  ) INTO v_recent_trips
  FROM (
    SELECT * FROM public.trip_history
    WHERE user_id = p_user_id
    ORDER BY trip_date DESC, created_at DESC
    LIMIT 5
  ) recent;
  
  -- Get recent donations (last 3)
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', d.id,
      'amount', d.amount,
      'carbon_amount', d.carbon_amount,
      'tree_count', d.tree_count,
      'community_name', c.name,
      'payment_status', d.payment_status,
      'donated_at', d.donated_at
    )
  ) INTO v_recent_donations
  FROM (
    SELECT d.*, c.name
    FROM public.donations d
    JOIN public.communities c ON d.community_id = c.id
    WHERE d.user_id = p_user_id
    ORDER BY d.donated_at DESC
    LIMIT 3
  ) d(id, user_id, community_id, amount, carbon_amount, tree_count, payment_method, payment_status, midtrans_order_id, midtrans_transaction_id, midtrans_payment_type, payment_url, donor_name, donor_message, is_anonymous, donated_at, paid_at, expires_at, created_at, updated_at, name);
  
  -- Get unread notifications count
  v_unread_notifications := get_unread_notification_count(p_user_id);
  
  RETURN jsonb_build_object(
    'user', jsonb_build_object(
      'full_name', v_user.full_name,
      'email', v_user.email,
      'profile_photo_url', v_user.profile_photo_url,
      'emisi_offset', v_user.emisi_offset,
      'emisi_belum', v_user.emisi_belum,
      'total_distance', v_user.total_distance,
      'total_trips', v_user.total_trips
    ),
    'tracking', COALESCE(row_to_json(v_tracking), '{}'::json),
    'recent_trips', COALESCE(v_recent_trips, '[]'::jsonb),
    'recent_donations', COALESCE(v_recent_donations, '[]'::jsonb),
    'unread_notifications', v_unread_notifications
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 9. CLEANUP AND MAINTENANCE FUNCTIONS
-- =====================================================

-- Function to cleanup expired OTPs
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  DELETE FROM public.auth_otps
  WHERE expires_at < NOW() - INTERVAL '1 hour';
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired donations
CREATE OR REPLACE FUNCTION cleanup_expired_donations()
RETURNS INTEGER AS $$
DECLARE
  v_updated_count INTEGER;
BEGIN
  UPDATE public.donations
  SET payment_status = 'expired'
  WHERE payment_status = 'pending'
    AND expires_at < NOW();
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 10. CREATE VIEWS FOR EASY DATA ACCESS
-- =====================================================

-- View for user statistics
CREATE OR REPLACE VIEW user_statistics AS
SELECT 
  u.user_id,
  u.full_name,
  u.email,
  u.emisi_offset,
  u.emisi_belum,
  u.total_distance,
  u.total_trips,
  ts.monthly_trips,
  ts.monthly_distance,
  ts.monthly_emissions,
  ts.yearly_trips,
  ts.yearly_distance,
  ts.yearly_emissions,
  ts.trees_planted,
  ts.co2_saved,
  COUNT(d.id) as total_donations,
  COALESCE(SUM(d.amount), 0) as total_donated_amount
FROM public.users u
LEFT JOIN public.tracking_summary ts ON u.user_id = ts.user_id
LEFT JOIN public.donations d ON u.user_id = d.user_id AND d.payment_status = 'success'
GROUP BY u.user_id, u.full_name, u.email, u.emisi_offset, u.emisi_belum, 
         u.total_distance, u.total_trips, ts.monthly_trips, ts.monthly_distance, 
         ts.monthly_emissions, ts.yearly_trips, ts.yearly_distance, ts.yearly_emissions,
         ts.trees_planted, ts.co2_saved;

-- View for community statistics
CREATE OR REPLACE VIEW community_statistics AS
SELECT 
  c.id,
  c.name,
  c.location,
  c.focus_area,
  c.carbon_price_per_kg,
  c.total_donations,
  c.total_carbon_offset,
  c.total_trees_planted,
  COUNT(d.id) as donation_count,
  COUNT(DISTINCT d.user_id) as unique_donors,
  AVG(d.amount) as avg_donation_amount,
  c.is_active,
  c.is_featured
FROM public.communities c
LEFT JOIN public.donations d ON c.id = d.community_id AND d.payment_status = 'success'
GROUP BY c.id, c.name, c.location, c.focus_area, c.carbon_price_per_kg,
         c.total_donations, c.total_carbon_offset, c.total_trees_planted,
         c.is_active, c.is_featured;

-- =====================================================
-- FUNCTIONS SETUP COMPLETE!
-- =====================================================
-- All business logic functions have been created
-- Ready for Flutter app integration
-- =====================================================