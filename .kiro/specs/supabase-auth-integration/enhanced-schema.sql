-- ============================================
-- ENHANCED SUPABASE DATABASE SCHEMA FOR ECOTRACK
-- ============================================
-- Enhanced schema dengan fitur donasi dan notifikasi

-- ============================================
-- 1. EXISTING TABLES (from previous schema)
-- ============================================
-- users table dan trip_history sudah ada dari schema sebelumnya

-- ============================================
-- 2. CREATE COMMUNITIES TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.communities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  location TEXT,
  focus_area TEXT, -- 'reforestation', 'renewable_energy', 'waste_management', etc.
  carbon_price_per_kg DECIMAL(10, 2) DEFAULT 5000.00, -- Harga per kg CO2 dalam Rupiah (mulai dari 5.000)
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
-- 3. CREATE DONATIONS TABLE
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
-- 4. CREATE NOTIFICATIONS TABLE
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
-- 5. CREATE NOTIFICATION PREFERENCES TABLE
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
-- 6. ENABLE ROW LEVEL SECURITY
-- ============================================

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
-- 7. CREATE TRIGGERS FOR AUTO-UPDATE TIMESTAMPS
-- ============================================

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
-- 8. CREATE FUNCTIONS FOR DONATION PROCESSING
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

-- ============================================
-- 9. INSERT SAMPLE COMMUNITIES DATA
-- ============================================

INSERT INTO public.communities (name, description, image_url, location, focus_area, carbon_price_per_kg) VALUES
('Hutan Lindung Bogor', 'Program penanaman pohon dan konservasi hutan di kawasan Bogor untuk menyerap CO2', 'https://example.com/forest1.jpg', 'Bogor, Jawa Barat', 'reforestation', 5000.00),
('Energi Surya Bali', 'Pengembangan panel surya untuk mengurangi emisi dari energi fosil', 'https://example.com/solar1.jpg', 'Bali', 'renewable_energy', 6000.00),
('Mangrove Surabaya', 'Restorasi hutan mangrove untuk penyerapan karbon dan perlindungan pantai', 'https://example.com/mangrove1.jpg', 'Surabaya, Jawa Timur', 'reforestation', 4500.00),
('Biogas Yogyakarta', 'Konversi limbah organik menjadi biogas untuk mengurangi emisi metana', 'https://example.com/biogas1.jpg', 'Yogyakarta', 'waste_management', 5500.00),
('Hutan Kota Jakarta', 'Pengembangan ruang terbuka hijau di Jakarta untuk kualitas udara yang lebih baik', 'https://example.com/urban_forest1.jpg', 'Jakarta', 'urban_forest', 5200.00),
('Konservasi Laut Lombok', 'Program perlindungan terumbu karang dan ekosistem laut untuk penyerapan karbon biru', 'https://example.com/ocean1.jpg', 'Lombok, NTB', 'ocean_conservation', 4800.00),
('Daur Ulang Bandung', 'Program pengelolaan sampah dan daur ulang untuk mengurangi emisi dari TPA', 'https://example.com/recycle1.jpg', 'Bandung, Jawa Barat', 'waste_management', 4700.00),
('Hutan Rakyat Malang', 'Pemberdayaan masyarakat dalam pengelolaan hutan berkelanjutan', 'https://example.com/forest2.jpg', 'Malang, Jawa Timur', 'reforestation', 4900.00);

-- ============================================
-- 10. CREATE VIEWS FOR REPORTING
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
-- 11. VERIFY ENHANCED SETUP
-- ============================================

-- Check if all tables exist
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('users', 'trip_history', 'communities', 'donations', 'notifications', 'notification_preferences')
ORDER BY table_name;

-- Check sample communities data
SELECT name, location, focus_area, carbon_price_per_kg FROM public.communities WHERE is_active = TRUE;

-- ============================================
-- ENHANCED SETUP COMPLETE!
-- ============================================
-- Features added:
-- 1. Communities for carbon offset donations
-- 2. Donations with Midtrans payment integration
-- 3. Notifications system with preferences
-- 4. Functions for donation processing
-- 5. Views for reporting and statistics
-- ============================================