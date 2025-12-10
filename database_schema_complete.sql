-- =====================================================
-- ECOTRACK COMPLETE DATABASE SCHEMA
-- =====================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. COMMUNITIES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS communities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    image_url TEXT,
    location VARCHAR(255) NOT NULL,
    focus_area VARCHAR(100) NOT NULL CHECK (focus_area IN (
        'reforestation', 
        'renewable_energy', 
        'waste_management', 
        'ocean_conservation', 
        'urban_forest'
    )),
    carbon_price_per_kg DECIMAL(10,2) NOT NULL CHECK (carbon_price_per_kg > 0),
    total_donations DECIMAL(15,2) DEFAULT 0 CHECK (total_donations >= 0),
    total_carbon_offset DECIMAL(10,2) DEFAULT 0 CHECK (total_carbon_offset >= 0),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. USERS TABLE (Enhanced)
-- =====================================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID UNIQUE, -- Reference to Supabase auth.users
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    profile_photo_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    address TEXT,
    city VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(10),
    
    -- Carbon tracking fields
    total_emission_kg DECIMAL(10,2) DEFAULT 0 CHECK (total_emission_kg >= 0),
    total_offset_kg DECIMAL(10,2) DEFAULT 0 CHECK (total_offset_kg >= 0),
    total_donations DECIMAL(15,2) DEFAULT 0 CHECK (total_donations >= 0),
    
    -- Preferences
    preferred_vehicle_type VARCHAR(20) DEFAULT 'car' CHECK (preferred_vehicle_type IN ('car', 'motorcycle')),
    preferred_engine_cc INTEGER,
    notification_enabled BOOLEAN DEFAULT true,
    
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. DONATIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS donations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    community_id UUID NOT NULL REFERENCES communities(id) ON DELETE RESTRICT,
    
    amount DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    carbon_amount DECIMAL(10,2) NOT NULL CHECK (carbon_amount > 0),
    
    payment_method VARCHAR(50) NOT NULL DEFAULT 'midtrans',
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (payment_status IN (
        'pending', 'success', 'failed', 'cancelled'
    )),
    
    transaction_id VARCHAR(255),
    midtrans_order_id VARCHAR(255),
    payment_url TEXT,
    notes TEXT,
    
    donated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. VEHICLE EMISSION FACTORS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS vehicle_emission_factors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('car', 'motorcycle')),
    cc_min INTEGER NOT NULL CHECK (cc_min >= 0),
    cc_max INTEGER NOT NULL CHECK (cc_max >= 0), -- 0 means no upper limit
    emission_min DECIMAL(6,4) NOT NULL CHECK (emission_min > 0), -- kg CO2 per km
    emission_max DECIMAL(6,4) NOT NULL CHECK (emission_max > 0), -- kg CO2 per km
    emission_average DECIMAL(6,4) GENERATED ALWAYS AS ((emission_min + emission_max) / 2) STORED,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(vehicle_type, cc_min, cc_max)
);

-- =====================================================
-- 5. TRIP TRACKING TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS trip_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('car', 'motorcycle')),
    engine_cc INTEGER NOT NULL CHECK (engine_cc > 0),
    distance_km DECIMAL(8,2) NOT NULL CHECK (distance_km > 0),
    
    emission_kg DECIMAL(10,4) NOT NULL CHECK (emission_kg > 0),
    emission_factor DECIMAL(6,4) NOT NULL CHECK (emission_factor > 0),
    
    start_location TEXT,
    end_location TEXT,
    start_latitude DECIMAL(10,8),
    start_longitude DECIMAL(11,8),
    end_latitude DECIMAL(10,8),
    end_longitude DECIMAL(11,8),
    
    trip_date DATE NOT NULL DEFAULT CURRENT_DATE,
    trip_duration_minutes INTEGER, -- Optional: trip duration
    notes TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 6. TRACKING SUMMARY TABLE (Aggregated Data)
