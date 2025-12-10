-- =====================================================
-- ECOTRACK OTP FUNCTIONS AND API ENDPOINTS
-- =====================================================
-- Run this AFTER the incremental update file
-- Contains OTP system and API functions for Flutter

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
-- 2. DONATION CALCULATION FUNCTIONS
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
  -- Get community details (if communities table exists)
  BEGIN
    SELECT * INTO v_community
    FROM public.communities
    WHERE id = p_community_id AND is_active = TRUE;
    
    IF NOT FOUND THEN
      RETURN jsonb_build_object('success', false, 'error', 'Community not found');
    END IF;
    
    -- Calculate carbon offset amount
    v_carbon_amount := p_amount / v_community.carbon_price_per_kg;
  EXCEPTION
    WHEN undefined_table THEN
      -- If communities table doesn't exist, use default price
      v_carbon_amount := p_amount / 5000.00; -- Default Rp 5,000 per kg
      v_community.name := 'Default Community';
      v_community.carbon_price_per_kg := 5000.00;
  END;
  
  -- Calculate tree count
  v_tree_count := FLOOR(p_amount / v_rupiah_per_tree);
  
  RETURN jsonb_build_object(
    'success', true,
    'amount', p_amount,
    'carbon_amount', v_carbon_amount,
    'tree_count', v_tree_count,
    'co2_per_tree', v_co2_per_tree,
    'total_co2_offset', v_tree_count * v_co2_per_tree,
    'community_name', COALESCE(v_community.name, 'Default Community'),
    'carbon_price_per_kg', COALESCE(v_community.carbon_price_per_kg, 5000.00)
  );
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. NOTIFICATION FUNCTIONS
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
  -- Check if notifications table exists
  BEGIN
    -- Get user notification preferences (if table exists)
    BEGIN
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
      END IF;
    EXCEPTION
      WHEN undefined_table THEN
        -- If notification_preferences table doesn't exist, use defaults
        v_preferences.trip_notifications := TRUE;
        v_preferences.donation_notifications := TRUE;
        v_preferences.profile_notifications := TRUE;
        v_preferences.weekly_reminders := TRUE;
    END;
    
    -- Check if user wants this type of notification
    IF (p_type = 'trip_completed' AND NOT v_preferences.trip_notifications) OR
       (p_type IN ('donation_success', 'donation_failed') AND NOT v_preferences.donation_notifications) OR
       (p_type = 'profile_updated' AND NOT v_preferences.profile_notifications) OR
       (p_type = 'weekly_reminder' AND NOT v_preferences.weekly_reminders) THEN
      RETURN NULL; -- Don't create notification if user disabled it
    END IF;
    
    -- Create notification
    INSERT INTO public.notifications (user_id, type, title, message, data)
    VALUES (p_user_id, p_type, p_title, p_message, p_data)
    RETURNING id INTO v_notification_id;
    
    RETURN v_notification_id;
  EXCEPTION
    WHEN undefined_table THEN
      -- If notifications table doesn't exist, return NULL
      RETURN NULL;
  END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. API ENDPOINTS FOR FLUTTER
-- =====================================================

-- API: Request OTP for login/registration
CREATE OR REPLACE FUNCTION api_request_otp(
  p_identifier TEXT,
  p_identifier_type TEXT DEFAULT 'email'
)
RETURNS JSONB AS $$
BEGIN
  -- Validate input
  IF p_identifier IS NULL OR LENGTH(TRIM(p_identifier)) = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Identifier is required');
  END IF;
  
  IF p_identifier_type NOT IN ('email', 'phone') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid identifier type');
  END IF;
  
  -- Generate OTP
  RETURN generate_otp(TRIM(LOWER(p_identifier)), p_identifier_type);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Verify OTP and login/register
