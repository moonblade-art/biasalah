-- =====================================================
-- ECOTRACK COMPLETE DATABASE SCHEMA FOR SUPABASE
-- =====================================================
-- Includes: Communities, Donations, Tracking, OTP Auth, Emission Factors
-- Version: 2.0
-- Date: December 2024

-- =====================================================
-- 1. ENABLE EXTENSIONS
-- =====================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =====================================================
-- 2. CREATE HELPER FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- 3. USERS TABLE (Enhanced)
-- =====================================================

-- Drop existing users table if exists and recreate with all needed fields
DROP TABLE IF EXISTS public.users CASCADE;

CREATE TABLE public.users (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  profile_photo_url TEXT,
  date_of_birth DATE,
  gender TEXT CHECK (gender IN ('male', 'female', 'other')),
  address TEXT,
  city TEXT,
  province TEXT,
  
  -- Carbon tracking fields
  emisi_offset DECIMAL(10, 2) DEFAULT 0.00, -- CO2 yang sudah di-offset (kg)
  emisi_belum DECIMAL(10, 2) DEFAULT 0.00,  -- CO2 yang belum di-offset (kg)
  total_distance DECIMAL(10, 2) DEFAULT 0.00, -- Total jarak tempuh (km)
  total_trips INTEGER DEFAULT 0,
  
  -- Preferences
  preferred_vehicle_type TEXT DEFAULT 'car',
  preferred_vehicle_cc INTEGER DEFAULT 1500,
  
  -- Metadata
  is_active BOOLEAN DEFAULT TRUE,
  email_verified BOOLEAN DEFAULT FALSE,
  phone_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for users
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_phone ON public.users(phone);
CREATE INDEX idx_users_active ON public.users(is_active);

-- =====================================================
-- 4. OTP AUTHENTICATION TABLE
-- =====================================================

CREATE TABLE public.auth_otps (
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
CREATE INDEX idx_auth_otps_identifier ON public.auth_otps(identifier);
CREATE INDEX idx_auth_otps_code ON public.auth_otps(otp_code);
CREATE INDEX idx_auth_otps_expires ON public.auth_otps(expires_at);

-- =====================================================
-- 5. VEHICLE EMISSION FACTORS TABLE
-- =====================================================

CREATE TABLE public.vehicle_emission_factors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('car', 'motorcycle', 'bicycle')),
  fuel_type TEXT NOT NULL CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid', 'human')),
  cc_min INTEGER NOT NULL,
  cc_max INTEGER,
  emission_factor_min DECIMAL(6, 4) NOT NULL, -- kg CO2 per km (minimum)
  emission_factor_max DECIMAL(6, 4) NOT NULL, -- kg CO2 per km (maximum)
  emission_factor_avg DECIMAL(6, 4) GENERATED ALWAYS AS ((emission_factor_min + emission_factor_max) / 2) STORED,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for emission factors
CREATE INDEX idx_emission_factors_vehicle_type ON public.vehicle_emission_factors(vehicle_type);
CREATE INDEX idx_emission_factors_cc_range ON public.vehicle_emission_factors(cc_min, cc_max);

-- =====================================================
-- 6. TRIP HISTORY TABLE (Enhanced)
-- =====================================================

CREATE TABLE public.trip_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(user_id) ON DELETE CASCADE NOT NULL,
  
  -- Trip details
  start_location TEXT,
  end_location TEXT,
  start_latitude DECIMAL(10, 8),
  start_longitude DECIMAL(11, 8),
  end_latitude DECIMAL(10, 8),
  end_longitude DECIMAL(11, 8),
  distance_km DECIMAL(10, 2) NOT NULL,
  
  -- Vehicle information
  vehicle_type TEXT NOT NULL CHECK (vehicle_type IN ('car', 'motorcycle', 'bicycle')),
  vehicle_cc INTEGER NOT NULL,
  fuel_type TEXT DEFAULT 'gasoline' CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid', 'human')),
  
  -- Emission calculation
  emission_factor DECIMAL(6, 4) NOT NULL, -- kg CO2 per km used for this trip
  co2_emission DECIMAL(10, 2) NOT NULL, -- Total CO2 emission for this trip (kg)
  
  -- Trip metadata
  trip_date DATE NOT NULL DEFAULT CURRENT_DATE,
  trip_duration_minutes INTEGER,
  notes TEXT,
  
  -- Status
  is_offset BOOLEAN DEFAULT FALSE, -- Whether this trip's emission has been offset
  offset_date TIMESTAMP WITH TIME ZONE,
  offset_donation_id UUID, -- Reference to donation that offset this trip
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for trip history
CREATE INDEX idx_trip_history_user_id ON public.trip_history(user_id);
CREATE INDEX idx_trip_history_date ON public.trip_history(trip_date);
CREATE INDEX idx_trip_history_vehicle ON public.trip_history(vehicle_type, vehicle_cc);
CREATE INDEX idx_trip_history_offset ON public.trip_history(is_offset);

-- =====================================================
-- 7. COMMUNITIES TABLE
-- =====================================================

CREATE TABLE public.communities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  location TEXT NOT NULL,
  focus_area TEXT NOT NULL CHECK (focus_area IN (
    'reforestation', 'renewable_energy', 'waste_management', 
    'ocean_conservation', 'urban_forest', 'agriculture'
  )),
  
  -- Pricing
  carbon_price_per_kg DECIMAL(10, 2) NOT NULL DEFAULT 10000.00, -- Rp per kg CO2
  
  -- Statistics
  total_donations DECIMAL(15, 2) DEFAULT 0.00,
  total_carbon_offset DECIMAL(12, 2) DEFAULT 0.00,
  total_trees_planted INTEGER DEFAULT 0,
  
  -- Contact & Details
  contact_person TEXT,
  contact_phone TEXT,
  contact_email TEXT,
  website_url TEXT,
  
  -- Status
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for communities
CREATE INDEX idx_communities_active ON public.communities(is_active);
CREATE INDEX idx_communities_focus ON public.communities(focus_area);
CREATE INDEX idx_communities_featured ON public.communities(is_featured);
CREATE INDEX idx_communities_location ON public.communities(location);

-- =====================================================
-- 8. DONATIONS TABLE
-- =====================================================

CREATE TABLE public.donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(user_id) ON DELETE CASCADE NOT NULL,
  community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE NOT NULL,
  
  -- Donation amounts
  amount DECIMAL(15, 2) NOT NULL, -- Donation amount in Rupiah
  carbon_amount DECIMAL(10, 2) NOT NULL, -- CO2 offset amount in kg
  tree_count INTEGER GENERATED ALWAYS AS (FLOOR(amount / 10000)) STORED, -- Trees planted (1 tree = Rp 10,000)
  
  -- Payment details
  payment_method TEXT NOT NULL DEFAULT 'midtrans',
  payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN (
    'pending', 'processing', 'success', 'failed', 'cancelled', 'expired'
  )),
  
  -- Midtrans integration
  midtrans_order_id TEXT UNIQUE,
  midtrans_transaction_id TEXT,
  midtrans_payment_type TEXT,
  payment_url TEXT,
  
  -- Additional info
  donor_name TEXT, -- Optional custom donor name
  donor_message TEXT, -- Optional message from donor
  is_anonymous BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  donated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  paid_at TIMESTAMP WITH TIME ZONE,
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours'),
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for donations
CREATE INDEX idx_donations_user_id ON public.donations(user_id);
CREATE INDEX idx_donations_community_id ON public.donations(community_id);
CREATE INDEX idx_donations_status ON public.donations(payment_status);
CREATE INDEX idx_donations_midtrans_order ON public.donations(midtrans_order_id);
CREATE INDEX idx_donations_date ON public.donations(donated_at);

