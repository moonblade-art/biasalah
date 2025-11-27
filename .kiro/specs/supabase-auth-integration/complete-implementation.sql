-- ============================================
-- COMPLETE SUPABASE IMPLEMENTATION FOR ECOTRACK
-- ============================================
-- This script includes all necessary tables, functions, and policies
-- for the complete EcoTrack application with donation and notification features

-- ============================================
-- 1. CREATE EXTENSION AND HELPER FUNCTIONS
-- ============================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================
-- 2. CREATE USERS TABLE (Enhanced)
-- ============================================

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  emisi_offset DECIMAL(10, 2) DEFAULT 0.00,
  emisi_belum DECIMAL(10, 2) DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_users_user_id ON public.users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Add comments
COMMENT ON TABLE public.users IS 'User profiles with carbon emission tracking';
COMMENT ON COLUMN public.users.emisi_offset IS 'Carbon emissions that have been offset (kg CO2)';
COMMENT ON COLUMN public.users.emisi_belum IS 'Carbon emissions not yet offset (kg CO2)';

-- ============================================
-- 3. CREATE TRIP HISTORY TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.trip_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  vehicle_type TEXT NOT NULL,
  fuel_type TEXT,
  distance DECIMAL(10, 2) NOT NULL,
  carbon_emission DECIMAL(10, 2) NOT NULL,
  trip_date DATE DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_trip_history_user_id ON public.trip_history(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_history_date ON public.trip_history(trip_date);

-- Add comments
COMMENT ON TABLE public.trip_history IS 'User trip history with carbon emission calculations';

-- ============================================
-- 4. CREATE COMMUNITIES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.communities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  location TEXT,
  focus_area TEXT, -- 'reforestation', 'renewable_energy', 'waste_management', etc.
  carbon_price_per_kg DECIMAL(10, 2) DEFAULT 5000.00, -- Harga per kg CO2 dalam Rupiah
  total_donations DECIMAL(15, 2) DEFAULT 0.00,
  total_carbon_offset DECIMAL(10, 2) DEFAULT 0.00,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_communities_active ON public.communities(is_active);
CREATE INDEX IF NOT EXISTS idx_communities_focus ON public.communities(focus_area);

-- Add comments
COMMENT ON TABLE public.communities IS 'Communities available for carbon offset donations';
COMMENT ON COLUMN public.communities.carbon_price_per_kg IS 'Price per kg CO2 in Indonesian Rupiah';

-- ============================================
-- 5. CREATE DONATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.donations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  community_id UUID REFERENCES public.communities(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(15, 2) NOT NULL, -- Jumlah donasi dalam Rupiah
  carbon_amount DECIMAL(10, 2) NOT NULL, -- Jumlah karbon yang di-offset dalam kg
  payment_method TEXT NOT NULL, -- 'midtrans', 'bank_transfer', etc.
  payment_status TEXT DEFAULT 'pending', -- 'pending', 'success', 'failed', 'cancelled'
  transaction_id TEXT UNIQUE, -- ID transaksi dari payment gateway
  midtrans_order_id TEXT UNIQUE, -- Order ID dari Midtrans
  payment_url TEXT, -- URL pembayaran dari Midtrans
  notes TEXT,
  donated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  paid_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_donations_user_id ON public.donations(user_id);
CREATE INDEX IF NOT EXISTS idx_donations_community_id ON public.donations(community_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON public.donations(payment_status);
CREATE INDEX IF NOT EXISTS idx_donations_transaction_id ON public.donations(transaction_id);
CREATE INDEX IF NOT EXISTS idx_donations_date ON public.donations(donated_at);

-- Add comments
COMMENT ON TABLE public.donations IS 'Carbon offset donations made by users';
COMMENT ON COLUMN public.donations.amount IS 'Donation amount in Indonesian Rupiah';
COMMENT ON COLUMN public.donations.carbon_amount IS 'Amount of CO2 offset in kg';

-- ============================================
-- 6. CREATE NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL, -- 'trip_completed', 'donation_success', 'profile_updated', 'weekly_reminder'
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB, -- Additional data for the notification
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON public.notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_date ON public.notifications(created_at);

-- Add comments
COMMENT ON TABLE public.notifications IS 'User notifications for various app events';
COMMENT ON COLUMN public.notifications.data IS 'Additional JSON data for the notification';

-- ============================================
-- 7. CREATE NOTIFICATION PREFERENCES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.notification_preferences (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  trip_notifications BOOLEAN DEFAULT TRUE,
  donation_notifications BOOLEAN DEFAULT TRUE,
  profile_notifications BOOLEAN DEFAULT TRUE,
  weekly_reminders BOOLEAN DEFAULT TRUE,
  push_notifications BOOLEAN DEFAULT TRUE,
  email_notifications BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_notification_prefs_user_id ON public.notification_preferences(user_id);

-- Add comments
COMMENT ON TABLE public.notification_preferences IS 'User preferences for different types of notifications';

-- ============================================
-- 8. ENABLE ROW LEVEL SECURITY
-- ============================================

-- Users table
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;

CREATE POLICY "Users can read own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own profile"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Trip history table
ALTER TABLE public.trip_history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own trips" ON public.trip_history;

CREATE POLICY "Users can manage own trips"
  ON public.trip_history
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Communities (public read, admin write)
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Communities are publicly readable" ON public.communities;
CREATE POLICY "Communities are publicly readable"
  ON public.communities
  FOR SELECT
  USING (is_active = TRUE);

-- Donations (users can read/write their own)
ALTER TABLE public.donations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own donations" ON public.donations;
DROP POLICY IF EXISTS "Users can insert own donations" ON public.donations;
DROP POLICY IF EXISTS "Users can update own donations" ON public.donations;

CREATE POLICY "Users can read own donations"
  ON public.donations
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own donations"
  ON public.donations
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own donations"
  ON public.donations
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Notifications (users can read/write their own)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;

CREATE POLICY "Users can read own notifications"
  ON public.notifications
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications"
  ON public.notifications
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Notification preferences (users can read/write their own)
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own notification preferences" ON public.notification_preferences;

CREATE POLICY "Users can manage own notification preferences"
  ON public.notification_preferences
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 9. CREATE TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ============================================

-- Users
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Trip history
DROP TRIGGER IF EXISTS update_trip_history_updated_at ON public.trip_history;
CREATE TRIGGER update_trip_history_updated_at
  BEFORE UPDATE ON public.trip_history
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Communities
DROP TRIGGER IF EXISTS update_communities_updated_at ON public.communities;
CREATE TRIGGER update_communities_updated_at
  BEFORE UPDATE ON public.communities
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Donations
DROP TRIGGER IF EXISTS update_donations_updated_at ON public.donations;
CREATE TRIGGER update_donations_updated_at
  BEFORE UPDATE ON public.donations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Notification preferences
DROP TRIGGER IF EXISTS update_notification_prefs_updated_at ON public.notification_preferences;
CREATE TRIGGER update_notification_prefs_updated_at
  BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 10. CREATE FUNCTIONS FOR BUSINESS LOGIC
-- ============================================

-- Function to process successful donation
CREATE OR REPLACE FUNCTION process_successful_donation(
  p_donation_id UUID,
  p_transaction_id TEXT
)
RETURNS VOID AS $$
DECLARE
  v_donation RECORD;
  v_user_id UUID;
  v_carbon_amount DECIMAL(10, 2);
  v_community_name TEXT;
BEGIN
  -- Get donation details
  SELECT d.*, c.name as community_name
  INTO v_donation
  FROM public.donations d
  JOIN public.communities c ON d.community_id = c.id
  WHERE d.id = p_donation_id;
  
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Donation not found';
  END IF;
  
  -- Update donation status
  UPDATE public.donations
  SET 
    payment_status = 'success',
    transaction_id = p_transaction_id,
    paid_at = NOW()
  WHERE id = p_donation_id;
  
  -- Update user's offset emissions
  UPDATE public.users
  SET 
    emisi_offset = emisi_offset + v_donation.carbon_amount,
    emisi_belum = GREATEST(0, emisi_belum - v_donation.carbon_amount)
  WHERE user_id = v_donation.user_id;
  
  -- Update community totals
  UPDATE public.communities
  SET 
    total_donations = total_donations + v_donation.amount,
    total_carbon_offset = total_carbon_offset + v_donation.carbon_amount
  WHERE id = v_donation.community_id;
  
  -- Create notification
  INSERT INTO public.notifications (user_id, type, title, message, data)
  VALUES (
    v_donation.user_id,
    'donation_success',
    'Donasi Berhasil!',
    'Donasi Anda sebesar Rp ' || TO_CHAR(v_donation.amount, 'FM999,999,999') || ' untuk ' || v_donation.community_name || ' telah berhasil diproses.',
    jsonb_build_object(
      'donation_id', p_donation_id,
      'amount', v_donation.amount,
      'carbon_amount', v_donation.carbon_amount,
      'community_name', v_donation.community_name
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

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
  -- Check user notification preferences
  SELECT * INTO v_preferences
  FROM public.notification_preferences
  WHERE user_id = p_user_id;
  
  -- Create default preferences if not exists
  IF NOT FOUND THEN
    INSERT INTO public.notification_preferences (user_id)
    VALUES (p_user_id);
    v_preferences.trip_notifications := TRUE;
    v_preferences.donation_notifications := TRUE;
    v_preferences.profile_notifications := TRUE;
    v_preferences.weekly_reminders := TRUE;
  END IF;
  
  -- Check if user wants this type of notification
  IF (p_type = 'trip_completed' AND NOT v_preferences.trip_notifications) OR
     (p_type = 'donation_success' AND NOT v_preferences.donation_notifications) OR
     (p_type = 'profile_updated' AND NOT v_preferences.profile_notifications) OR
     (p_type = 'weekly_reminder' AND NOT v_preferences.weekly_reminders) THEN
    RETURN NULL; -- Don't create notification if user disabled it
  END IF;
  
  -- Create notification
  INSERT INTO public.notifications (user_id, type, title, message, data)
  VALUES (p_user_id, p_type, p_title, p_message, p_data)
  RETURNING id INTO v_notification_id;
  
  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add trip and update emissions
CREATE OR REPLACE FUNCTION add_trip_and_update_emissions(
  p_user_id UUID,
  p_vehicle_type TEXT,
  p_fuel_type TEXT,
  p_distance DECIMAL(10, 2),
  p_carbon_emission DECIMAL(10, 2),
  p_notes TEXT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
  v_trip_id UUID;
BEGIN
  -- Insert trip history
  INSERT INTO public.trip_history (
    user_id, vehicle_type, fuel_type, distance, carbon_emission, notes
  )
  VALUES (
    p_user_id, p_vehicle_type, p_fuel_type, p_distance, p_carbon_emission, p_notes
  )
  RETURNING id INTO v_trip_id;
  
  -- Update user's unoffset emissions
  UPDATE public.users
  SET emisi_belum = emisi_belum + p_carbon_emission
  WHERE user_id = p_user_id;
  
  -- Create notification
  PERFORM create_notification(
    p_user_id,
    'trip_completed',
    'Perjalanan Tercatat!',
    'Perjalanan Anda menghasilkan ' || p_carbon_emission || ' kg CO₂. Yuk offset dengan donasi!',
    jsonb_build_object(
      'trip_id', v_trip_id,
      'carbon_emission', p_carbon_emission,
      'vehicle_type', p_vehicle_type,
      'distance', p_distance
    )
  );
  
  RETURN v_trip_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to send weekly reminders
CREATE OR REPLACE FUNCTION send_weekly_reminders()
RETURNS INTEGER AS $$
DECLARE
  v_user RECORD;
  v_count INTEGER := 0;
  v_days_without_tracking INTEGER;
BEGIN
  -- Find users who haven't tracked in the last 7 days
  FOR v_user IN
    SELECT DISTINCT u.user_id, u.full_name
    FROM public.users u
    LEFT JOIN public.trip_history th ON u.user_id = th.user_id 
      AND th.created_at > NOW() - INTERVAL '7 days'
    WHERE th.id IS NULL
  LOOP
    -- Calculate days without tracking
    SELECT COALESCE(
      EXTRACT(DAY FROM NOW() - MAX(th.created_at))::INTEGER,
      30
    ) INTO v_days_without_tracking
    FROM public.trip_history th
    WHERE th.user_id = v_user.user_id;
    
    -- Create reminder notification
    PERFORM create_notification(
      v_user.user_id,
      'weekly_reminder',
      'Jangan Lupa Tracking!',
      'Sudah ' || v_days_without_tracking || ' hari tidak ada tracking perjalanan. Yuk mulai tracking lagi!',
      jsonb_build_object(
        'days_without_tracking', v_days_without_tracking
      )
    );
    
    v_count := v_count + 1;
  END LOOP;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 11. CREATE VIEWS FOR REPORTING
-- ============================================

-- View for user donation summary
CREATE OR REPLACE VIEW user_donation_summary AS
SELECT 
  u.user_id,
  u.full_name,
  u.email,
  COUNT(d.id) as total_donations,
  COALESCE(SUM(d.amount), 0) as total_amount_donated,
  COALESCE(SUM(d.carbon_amount), 0) as total_carbon_offset_donated,
  u.emisi_offset,
  u.emisi_belum
FROM public.users u
LEFT JOIN public.donations d ON u.user_id = d.user_id AND d.payment_status = 'success'
GROUP BY u.user_id, u.full_name, u.email, u.emisi_offset, u.emisi_belum;

-- View for community statistics
CREATE OR REPLACE VIEW community_statistics AS
SELECT 
  c.id,
  c.name,
  c.location,
  c.focus_area,
  c.carbon_price_per_kg,
  COUNT(d.id) as total_donations_count,
  COALESCE(SUM(d.amount), 0) as total_amount_received,
  COALESCE(SUM(d.carbon_amount), 0) as total_carbon_offset,
  c.is_active
FROM public.communities c
LEFT JOIN public.donations d ON c.id = d.community_id AND d.payment_status = 'success'
GROUP BY c.id, c.name, c.location, c.focus_area, c.carbon_price_per_kg, c.is_active;

-- ============================================
-- 12. INSERT SAMPLE DATA
-- ============================================

-- Insert sample communities
INSERT INTO public.communities (name, description, image_url, location, focus_area, carbon_price_per_kg) VALUES
('Hutan Lindung Bogor', 'Program penanaman pohon dan konservasi hutan di kawasan Bogor untuk menyerap CO2', 'https://example.com/forest1.jpg', 'Bogor, Jawa Barat', 'reforestation', 5000.00),
('Energi Surya Bali', 'Pengembangan panel surya untuk mengurangi emisi dari energi fosil', 'https://example.com/solar1.jpg', 'Bali', 'renewable_energy', 6000.00),
('Mangrove Surabaya', 'Restorasi hutan mangrove untuk penyerapan karbon dan perlindungan pantai', 'https://example.com/mangrove1.jpg', 'Surabaya, Jawa Timur', 'reforestation', 4500.00),
('Biogas Yogyakarta', 'Konversi limbah organik menjadi biogas untuk mengurangi emisi metana', 'https://example.com/biogas1.jpg', 'Yogyakarta', 'waste_management', 5500.00),
('Hutan Kota Jakarta', 'Pengembangan ruang terbuka hijau di Jakarta untuk kualitas udara yang lebih baik', 'https://example.com/urban_forest1.jpg', 'Jakarta', 'reforestation', 5200.00)
ON CONFLICT DO NOTHING;

-- ============================================
-- 13. SETUP COMPLETE VERIFICATION
-- ============================================

-- Check if all tables exist
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name AND table_schema = 'public') as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('users', 'trip_history', 'communities', 'donations', 'notifications', 'notification_preferences')
ORDER BY table_name;

-- Check sample communities data
SELECT name, location, focus_area, carbon_price_per_kg FROM public.communities WHERE is_active = TRUE;

-- ============================================
-- IMPLEMENTATION COMPLETE!
-- ============================================
-- This script provides:
-- 1. Complete database schema with all necessary tables
-- 2. Row Level Security policies for data protection
-- 3. Business logic functions for donations and notifications
-- 4. Triggers for automatic timestamp updates
-- 5. Views for reporting and analytics
-- 6. Sample data for testing
-- ============================================