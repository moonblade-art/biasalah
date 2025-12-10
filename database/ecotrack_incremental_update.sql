-- =====================================================
-- ECOTRACK INCREMENTAL UPDATE - SAFE FOR EXISTING DATABASE
-- =====================================================
-- This file safely adds missing features to existing EcoTrack database
-- Run this if you already have users and trip_history tables

-- =====================================================
-- 1. ENABLE EXTENSIONS (SAFE)
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 2. ADD MISSING COLUMNS TO EXISTING USERS TABLE
-- =====================================================

-- Add missing columns to users table (safe - uses IF NOT EXISTS)
ALTER TABLE public.users 
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS profile_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS date_of_birth DATE,
  ADD COLUMN IF NOT EXISTS gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS city TEXT,
  ADD COLUMN IF NOT EXISTS province TEXT,
  ADD COLUMN IF NOT EXISTS total_distance DECIMAL(10, 2) DEFAULT 0.00,
  ADD COLUMN IF NOT EXISTS preferred_vehicle_type TEXT DEFAULT 'car',
  ADD COLUMN IF NOT EXISTS preferred_vehicle_cc INTEGER DEFAULT 1500,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;

-- Add missing indexes (safe)
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_active ON public.users(is_active);

-- =====================================================
-- 3. ADD MISSING COLUMNS TO EXISTING TRIP_HISTORY TABLE
-- =====================================================

-- Add missing columns to trip_history table
ALTER TABLE public.trip_history 
  ADD COLUMN IF NOT EXISTS start_location TEXT,
  ADD COLUMN IF NOT EXISTS end_location TEXT,
  ADD COLUMN IF NOT EXISTS start_latitude DECIMAL(10, 8),
  ADD COLUMN IF NOT EXISTS start_longitude DECIMAL(11, 8),
  ADD COLUMN IF NOT EXISTS end_latitude DECIMAL(10, 8),
  ADD COLUMN IF NOT EXISTS end_longitude DECIMAL(11, 8),
  ADD COLUMN IF NOT EXISTS distance_km DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS vehicle_cc INTEGER,
  ADD COLUMN IF NOT EXISTS emission_factor DECIMAL(6, 4),
  ADD COLUMN IF NOT EXISTS co2_emission DECIMAL(10, 2),
  ADD COLUMN IF NOT EXISTS trip_duration_minutes INTEGER,
  ADD COLUMN IF NOT EXISTS notes TEXT,
  ADD COLUMN IF NOT EXISTS offset_date TIMESTAMP WITH TIME ZONE,
  ADD COLUMN IF NOT EXISTS offset_donation_id UUID;

-- Update existing data if columns were just added
UPDATE public.trip_history 
SET 
  distance_km = COALESCE(distance_km, distance),
  co2_emission = COALESCE(co2_emission, emission),
  vehicle_cc = COALESCE(vehicle_cc, 1500) -- default CC
WHERE distance_km IS NULL OR co2_emission IS NULL OR vehicle_cc IS NULL;

-- =====================================================
-- 4. CREATE OTP AUTHENTICATION TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.auth_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  identifier TEXT NOT NULL, -- email or phone number
  identifier_type TEXT NOT NULL CHECK (identifier_type IN ('email', 'phone')),
  otp_code TEXT NOT NULL, -- 6 digit OTP
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  used BOOLEAN DEFAULT FALSE,
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for OTP
CREATE INDEX IF NOT EXISTS idx_auth_otps_identifier ON public.auth_otps(identifier);
CREATE INDEX IF NOT EXISTS idx_auth_otps_code ON public.auth_otps(otp_code);
CREATE INDEX IF NOT EXISTS idx_auth_otps_expires ON public.auth_otps(expires_at);

-- =====================================================
-- 5. CREATE VEHICLE EMISSION FACTORS TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.vehicle_emission_factors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('car', 'motorcycle')),
  fuel_type TEXT NOT NULL CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid')),
  cc_min INTEGER NOT NULL,
  cc_max INTEGER,
  emission_factor_min DECIMAL(6, 4) NOT NULL, -- kg CO2 per km (minimum)
  emission_factor_max DECIMAL(6, 4) NOT NULL, -- kg CO2 per km (maximum)
  emission_factor_avg DECIMAL(6, 4) GENERATED ALWAYS AS ((emission_factor_min + emission_factor_max) / 2) STORED,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for emission factors
CREATE INDEX IF NOT EXISTS idx_emission_factors_vehicle_type ON public.vehicle_emission_factors(vehicle_type);
CREATE INDEX IF NOT EXISTS idx_emission_factors_cc_range ON public.vehicle_emission_factors(cc_min, cc_max);

-- =====================================================
-- 6. CREATE TRACKING SUMMARY TABLE
-- =====================================================