-- =====================================================
-- 9. TRACKING SUMMARY TABLE
-- =====================================================

CREATE TABLE public.tracking_summary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(user_id) ON DELETE CASCADE NOT NULL UNIQUE,
  
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
CREATE INDEX idx_tracking_summary_user_id ON public.tracking_summary(user_id);
CREATE INDEX idx_tracking_summary_month_year ON public.tracking_summary(current_month, current_year);

-- =====================================================
-- 10. NOTIFICATIONS TABLE
-- =====================================================

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(user_id) ON DELETE CASCADE NOT NULL,
  
  type TEXT NOT NULL CHECK (type IN (
    'trip_completed', 'donation_success', 'donation_failed', 
    'profile_updated', 'weekly_reminder', 'monthly_summary',
    'achievement_unlocked', 'community_update'
  )),
  
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB, -- Additional structured data
  
  -- Status
  is_read BOOLEAN DEFAULT FALSE,
  is_pushed BOOLEAN DEFAULT FALSE, -- Whether push notification was sent
  
  -- Scheduling
  scheduled_for TIMESTAMP WITH TIME ZONE,
  sent_at TIMESTAMP WITH TIME ZONE,
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for notifications
CREATE INDEX idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX idx_notifications_type ON public.notifications(type);
CREATE INDEX idx_notifications_read ON public.notifications(is_read);
CREATE INDEX idx_notifications_scheduled ON public.notifications(scheduled_for);

-- =====================================================
-- 11. NOTIFICATION PREFERENCES TABLE
-- =====================================================

CREATE TABLE public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.users(user_id) ON DELETE CASCADE NOT NULL UNIQUE,
  
  -- Notification types
  trip_notifications BOOLEAN DEFAULT TRUE,
  donation_notifications BOOLEAN DEFAULT TRUE,
  profile_notifications BOOLEAN DEFAULT TRUE,
  weekly_reminders BOOLEAN DEFAULT TRUE,
  monthly_summaries BOOLEAN DEFAULT TRUE,
  achievement_notifications BOOLEAN DEFAULT TRUE,
  community_updates BOOLEAN DEFAULT TRUE,
  
  -- Delivery methods
  push_notifications BOOLEAN DEFAULT TRUE,
  email_notifications BOOLEAN DEFAULT FALSE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  
  -- Quiet hours
  quiet_hours_enabled BOOLEAN DEFAULT FALSE,
  quiet_hours_start TIME DEFAULT '22:00:00',
  quiet_hours_end TIME DEFAULT '07:00:00',
  
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for notification preferences
CREATE INDEX idx_notification_prefs_user_id ON public.notification_preferences(user_id);

