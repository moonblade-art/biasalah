-- ============================================
-- SUPABASE DATABASE SCHEMA FOR ECOTRACK
-- ============================================
-- Copy and paste this entire file into Supabase SQL Editor
-- Dashboard → SQL Editor → New Query → Paste → Run

-- ============================================
-- 1. CREATE USERS TABLE (PROFILES)
-- ============================================

CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL UNIQUE,
  full_name TEXT NOT NULL,
  email TEXT NOT NULL,
  emisi_offset DECIMAL(10, 2) DEFAULT 0.0,
  emisi_belum DECIMAL(10, 2) DEFAULT 0.0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_users_user_id ON public.users(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);

-- Add comments for documentation
COMMENT ON TABLE public.users IS 'User profiles with emission tracking data';
COMMENT ON COLUMN public.users.user_id IS 'Foreign key to auth.users';
COMMENT ON COLUMN public.users.emisi_offset IS 'Total emissions that have been offset';
COMMENT ON COLUMN public.users.emisi_belum IS 'Total emissions not yet offset';

-- ============================================
-- 2. ENABLE ROW LEVEL SECURITY FOR USERS
-- ============================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (for re-running script)
DROP POLICY IF EXISTS "Users can read own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Service role can insert profiles" ON public.users;

-- Policy: Users can read their own profile
CREATE POLICY "Users can read own profile"
  ON public.users
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can update their own profile
CREATE POLICY "Users can update own profile"
  ON public.users
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Policy: Allow insert for authenticated users (for profile creation)
CREATE POLICY "Service role can insert profiles"
  ON public.users
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- ============================================
-- 3. CREATE TRIGGER FOR AUTO-UPDATE TIMESTAMP
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;

-- Create trigger to auto-update updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 4. CREATE TRIP HISTORY TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.trip_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  vehicle_type TEXT NOT NULL,
  fuel_type TEXT NOT NULL,
  distance DECIMAL(10, 2) NOT NULL,
  emission DECIMAL(10, 2) NOT NULL,
  is_offset BOOLEAN DEFAULT FALSE,
  trip_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for faster queries
CREATE INDEX IF NOT EXISTS idx_trip_history_user_id ON public.trip_history(user_id);
CREATE INDEX IF NOT EXISTS idx_trip_history_trip_date ON public.trip_history(trip_date);
CREATE INDEX IF NOT EXISTS idx_trip_history_is_offset ON public.trip_history(is_offset);

-- Add comments
COMMENT ON TABLE public.trip_history IS 'History of user trips and emissions';
COMMENT ON COLUMN public.trip_history.emission IS 'CO2 emission in kg';
COMMENT ON COLUMN public.trip_history.is_offset IS 'Whether this emission has been offset';

-- ============================================
-- 5. ENABLE ROW LEVEL SECURITY FOR TRIP HISTORY
-- ============================================

ALTER TABLE public.trip_history ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can read own trips" ON public.trip_history;
DROP POLICY IF EXISTS "Users can insert own trips" ON public.trip_history;
DROP POLICY IF EXISTS "Users can update own trips" ON public.trip_history;

-- Policy: Users can read their own trips
CREATE POLICY "Users can read own trips"
  ON public.trip_history
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can insert their own trips
CREATE POLICY "Users can insert own trips"
  ON public.trip_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own trips
CREATE POLICY "Users can update own trips"
  ON public.trip_history
  FOR UPDATE
  USING (auth.uid() = user_id);

-- ============================================
-- 6. CREATE FUNCTION TO CALCULATE TOTAL EMISSIONS
-- ============================================

-- Function to recalculate user emissions from trip history
CREATE OR REPLACE FUNCTION recalculate_user_emissions(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total_offset DECIMAL(10, 2);
  v_total_belum DECIMAL(10, 2);
BEGIN
  -- Calculate total offset emissions
  SELECT COALESCE(SUM(emission), 0)
  INTO v_total_offset
  FROM public.trip_history
  WHERE user_id = p_user_id AND is_offset = TRUE;
  
  -- Calculate total non-offset emissions
  SELECT COALESCE(SUM(emission), 0)
  INTO v_total_belum
  FROM public.trip_history
  WHERE user_id = p_user_id AND is_offset = FALSE;
  
  -- Update user profile
  UPDATE public.users
  SET 
    emisi_offset = v_total_offset,
    emisi_belum = v_total_belum
  WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 7. CREATE TRIGGER TO AUTO-UPDATE EMISSIONS
-- ============================================

-- Function to trigger emission recalculation
CREATE OR REPLACE FUNCTION trigger_recalculate_emissions()
RETURNS TRIGGER AS $$
BEGIN
  -- Recalculate for the affected user
  IF TG_OP = 'DELETE' THEN
    PERFORM recalculate_user_emissions(OLD.user_id);
  ELSE
    PERFORM recalculate_user_emissions(NEW.user_id);
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists
DROP TRIGGER IF EXISTS trip_history_emission_update ON public.trip_history;

-- Create trigger on trip_history changes
CREATE TRIGGER trip_history_emission_update
  AFTER INSERT OR UPDATE OR DELETE ON public.trip_history
  FOR EACH ROW
  EXECUTE FUNCTION trigger_recalculate_emissions();

-- ============================================
-- 8. INSERT SAMPLE DATA (OPTIONAL - FOR TESTING)
-- ============================================

-- Uncomment below to insert sample data after you create your first user

/*
-- Example: Insert sample trip for testing
-- Replace 'YOUR_USER_ID' with actual user_id from auth.users
INSERT INTO public.trip_history (user_id, vehicle_type, fuel_type, distance, emission, is_offset)
VALUES 
  ('YOUR_USER_ID', 'Mobil', 'Bensin', 10.5, 2.5, FALSE),
  ('YOUR_USER_ID', 'Motor', 'Bensin', 5.0, 0.8, TRUE);
*/

-- ============================================
-- 9. VERIFY SETUP
-- ============================================

-- Check if tables exist
SELECT 
  table_name,
  (SELECT COUNT(*) FROM information_schema.columns WHERE table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public' 
  AND table_name IN ('users', 'trip_history')
ORDER BY table_name;

-- Check if RLS is enabled
SELECT 
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN ('users', 'trip_history');

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Go to Authentication → Providers → Enable Email
-- 2. Configure email templates (optional)
-- 3. Test registration from your Flutter app
-- ============================================