CREATE TABLE IF NOT EXISTS public.tracking_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  
  -- Monthly statistics
  current_month INTEGER DEFAULT EXTRACT(MONTH FROM NOW()),
  current_year INTEGER DEFAULT EXTRACT(YEAR FROM NOW()),
  
  -- Trip statistics
  monthly_trips INTEGER DEFAULT 0,
  monthly_distance DECIMAL(10, 2) DEFAULT 0.00,
  monthly_emissions DECIMAL(10, 2) DEFAULT 0.00,
  
  -- Yearly statistics
  yearly_trips INTEGER DEFAULT 0,
  yearly_distance DECIMAL(10, 2) DEFAULT 0.00,
  yearly_emissions DECIMAL(10, 2) DEFAULT 0.00,
  
  -- All-time statistics
  total_trips INTEGER DEFAULT 0,
  total_distance DECIMAL(10, 2) DEFAULT 0.00,
  total_emissions DECIMAL(10, 2) DEFAULT 0.00,
  total_offset DECIMAL(10, 2) DEFAULT 0.00,
  
  -- Achievements
  trees_planted INTEGER DEFAULT 0,
  co2_saved DECIMAL(10, 2) DEFAULT 0.00,
  
  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for tracking summary
CREATE INDEX IF NOT EXISTS idx_tracking_summary_user_id ON public.tracking_summary(user_id);
CREATE INDEX IF NOT EXISTS idx_tracking_summary_month_year ON public.tracking_summary(current_month, current_year);

-- =====================================================
-- 7. ADD MISSING COLUMNS TO EXISTING DONATIONS TABLE (IF EXISTS)
-- =====================================================

-- Check if donations table exists and add missing columns
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'donations') THEN
    -- Add tree_count column if not exists
    ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS tree_count INTEGER GENERATED ALWAYS AS (FLOOR(amount / 10000)) STORED;
    
    -- Add other missing columns
    ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS midtrans_transaction_id TEXT;
    ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS midtrans_payment_type TEXT;
    ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS donor_name TEXT;
    ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS donor_message TEXT;
    ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS is_anonymous BOOLEAN DEFAULT FALSE;
    ALTER TABLE public.donations ADD COLUMN IF NOT EXISTS expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours');
  END IF;
END $$;

-- =====================================================
-- 8. INSERT VEHICLE EMISSION FACTORS DATA
-- =====================================================

-- Clear existing data and insert fresh data
DELETE FROM public.vehicle_emission_factors;

-- Car emission factors (gasoline)
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) VALUES
('car', 'gasoline', 0, 999, 0.11, 0.13, 'Small cars under 1000cc'),
('car', 'gasoline', 1000, 1400, 0.13, 0.16, 'Compact cars 1000-1400cc'),
('car', 'gasoline', 1401, 2000, 0.16, 0.21, 'Mid-size cars 1401-2000cc'),
('car', 'gasoline', 2001, 3000, 0.21, 0.28, 'Large cars 2001-3000cc'),
('car', 'gasoline', 3001, 9999, 0.28, 0.40, 'Very large cars over 3000cc');

-- Motorcycle emission factors (gasoline)
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) VALUES
('motorcycle', 'gasoline', 0, 124, 0.04, 0.06, 'Small motorcycles under 125cc'),
('motorcycle', 'gasoline', 125, 250, 0.06, 0.09, 'Medium motorcycles 125-250cc'),
('motorcycle', 'gasoline', 251, 500, 0.09, 0.12, 'Large motorcycles 251-500cc'),
('motorcycle', 'gasoline', 501, 750, 0.12, 0.15, 'Very large motorcycles 501-750cc'),
('motorcycle', 'gasoline', 751, 9999, 0.15, 0.20, 'Super large motorcycles over 750cc');

-- Diesel cars (typically higher CC)
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) VALUES
('car', 'diesel', 1500, 2500, 0.18, 0.24, 'Diesel cars 1500-2500cc'),
('car', 'diesel', 2501, 9999, 0.24, 0.35, 'Large diesel cars over 2500cc');

-- Electric vehicles (zero direct emissions)
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) VALUES
('car', 'electric', 0, 9999, 0.00, 0.00, 'Electric cars (zero direct emissions)'),
('motorcycle', 'electric', 0, 9999, 0.00, 0.00, 'Electric motorcycles (zero direct emissions)');

-- Hybrid vehicles (reduced emissions)
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) VALUES
('car', 'hybrid', 1000, 2000, 0.08, 0.12, 'Hybrid cars 1000-2000cc'),
('car', 'hybrid', 2001, 9999, 0.12, 0.18, 'Large hybrid cars over 2000cc');

-- =====================================================
-- 9. UPDATE COMMUNITIES PRICES TO AFFORDABLE RATES
-- =====================================================