-- =====================================================
CREATE TABLE IF NOT EXISTS tracking_summary (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Period information
    summary_date DATE NOT NULL DEFAULT CURRENT_DATE,
    summary_type VARCHAR(20) NOT NULL DEFAULT 'daily' CHECK (summary_type IN ('daily', 'weekly', 'monthly', 'yearly')),
    
    -- Emission data
    total_trips INTEGER DEFAULT 0 CHECK (total_trips >= 0),
    total_distance_km DECIMAL(10,2) DEFAULT 0 CHECK (total_distance_km >= 0),
    total_emission_kg DECIMAL(10,2) DEFAULT 0 CHECK (total_emission_kg >= 0),
    
    -- Offset data
    total_donations DECIMAL(15,2) DEFAULT 0 CHECK (total_donations >= 0),
    total_offset_kg DECIMAL(10,2) DEFAULT 0 CHECK (total_offset_kg >= 0),
    net_emission_kg DECIMAL(10,2) GENERATED ALWAYS AS (total_emission_kg - total_offset_kg) STORED,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(user_id, summary_date, summary_type)
);

-- =====================================================
-- 7. AUTH OTP TABLE (for 6-digit OTP authentication)
-- =====================================================
CREATE TABLE IF NOT EXISTS auth_otps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    identifier VARCHAR(255) NOT NULL, -- email or phone number
    otp_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    used BOOLEAN DEFAULT false,
    attempt_count INTEGER DEFAULT 0 CHECK (attempt_count >= 0),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Index for quick lookup
    INDEX idx_auth_otps_identifier_code (identifier, otp_code),
    INDEX idx_auth_otps_expires_at (expires_at)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Communities indexes
CREATE INDEX IF NOT EXISTS idx_communities_focus_area ON communities(focus_area);
CREATE INDEX IF NOT EXISTS idx_communities_location ON communities(location);
CREATE INDEX IF NOT EXISTS idx_communities_active ON communities(is_active);

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_auth_user_id ON users(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);

-- Donations indexes
CREATE INDEX IF NOT EXISTS idx_donations_user_id ON donations(user_id);
CREATE INDEX IF NOT EXISTS idx_donations_community_id ON donations(community_id);
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(payment_status);
CREATE INDEX IF NOT EXISTS idx_donations_donated_at ON donations(donated_at);