CREATE OR REPLACE FUNCTION api_verify_otp_and_auth(
  p_identifier TEXT,
  p_identifier_type TEXT,
  p_otp_code TEXT,
  p_full_name TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_otp_result JSONB;
  v_user_exists BOOLEAN;
BEGIN
  -- Verify OTP first
  v_otp_result := verify_otp(TRIM(LOWER(p_identifier)), p_identifier_type, p_otp_code);
  
  IF NOT (v_otp_result->>'success')::BOOLEAN THEN
    RETURN v_otp_result;
  END IF;
  
  v_user_exists := (v_otp_result->>'user_exists')::BOOLEAN;
  
  -- If user doesn't exist and we have full_name, create profile
  IF NOT v_user_exists AND p_full_name IS NOT NULL THEN
    -- Note: In real implementation, user_id would come from Supabase Auth
    -- This is just for the database structure
    RETURN jsonb_build_object(
      'success', true,
      'action', 'register',
      'message', 'OTP verified. Ready for registration.',
      'identifier', p_identifier,
      'full_name', p_full_name
    );
  ELSIF v_user_exists THEN
    RETURN jsonb_build_object(
      'success', true,
      'action', 'login',
      'message', 'OTP verified. User can login.',
      'identifier', p_identifier
    );
  ELSE
    RETURN jsonb_build_object(
      'success', false,
      'error', 'User not found. Please provide full name for registration.'
    );
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Get current user profile
CREATE OR REPLACE FUNCTION api_get_profile()
RETURNS JSONB AS $$
DECLARE
  v_user RECORD;
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Get user profile
  SELECT * INTO v_user
  FROM public.users
  WHERE user_id = v_user_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'User profile not found');
  END IF;
  
  -- Return safe profile data
  RETURN jsonb_build_object(
    'success', true,
    'user', jsonb_build_object(
      'user_id', v_user.user_id,
      'full_name', v_user.full_name,
      'email', v_user.email,
      'phone', v_user.phone,
      'profile_photo_url', v_user.profile_photo_url,
      'city', v_user.city,
      'province', v_user.province,
      'emisi_offset', v_user.emisi_offset,
      'emisi_belum', v_user.emisi_belum,
      'total_distance', COALESCE(v_user.total_distance, 0),
      'total_trips', COALESCE(v_user.total_trips, 0),
      'preferred_vehicle_type', v_user.preferred_vehicle_type,
      'preferred_vehicle_cc', v_user.preferred_vehicle_cc,
      'created_at', v_user.created_at
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Add new trip
CREATE OR REPLACE FUNCTION api_add_trip(
  p_start_location TEXT,
  p_end_location TEXT,
  p_distance_km DECIMAL(10, 2),
  p_vehicle_type TEXT,
  p_vehicle_cc INTEGER,
  p_fuel_type TEXT DEFAULT 'gasoline',
  p_start_latitude DECIMAL(10, 8) DEFAULT NULL,
  p_start_longitude DECIMAL(11, 8) DEFAULT NULL,
  p_end_latitude DECIMAL(10, 8) DEFAULT NULL,
  p_end_longitude DECIMAL(11, 8) DEFAULT NULL,
  p_trip_duration_minutes INTEGER DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_trip_id UUID;
  v_emission_factor DECIMAL(6, 4);
  v_co2_emission DECIMAL(10, 2);
  v_calculation JSONB;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Validate input
  IF p_distance_km <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Distance must be greater than 0');
  END IF;
  
  IF p_vehicle_type NOT IN ('car', 'motorcycle') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid vehicle type');
  END IF;
  
  IF p_vehicle_cc <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Vehicle CC must be greater than 0');
  END IF;
  
  -- Calculate emission
  v_calculation := calculate_trip_emission(p_distance_km, p_vehicle_type, p_vehicle_cc, p_fuel_type);
  v_emission_factor := (v_calculation->>'emission_factor')::DECIMAL(6, 4);
  v_co2_emission := (v_calculation->>'co2_emission')::DECIMAL(10, 2);
  
  -- Insert trip
  INSERT INTO public.trip_history (
    user_id, start_location, end_location,
    start_latitude, start_longitude, end_latitude, end_longitude,
    distance_km, distance, vehicle_type, vehicle_cc, fuel_type,
    emission_factor, co2_emission, emission, trip_duration_minutes, notes
  ) VALUES (
    v_user_id, p_start_location, p_end_location,
    p_start_latitude, p_start_longitude, p_end_latitude, p_end_longitude,
    p_distance_km, p_distance_km, p_vehicle_type, p_vehicle_cc, p_fuel_type,
    v_emission_factor, v_co2_emission, v_co2_emission, p_trip_duration_minutes, p_notes
  ) RETURNING id INTO v_trip_id;
  
  -- Update user statistics
  UPDATE public.users
  SET 
    emisi_belum = emisi_belum + v_co2_emission,
    total_distance = COALESCE(total_distance, 0) + p_distance_km,
    total_trips = COALESCE(total_trips, 0) + 1
  WHERE user_id = v_user_id;
  
  -- Update or create tracking summary
  PERFORM update_tracking_summary(v_user_id);
  
  -- Create notification
  PERFORM create_notification(
    v_user_id,
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

-- API: Get user trips with pagination
CREATE OR REPLACE FUNCTION api_get_trips(
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_trips JSONB;
  v_total_count INTEGER;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Get total count
  SELECT COUNT(*) INTO v_total_count
  FROM public.trip_history
  WHERE user_id = v_user_id
    AND (p_start_date IS NULL OR COALESCE(trip_date::date, created_at::date) >= p_start_date)
    AND (p_end_date IS NULL OR COALESCE(trip_date::date, created_at::date) <= p_end_date);
  
  -- Get trips
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'start_location', start_location,
      'end_location', end_location,
      'distance_km', COALESCE(distance_km, distance),
      'vehicle_type', vehicle_type,
      'vehicle_cc', vehicle_cc,
      'fuel_type', fuel_type,
      'co2_emission', COALESCE(co2_emission, emission),
      'trip_date', COALESCE(trip_date, created_at),
      'trip_duration_minutes', trip_duration_minutes,
      'notes', notes,
      'is_offset', is_offset,
      'created_at', created_at
    )
  ) INTO v_trips
  FROM (
    SELECT *
    FROM public.trip_history
    WHERE user_id = v_user_id
      AND (p_start_date IS NULL OR COALESCE(trip_date::date, created_at::date) >= p_start_date)
      AND (p_end_date IS NULL OR COALESCE(trip_date::date, created_at::date) <= p_end_date)
    ORDER BY COALESCE(trip_date, created_at) DESC, created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) t;
  
  RETURN jsonb_build_object(
    'success', true,
    'trips', COALESCE(v_trips, '[]'::jsonb),
    'total_count', v_total_count,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Calculate trip emission preview
CREATE OR REPLACE FUNCTION api_calculate_trip_emission(
  p_distance_km DECIMAL(10, 2),
  p_vehicle_type TEXT,
  p_vehicle_cc INTEGER,
  p_fuel_type TEXT DEFAULT 'gasoline'
)
RETURNS JSONB AS $$
BEGIN
  IF p_distance_km <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Distance must be greater than 0');
  END IF;
  
  IF p_vehicle_type NOT IN ('car', 'motorcycle') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid vehicle type');
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'calculation', calculate_trip_emission(p_distance_km, p_vehicle_type, p_vehicle_cc, p_fuel_type)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Get emission factors
CREATE OR REPLACE FUNCTION api_get_emission_factors()
RETURNS JSONB AS $$
DECLARE
  v_factors JSONB;
BEGIN
  SELECT jsonb_agg(
    jsonb_build_object(
      'vehicle_type', vehicle_type,
      'fuel_type', fuel_type,
      'cc_min', cc_min,
      'cc_max', cc_max,
      'emission_factor_min', emission_factor_min,
      'emission_factor_max', emission_factor_max,
      'emission_factor_avg', emission_factor_avg,
      'description', description
    )
  ) INTO v_factors
  FROM public.vehicle_emission_factors
  ORDER BY vehicle_type, cc_min;
  
  RETURN jsonb_build_object(
    'success', true,
    'emission_factors', COALESCE(v_factors, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. CLEANUP FUNCTIONS
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

-- =====================================================
-- 6. TEST THE FUNCTIONS
-- =====================================================

-- Test OTP generation (remove in production)
SELECT generate_otp('test@example.com', 'email') as test_otp;

-- Test emission calculation
SELECT calculate_trip_emission(25.5, 'car', 1500, 'gasoline') as test_emission;

-- Test donation calculation (if communities exist)
SELECT calculate_donation_details(100000.00, gen_random_uuid()) as test_donation;

-- =====================================================
-- OTP AND API SETUP COMPLETE!
-- =====================================================
-- Added:
-- ✅ OTP authentication system (6-digit codes)
-- ✅ Donation calculation with tree planting formula
-- ✅ API endpoints for Flutter app
-- ✅ Emission calculation based on vehicle CC
-- ✅ Trip tracking with proper emission factors
-- ✅ Cleanup functions for maintenance
-- =====================================================