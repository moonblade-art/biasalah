-- =====================================================
-- ECOTRACK API ENDPOINTS (SQL Functions for Flutter)
-- =====================================================
-- These functions serve as API endpoints for the Flutter app
-- All functions are SECURITY DEFINER for proper RLS handling

-- =====================================================
-- 1. AUTHENTICATION API ENDPOINTS
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
  v_user_id UUID;
  v_profile_result JSONB;
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

-- =====================================================
-- 2. USER PROFILE API ENDPOINTS
-- =====================================================

-- API: Get current user profile
CREATE OR REPLACE FUNCTION api_get_profile()
RETURNS JSONB AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  RETURN get_current_user_profile();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Update user profile
CREATE OR REPLACE FUNCTION api_update_profile(
  p_full_name TEXT DEFAULT NULL,
  p_phone TEXT DEFAULT NULL,
  p_profile_photo_url TEXT DEFAULT NULL,
  p_date_of_birth DATE DEFAULT NULL,
  p_gender TEXT DEFAULT NULL,
  p_address TEXT DEFAULT NULL,
  p_city TEXT DEFAULT NULL,
  p_province TEXT DEFAULT NULL,
  p_preferred_vehicle_type TEXT DEFAULT NULL,
  p_preferred_vehicle_cc INTEGER DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Update profile
  UPDATE public.users SET
    full_name = COALESCE(p_full_name, full_name),
    phone = COALESCE(p_phone, phone),
    profile_photo_url = COALESCE(p_profile_photo_url, profile_photo_url),
    date_of_birth = COALESCE(p_date_of_birth, date_of_birth),
    gender = COALESCE(p_gender, gender),
    address = COALESCE(p_address, address),
    city = COALESCE(p_city, city),
    province = COALESCE(p_province, province),
    preferred_vehicle_type = COALESCE(p_preferred_vehicle_type, preferred_vehicle_type),
    preferred_vehicle_cc = COALESCE(p_preferred_vehicle_cc, preferred_vehicle_cc),
    updated_at = NOW()
  WHERE user_id = v_user_id;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'User not found');
  END IF;
  
  -- Create notification
  PERFORM create_notification(
    v_user_id,
    'profile_updated',
    'Profil Diperbarui',
    'Profil Anda telah berhasil diperbarui.',
    NULL
  );
  
  RETURN jsonb_build_object('success', true, 'message', 'Profile updated successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. TRIP TRACKING API ENDPOINTS
-- =====================================================

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
  
  -- Add trip using the existing function
  RETURN add_trip(
    v_user_id, p_start_location, p_end_location,
    p_start_latitude, p_start_longitude, p_end_latitude, p_end_longitude,
    p_distance_km, p_vehicle_type, p_vehicle_cc, p_fuel_type,
    p_trip_duration_minutes, p_notes
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
    AND (p_start_date IS NULL OR trip_date >= p_start_date)
    AND (p_end_date IS NULL OR trip_date <= p_end_date);
  
  -- Get trips
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'start_location', start_location,
      'end_location', end_location,
      'distance_km', distance_km,
      'vehicle_type', vehicle_type,
      'vehicle_cc', vehicle_cc,
      'fuel_type', fuel_type,
      'co2_emission', co2_emission,
      'trip_date', trip_date,
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
      AND (p_start_date IS NULL OR trip_date >= p_start_date)
      AND (p_end_date IS NULL OR trip_date <= p_end_date)
    ORDER BY trip_date DESC, created_at DESC
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

-- API: Get trip statistics
CREATE OR REPLACE FUNCTION api_get_trip_statistics()
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_stats RECORD;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Get statistics
  SELECT 
    COUNT(*) as total_trips,
    COALESCE(SUM(distance_km), 0) as total_distance,
    COALESCE(SUM(co2_emission), 0) as total_emissions,
    COALESCE(AVG(distance_km), 0) as avg_distance,
    COALESCE(AVG(co2_emission), 0) as avg_emission
  INTO v_stats
  FROM public.trip_history
  WHERE user_id = v_user_id;
  
  RETURN jsonb_build_object(
    'success', true,
    'statistics', jsonb_build_object(
      'total_trips', v_stats.total_trips,
      'total_distance', v_stats.total_distance,
      'total_emissions', v_stats.total_emissions,
      'avg_distance', ROUND(v_stats.avg_distance, 2),
      'avg_emission', ROUND(v_stats.avg_emission, 2)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 4. COMMUNITIES API ENDPOINTS
-- =====================================================

-- API: Get all active communities
CREATE OR REPLACE FUNCTION api_get_communities(
  p_focus_area TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 50,
  p_offset INTEGER DEFAULT 0
)
RETURNS JSONB AS $$
DECLARE
  v_communities JSONB;
  v_total_count INTEGER;
BEGIN
  -- Get total count
  SELECT COUNT(*) INTO v_total_count
  FROM public.communities
  WHERE is_active = TRUE
    AND (p_focus_area IS NULL OR focus_area = p_focus_area);
  
  -- Get communities
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'name', name,
      'description', description,
      'image_url', image_url,
      'location', location,
      'focus_area', focus_area,
      'carbon_price_per_kg', carbon_price_per_kg,
      'total_donations', total_donations,
      'total_carbon_offset', total_carbon_offset,
      'total_trees_planted', total_trees_planted,
      'contact_person', contact_person,
      'contact_email', contact_email,
      'website_url', website_url,
      'is_featured', is_featured,
      'created_at', created_at
    )
  ) INTO v_communities
  FROM (
    SELECT *
    FROM public.communities
    WHERE is_active = TRUE
      AND (p_focus_area IS NULL OR focus_area = p_focus_area)
    ORDER BY is_featured DESC, total_carbon_offset DESC, name
    LIMIT p_limit OFFSET p_offset
  ) c;
  
  RETURN jsonb_build_object(
    'success', true,
    'communities', COALESCE(v_communities, '[]'::jsonb),
    'total_count', v_total_count,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Get community details
CREATE OR REPLACE FUNCTION api_get_community_details(p_community_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_community RECORD;
  v_recent_donations JSONB;
BEGIN
  -- Get community details
  SELECT * INTO v_community
  FROM public.communities
  WHERE id = p_community_id AND is_active = TRUE;
  
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Community not found');
  END IF;
  
  -- Get recent donations (anonymous)
  SELECT jsonb_agg(
    jsonb_build_object(
      'amount', amount,
      'carbon_amount', carbon_amount,
      'tree_count', tree_count,
      'donor_name', CASE WHEN is_anonymous THEN 'Anonymous' ELSE COALESCE(donor_name, 'Anonymous') END,
      'donor_message', donor_message,
      'donated_at', donated_at
    )
  ) INTO v_recent_donations
  FROM (
    SELECT *
    FROM public.donations
    WHERE community_id = p_community_id 
      AND payment_status = 'success'
    ORDER BY donated_at DESC
    LIMIT 10
  ) d;
  
  RETURN jsonb_build_object(
    'success', true,
    'community', jsonb_build_object(
      'id', v_community.id,
      'name', v_community.name,
      'description', v_community.description,
      'image_url', v_community.image_url,
      'location', v_community.location,
      'focus_area', v_community.focus_area,
      'carbon_price_per_kg', v_community.carbon_price_per_kg,
      'total_donations', v_community.total_donations,
      'total_carbon_offset', v_community.total_carbon_offset,
      'total_trees_planted', v_community.total_trees_planted,
      'contact_person', v_community.contact_person,
      'contact_email', v_community.contact_email,
      'website_url', v_community.website_url,
      'created_at', v_community.created_at
    ),
    'recent_donations', COALESCE(v_recent_donations, '[]'::jsonb)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. DONATIONS API ENDPOINTS
-- =====================================================

-- API: Calculate donation details
CREATE OR REPLACE FUNCTION api_calculate_donation(
  p_amount DECIMAL(15, 2),
  p_community_id UUID
)
RETURNS JSONB AS $$
BEGIN
  IF p_amount <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Amount must be greater than 0');
  END IF;
  
  RETURN calculate_donation_details(p_amount, p_community_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Create donation
CREATE OR REPLACE FUNCTION api_create_donation(
  p_community_id UUID,
  p_amount DECIMAL(15, 2),
  p_donor_name TEXT DEFAULT NULL,
  p_donor_message TEXT DEFAULT NULL,
  p_is_anonymous BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  IF p_amount <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Amount must be greater than 0');
  END IF;
  
  RETURN create_donation(
    v_user_id, p_community_id, p_amount,
    p_donor_name, p_donor_message, p_is_anonymous
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Get user donations
CREATE OR REPLACE FUNCTION api_get_donations(
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_status TEXT DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_donations JSONB;
  v_total_count INTEGER;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Get total count
  SELECT COUNT(*) INTO v_total_count
  FROM public.donations
  WHERE user_id = v_user_id
    AND (p_status IS NULL OR payment_status = p_status);
  
  -- Get donations
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', d.id,
      'community_id', d.community_id,
      'community_name', c.name,
      'amount', d.amount,
      'carbon_amount', d.carbon_amount,
      'tree_count', d.tree_count,
      'payment_status', d.payment_status,
      'midtrans_order_id', d.midtrans_order_id,
      'payment_url', d.payment_url,
      'donor_name', d.donor_name,
      'donor_message', d.donor_message,
      'is_anonymous', d.is_anonymous,
      'donated_at', d.donated_at,
      'paid_at', d.paid_at,
      'expires_at', d.expires_at
    )
  ) INTO v_donations
  FROM (
    SELECT d.*, c.name
    FROM public.donations d
    JOIN public.communities c ON d.community_id = c.id
    WHERE d.user_id = v_user_id
      AND (p_status IS NULL OR d.payment_status = p_status)
    ORDER BY d.donated_at DESC
    LIMIT p_limit OFFSET p_offset
  ) d(id, user_id, community_id, amount, carbon_amount, tree_count, payment_method, payment_status, midtrans_order_id, midtrans_transaction_id, midtrans_payment_type, payment_url, donor_name, donor_message, is_anonymous, donated_at, paid_at, expires_at, created_at, updated_at, name);
  
  RETURN jsonb_build_object(
    'success', true,
    'donations', COALESCE(v_donations, '[]'::jsonb),
    'total_count', v_total_count,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 6. NOTIFICATIONS API ENDPOINTS
-- =====================================================

-- API: Get user notifications
CREATE OR REPLACE FUNCTION api_get_notifications(
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0,
  p_unread_only BOOLEAN DEFAULT FALSE
)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_notifications JSONB;
  v_total_count INTEGER;
  v_unread_count INTEGER;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  -- Get total count
  SELECT COUNT(*) INTO v_total_count
  FROM public.notifications
  WHERE user_id = v_user_id
    AND (NOT p_unread_only OR is_read = FALSE);
  
  -- Get unread count
  SELECT COUNT(*) INTO v_unread_count
  FROM public.notifications
  WHERE user_id = v_user_id AND is_read = FALSE;
  
  -- Get notifications
  SELECT jsonb_agg(
    jsonb_build_object(
      'id', id,
      'type', type,
      'title', title,
      'message', message,
      'data', data,
      'is_read', is_read,
      'created_at', created_at
    )
  ) INTO v_notifications
  FROM (
    SELECT *
    FROM public.notifications
    WHERE user_id = v_user_id
      AND (NOT p_unread_only OR is_read = FALSE)
    ORDER BY created_at DESC
    LIMIT p_limit OFFSET p_offset
  ) n;
  
  RETURN jsonb_build_object(
    'success', true,
    'notifications', COALESCE(v_notifications, '[]'::jsonb),
    'total_count', v_total_count,
    'unread_count', v_unread_count,
    'limit', p_limit,
    'offset', p_offset
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Mark notification as read
CREATE OR REPLACE FUNCTION api_mark_notification_read(p_notification_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_success BOOLEAN;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  v_success := mark_notification_read(p_notification_id, v_user_id);
  
  IF v_success THEN
    RETURN jsonb_build_object('success', true, 'message', 'Notification marked as read');
  ELSE
    RETURN jsonb_build_object('success', false, 'error', 'Notification not found');
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- API: Mark all notifications as read
CREATE OR REPLACE FUNCTION api_mark_all_notifications_read()
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_updated_count INTEGER;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  UPDATE public.notifications
  SET is_read = TRUE
  WHERE user_id = v_user_id AND is_read = FALSE;
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  
  RETURN jsonb_build_object(
    'success', true, 
    'message', 'All notifications marked as read',
    'updated_count', v_updated_count
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 7. DASHBOARD API ENDPOINT
-- =====================================================

-- API: Get complete dashboard data
CREATE OR REPLACE FUNCTION api_get_dashboard()
RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Not authenticated');
  END IF;
  
  RETURN jsonb_build_object(
    'success', true,
    'dashboard', get_user_dashboard(v_user_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 8. UTILITY API ENDPOINTS
-- =====================================================

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

-- =====================================================
-- API ENDPOINTS SETUP COMPLETE!
-- =====================================================
-- All API functions are ready for Flutter integration
-- Use these functions as RPC calls from Supabase client
-- =====================================================