-- Trip tracking indexes
CREATE INDEX IF NOT EXISTS idx_trip_tracking_user_id ON trip_tracking(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_tracking_trip_date ON trip_tracking(trip_date);
CREATE INDEX IF NOT EXISTS idx_trip_tracking_vehicle_type ON trip_tracking(vehicle_type);

-- Tracking summary indexes
CREATE INDEX IF NOT EXISTS idx_tracking_summary_user_date ON tracking_summary(user_id, summary_date);
CREATE INDEX IF NOT EXISTS idx_tracking_summary_type ON tracking_summary(summary_type);

-- =====================================================
-- TRIGGERS FOR UPDATED_AT
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables
CREATE TRIGGER update_communities_updated_at BEFORE UPDATE ON communities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_donations_updated_at BEFORE UPDATE ON donations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_vehicle_emission_factors_updated_at BEFORE UPDATE ON vehicle_emission_factors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trip_tracking_updated_at BEFORE UPDATE ON trip_tracking FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tracking_summary_updated_at BEFORE UPDATE ON tracking_summary FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- INSERT VEHICLE EMISSION FACTORS DATA
-- =====================================================

INSERT INTO vehicle_emission_factors (vehicle_type, cc_min, cc_max, emission_min, emission_max) VALUES
-- MOBIL BENSIN
('car', 0, 999, 0.11, 0.13),
('car', 1000, 1400, 0.13, 0.16),
('car', 1401, 2000, 0.16, 0.21),
('car', 2001, 3000, 0.21, 0.28),
('car', 3001, 0, 0.28, 0.40), -- 0 means no upper limit

-- MOTOR
('motorcycle', 0, 124, 0.04, 0.06),
('motorcycle', 125, 250, 0.06, 0.09),
('motorcycle', 251, 500, 0.09, 0.12),
('motorcycle', 501, 750, 0.12, 0.15),
('motorcycle', 751, 0, 0.15, 0.20) -- 0 means no upper limit
ON CONFLICT (vehicle_type, cc_min, cc_max) DO NOTHING;

-- =====================================================
-- INSERT SAMPLE COMMUNITIES DATA
-- =====================================================

INSERT INTO communities (name, description, location, focus_area, carbon_price_per_kg, total_donations, total_carbon_offset) VALUES
('Mangrove Surabaya', 'Restorasi hutan mangrove untuk penyerapan karbon dan perlindungan pantai', 'Surabaya, Jawa Timur', 'reforestation', 4500, 0, 0),
('Hutan Lindung Bogor', 'Program penanaman pohon dan konservasi hutan di kawasan Bogor untuk menyerap CO2', 'Bogor, Jawa Barat', 'reforestation', 5000, 0, 0),
('Solar Panel Desa NTT', 'Instalasi panel surya untuk desa-desa terpencil di Nusa Tenggara Timur', 'Nusa Tenggara Timur', 'renewable_energy', 6000, 0, 0),
('Bank Sampah Jakarta', 'Program pengelolaan sampah berbasis komunitas di Jakarta', 'DKI Jakarta', 'waste_management', 3500, 0, 0),
('Konservasi Terumbu Karang Bali', 'Pelestarian terumbu karang di perairan Bali', 'Bali', 'ocean_conservation', 5500, 0, 0),
('Taman Kota Hijau Surabaya', 'Pengembangan ruang terbuka hijau di perkotaan Surabaya', 'Surabaya, Jawa Timur', 'urban_forest', 4000, 0, 0)
ON CONFLICT DO NOTHING;

-- =====================================================
-- STORED PROCEDURES
-- =====================================================

-- Function to calculate emission based on vehicle type and CC
CREATE OR REPLACE FUNCTION calculate_emission(
    p_vehicle_type VARCHAR(20),
    p_engine_cc INTEGER,
    p_distance_km DECIMAL(8,2)
)
RETURNS DECIMAL(10,4) AS $$
DECLARE
    emission_factor DECIMAL(6,4);
    total_emission DECIMAL(10,4);
BEGIN
    -- Get emission factor
    SELECT emission_average INTO emission_factor
    FROM vehicle_emission_factors
    WHERE vehicle_type = p_vehicle_type
    AND p_engine_cc >= cc_min
    AND (cc_max = 0 OR p_engine_cc <= cc_max)
    LIMIT 1;
    
    IF emission_factor IS NULL THEN
        RAISE EXCEPTION 'No emission factor found for vehicle type % with %cc', p_vehicle_type, p_engine_cc;
    END IF;
    
    -- Calculate total emission
    total_emission := emission_factor * p_distance_km;
    
    RETURN total_emission;
END;
$$ LANGUAGE plpgsql;

-- Function to update tracking summary
CREATE OR REPLACE FUNCTION update_tracking_summary(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- Update daily summary
    INSERT INTO tracking_summary (
        user_id, 
        summary_date, 
        summary_type,
        total_trips,
        total_distance_km,
        total_emission_kg,
        total_donations,
        total_offset_kg
    )
    SELECT 
        p_user_id,
        CURRENT_DATE,
        'daily',
        COUNT(tt.id),
        COALESCE(SUM(tt.distance_km), 0),
        COALESCE(SUM(tt.emission_kg), 0),
        COALESCE(SUM(d.amount), 0),
        COALESCE(SUM(d.carbon_amount), 0)
    FROM trip_tracking tt
    LEFT JOIN donations d ON d.user_id = p_user_id AND d.payment_status = 'success'
    WHERE tt.user_id = p_user_id 
    AND tt.trip_date = CURRENT_DATE
    ON CONFLICT (user_id, summary_date, summary_type)
    DO UPDATE SET
        total_trips = EXCLUDED.total_trips,
        total_distance_km = EXCLUDED.total_distance_km,
        total_emission_kg = EXCLUDED.total_emission_kg,
        total_donations = EXCLUDED.total_donations,
        total_offset_kg = EXCLUDED.total_offset_kg,
        updated_at = NOW();
        
    -- Update user totals
    UPDATE users SET
        total_emission_kg = (
            SELECT COALESCE(SUM(emission_kg), 0) 
            FROM trip_tracking 
            WHERE user_id = p_user_id
        ),
        total_offset_kg = (
            SELECT COALESCE(SUM(carbon_amount), 0) 
            FROM donations 
            WHERE user_id = p_user_id AND payment_status = 'success'
        ),
        total_donations = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM donations 
            WHERE user_id = p_user_id AND payment_status = 'success'
        ),
        updated_at = NOW()
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- Function to process successful donation
CREATE OR REPLACE FUNCTION process_successful_donation(p_donation_id UUID)
RETURNS VOID AS $$
DECLARE
    donation_record donations%ROWTYPE;
BEGIN
    -- Get donation details
    SELECT * INTO donation_record FROM donations WHERE id = p_donation_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Donation not found: %', p_donation_id;
    END IF;
    
    -- Update community totals
    UPDATE communities SET
        total_donations = total_donations + donation_record.amount,
        total_carbon_offset = total_carbon_offset + donation_record.carbon_amount,
        updated_at = NOW()
    WHERE id = donation_record.community_id;
    
    -- Update tracking summary
    PERFORM update_tracking_summary(donation_record.user_id);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC CALCULATIONS
-- =====================================================

-- Trigger to update tracking summary when trip is added/updated
CREATE OR REPLACE FUNCTION trigger_update_tracking_summary()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM update_tracking_summary(NEW.user_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trip_tracking_summary_trigger
    AFTER INSERT OR UPDATE ON trip_tracking
    FOR EACH ROW EXECUTE FUNCTION trigger_update_tracking_summary();

-- Trigger to process successful donations
CREATE OR REPLACE FUNCTION trigger_process_donation()
RETURNS TRIGGER AS $$
BEGIN
    -- Only process when status changes to success
    IF NEW.payment_status = 'success' AND (OLD IS NULL OR OLD.payment_status != 'success') THEN
        NEW.paid_at = NOW();
        PERFORM process_successful_donation(NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER donation_success_trigger
    BEFORE UPDATE ON donations
    FOR EACH ROW EXECUTE FUNCTION trigger_process_donation();

-- =====================================================
-- RLS (Row Level Security) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE donations ENABLE ROW LEVEL SECURITY;
ALTER TABLE trip_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracking_summary ENABLE ROW LEVEL SECURITY;

-- Users can only access their own data
CREATE POLICY "Users can view own profile" ON users FOR SELECT USING (auth.uid() = auth_user_id);
CREATE POLICY "Users can update own profile" ON users FOR UPDATE USING (auth.uid() = auth_user_id);

-- Donations policies
CREATE POLICY "Users can view own donations" ON donations FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
);
CREATE POLICY "Users can create own donations" ON donations FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
);

-- Trip tracking policies
CREATE POLICY "Users can view own trips" ON trip_tracking FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
);
CREATE POLICY "Users can create own trips" ON trip_tracking FOR INSERT WITH CHECK (
    user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
);