-- Update existing communities with new affordable prices (if communities table exists)
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'communities') THEN
    UPDATE public.communities SET 
      carbon_price_per_kg = CASE 
        WHEN name LIKE '%Bogor%' THEN 5000.00
        WHEN name LIKE '%Bali%' THEN 6000.00
        WHEN name LIKE '%Surabaya%' THEN 4500.00
        WHEN name LIKE '%Yogyakarta%' THEN 5500.00
        WHEN name LIKE '%Jakarta%' THEN 5200.00
        ELSE 5000.00 -- Default price for any other communities
      END,
      updated_at = NOW()
    WHERE is_active = TRUE;
  END IF;
END $$;

-- =====================================================
-- 10. CREATE ESSENTIAL FUNCTIONS
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
    COALESCE(SUM(COALESCE(distance_km, distance)), 0) as total_distance,
    COALESCE(SUM(COALESCE(co2_emission, emission)), 0) as total_emissions
  INTO v_monthly_stats
  FROM public.trip_history
  WHERE user_id = p_user_id
    AND EXTRACT(MONTH FROM COALESCE(trip_date, created_at)) = v_current_month
    AND EXTRACT(YEAR FROM COALESCE(trip_date, created_at)) = v_current_year;
  
  -- Calculate yearly statistics
  SELECT 
    COUNT(*) as trip_count,
    COALESCE(SUM(COALESCE(distance_km, distance)), 0) as total_distance,
    COALESCE(SUM(COALESCE(co2_emission, emission)), 0) as total_emissions
  INTO v_yearly_stats
  FROM public.trip_history
  WHERE user_id = p_user_id
    AND EXTRACT(YEAR FROM COALESCE(trip_date, created_at)) = v_current_year;
  
  -- Calculate total statistics
  SELECT 
    COUNT(*) as trip_count,
    COALESCE(SUM(COALESCE(distance_km, distance)), 0) as total_distance,
    COALESCE(SUM(COALESCE(co2_emission, emission)), 0) as total_emissions
  INTO v_total_stats
  FROM public.trip_history
  WHERE user_id = p_user_id;
  
  -- Calculate offset statistics (if donations table exists)
  BEGIN
    SELECT 
      COALESCE(SUM(carbon_amount), 0) as total_offset,
      COALESCE(SUM(COALESCE(tree_count, FLOOR(amount / 10000))), 0) as trees_planted
    INTO v_offset_stats
    FROM public.donations
    WHERE user_id = p_user_id AND payment_status = 'success';
  EXCEPTION
    WHEN undefined_table THEN
      v_offset_stats.total_offset := 0;
      v_offset_stats.trees_planted := 0;
  END;
  
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
-- 11. ENABLE ROW LEVEL SECURITY FOR NEW TABLES
-- =====================================================

-- OTP table (no direct access)
ALTER TABLE public.auth_otps ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "otp_no_direct_access" ON public.auth_otps;
CREATE POLICY "otp_no_direct_access" ON public.auth_otps FOR ALL USING (FALSE);

-- Vehicle emission factors (public read)
ALTER TABLE public.vehicle_emission_factors ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "emission_factors_public_read" ON public.vehicle_emission_factors;
CREATE POLICY "emission_factors_public_read" ON public.vehicle_emission_factors FOR SELECT USING (TRUE);

-- Tracking summary
ALTER TABLE public.tracking_summary ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "tracking_select_own" ON public.tracking_summary;
DROP POLICY IF EXISTS "tracking_insert_own" ON public.tracking_summary;
DROP POLICY IF EXISTS "tracking_update_own" ON public.tracking_summary;

CREATE POLICY "tracking_select_own" ON public.tracking_summary FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "tracking_insert_own" ON public.tracking_summary FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "tracking_update_own" ON public.tracking_summary FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- 12. CREATE TRIGGERS FOR NEW TABLES
-- =====================================================

-- Tracking summary table trigger
DROP TRIGGER IF EXISTS update_tracking_summary_updated_at ON public.tracking_summary;
CREATE TRIGGER update_tracking_summary_updated_at
  BEFORE UPDATE ON public.tracking_summary
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 13. VERIFY INCREMENTAL UPDATE
-- =====================================================

-- Check all tables exist
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('users', 'trip_history', 'communities', 'donations', 'notifications', 'notification_preferences', 'auth_otps', 'vehicle_emission_factors', 'tracking_summary')
ORDER BY table_name;

-- Check emission factors data
SELECT vehicle_type, fuel_type, COUNT(*) as factor_count FROM public.vehicle_emission_factors GROUP BY vehicle_type, fuel_type ORDER BY vehicle_type, fuel_type;

-- Test emission calculation
SELECT calculate_trip_emission(25.5, 'car', 1500, 'gasoline') as test_calculation;

-- =====================================================
-- INCREMENTAL UPDATE COMPLETE!
-- =====================================================
-- Added:
-- ✅ Missing columns to existing tables
-- ✅ OTP authentication system
-- ✅ Vehicle emission factors with CC-based calculation
-- ✅ Tracking summary system
-- ✅ Essential functions for emission calculation
-- ✅ Security policies for new tables
-- ✅ Updated community prices
-- =====================================================