-- =====================================================
-- 12. INSERT VEHICLE EMISSION FACTORS DATA
-- =====================================================

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

-- Human-powered vehicles (zero emissions)
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) VALUES
('bicycle', 'human', 0, 0, 0.00, 0.00, 'Human-powered bicycles (zero emissions)');

-- =====================================================
-- 13. INSERT SAMPLE COMMUNITIES DATA
-- =====================================================

INSERT INTO public.communities (name, description, location, focus_area, carbon_price_per_kg, contact_person, contact_email) VALUES
('Mangrove Surabaya', 'Restorasi hutan mangrove untuk penyerapan karbon dan perlindungan pantai', 'Surabaya, Jawa Timur', 'reforestation', 4500.00, 'Budi Santoso', 'budi@mangrovesby.org'),
('Hutan Lindung Bogor', 'Program penanaman pohon dan konservasi hutan di kawasan Bogor untuk menyerap CO2', 'Bogor, Jawa Barat', 'reforestation', 5000.00, 'Sari Dewi', 'sari@hutanbogor.org'),
('Energi Surya Bali', 'Pengembangan panel surya untuk mengurangi emisi dari energi fosil', 'Bali', 'renewable_energy', 6000.00, 'Made Wirawan', 'made@solarbali.com'),
('Biogas Yogyakarta', 'Konversi limbah organik menjadi biogas untuk mengurangi emisi metana', 'Yogyakarta', 'waste_management', 5500.00, 'Andi Prasetyo', 'andi@biogasygk.org'),
('Hutan Kota Jakarta', 'Pengembangan ruang terbuka hijau di Jakarta untuk kualitas udara yang lebih baik', 'Jakarta', 'urban_forest', 5200.00, 'Lisa Maharani', 'lisa@hutankotajkt.id'),
('Konservasi Laut Lombok', 'Program perlindungan terumbu karang dan ekosistem laut untuk penyerapan karbon biru', 'Lombok, NTB', 'ocean_conservation', 4800.00, 'Agus Salim', 'agus@lautlombok.org'),
('Daur Ulang Bandung', 'Program pengelolaan sampah dan daur ulang untuk mengurangi emisi dari TPA', 'Bandung, Jawa Barat', 'waste_management', 4700.00, 'Rina Sari', 'rina@recyclebdg.com'),
('Hutan Rakyat Malang', 'Pemberdayaan masyarakat dalam pengelolaan hutan berkelanjutan', 'Malang, Jawa Timur', 'reforestation', 4900.00, 'Joko Widodo', 'joko@hutanmalang.org');

-- =====================================================
-- 14. CREATE TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- =====================================================

-- Users table
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trip history table
CREATE TRIGGER update_trip_history_updated_at
  BEFORE UPDATE ON public.trip_history
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Communities table
CREATE TRIGGER update_communities_updated_at
  BEFORE UPDATE ON public.communities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Donations table
CREATE TRIGGER update_donations_updated_at
  BEFORE UPDATE ON public.donations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Notification preferences table
CREATE TRIGGER update_notification_prefs_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 15. ENABLE ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read and update own profile" ON public.users
  FOR ALL USING (auth.uid() = user_id);

-- OTP table (no RLS - handled by functions)
ALTER TABLE public.auth_otps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "OTP access via functions only" ON public.auth_otps
  FOR ALL USING (FALSE); -- Only accessible via security definer functions

-- Vehicle emission factors (public read)
ALTER TABLE public.vehicle_emission_factors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Emission factors are publicly readable" ON public.vehicle_emission_factors
  FOR SELECT USING (TRUE);

-- Trip history
ALTER TABLE public.trip_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own trips" ON public.trip_history
  FOR ALL USING (auth.uid() = user_id);

-- Communities (public read)
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Communities are publicly readable" ON public.communities
  FOR SELECT USING (is_active = TRUE);

-- Donations
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own donations" ON public.donations
  FOR ALL USING (auth.uid() = user_id);

-- Tracking summary
ALTER TABLE public.tracking_summary ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own tracking summary" ON public.tracking_summary
  FOR ALL USING (auth.uid() = user_id);

-- Notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read and update own notifications" ON public.notifications
  FOR ALL USING (auth.uid() = user_id);

-- Notification preferences
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own notification preferences" ON public.notification_preferences
  FOR ALL USING (auth.uid() = user_id);

-- =====================================================
-- SCHEMA CREATION COMPLETE!
-- =====================================================
-- Next: Run the functions file for business logic
-- =====================================================