-- Tracking summary policies
CREATE POLICY "Users can view own summary" ON tracking_summary FOR SELECT USING (
    user_id IN (SELECT id FROM users WHERE auth_user_id = auth.uid())
);

-- Communities are public (read-only)
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Communities are publicly readable" ON communities FOR SELECT USING (is_active = true);

-- Vehicle emission factors are public (read-only)
ALTER TABLE vehicle_emission_factors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Emission factors are publicly readable" ON vehicle_emission_factors FOR SELECT USING (true);

-- =====================================================
-- VIEWS FOR EASY DATA ACCESS
-- =====================================================

-- User dashboard view
CREATE OR REPLACE VIEW user_dashboard AS
SELECT 
    u.id,
    u.full_name,
    u.email,
    u.total_emission_kg,
    u.total_offset_kg,
    u.total_donations,
    (u.total_emission_kg - u.total_offset_kg) as net_emission_kg,
    CASE 
        WHEN u.total_emission_kg > 0 THEN (u.total_offset_kg / u.total_emission_kg * 100)
        ELSE 0 
    END as offset_percentage,
    (SELECT COUNT(*) FROM trip_tracking WHERE user_id = u.id) as total_trips,
    (SELECT COUNT(*) FROM donations WHERE user_id = u.id AND payment_status = 'success') as total_successful_donations
FROM users u;

-- Community statistics view
CREATE OR REPLACE VIEW community_statistics AS
SELECT 
    c.*,
    (SELECT COUNT(*) FROM donations WHERE community_id = c.id AND payment_status = 'success') as donor_count,
    CASE 
        WHEN c.total_donations > 0 THEN (c.total_donations / NULLIF((SELECT COUNT(*) FROM donations WHERE community_id = c.id AND payment_status = 'success'), 0))
        ELSE 0 
    END as average_donation
FROM communities c;

-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================

-- Note: Sample users will be created through the application
-- This is just the schema setup

COMMIT;