-- ============================================
-- UPDATE USERS TABLE - ADD PROFILE FIELDS
-- ============================================
-- Script untuk menambahkan field profile ke table users

-- Add new columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS total_donations DECIMAL(15, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS total_trips INTEGER DEFAULT 0;

-- Add comments for new columns
COMMENT ON COLUMN public.users.phone IS 'User phone number (optional)';
COMMENT ON COLUMN public.users.address IS 'User address (optional)';
COMMENT ON COLUMN public.users.profile_picture_url IS 'URL to user profile picture';
COMMENT ON COLUMN public.users.total_donations IS 'Total amount donated by user';
COMMENT ON COLUMN public.users.total_trips IS 'Total number of trips recorded';

-- Create index for profile picture URL (for faster queries)
CREATE INDEX IF NOT EXISTS idx_users_profile_picture ON public.users(profile_picture_url) WHERE profile_picture_url IS NOT NULL;

-- ============================================
-- CREATE STORAGE BUCKET FOR AVATARS
-- ============================================

-- Create avatars bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Set up storage policy for avatars
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;

-- Create new policies
CREATE POLICY "Avatar images are publicly accessible"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can update their own avatar"
ON storage.objects FOR UPDATE
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own avatar"
ON storage.objects FOR DELETE
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================
-- UPDATE FUNCTIONS TO HANDLE NEW FIELDS
-- ============================================

-- Function to update user statistics
CREATE OR REPLACE FUNCTION update_user_statistics(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
  v_total_trips INTEGER;
  v_total_donations DECIMAL(15, 2);
BEGIN
  -- Count total trips
  SELECT COUNT(*)
  INTO v_total_trips
  FROM public.trip_history
  WHERE user_id = p_user_id;
  
  -- Sum total donations (if donations table exists)
  SELECT COALESCE(SUM(amount), 0)
  INTO v_total_donations
  FROM public.donations
  WHERE user_id = p_user_id AND payment_status = 'success';
  
  -- Update user statistics
  UPDATE public.users
  SET 
    total_trips = v_total_trips,
    total_donations = v_total_donations
  WHERE user_id = p_user_id;
  
EXCEPTION
  WHEN undefined_table THEN
    -- If donations table doesn't exist, only update trips
    UPDATE public.users
    SET total_trips = v_total_trips
    WHERE user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- VERIFY UPDATE
-- ============================================

-- Check if new columns exist
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name IN ('phone', 'address', 'profile_picture_url', 'total_donations', 'total_trips')
ORDER BY column_name;

-- Check storage bucket
SELECT * FROM storage.buckets WHERE id = 'avatars';

-- ============================================
-- UPDATE COMPLETE!
-- ============================================