-- ============================================
-- STEP BY STEP SETUP FOR PROFILE FEATURES
-- ============================================
-- Jalankan script ini satu per satu di Supabase SQL Editor

-- ============================================
-- STEP 1: UPDATE USERS TABLE
-- ============================================
-- Jalankan query ini terlebih dahulu:

ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS total_donations DECIMAL(15, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS total_trips INTEGER DEFAULT 0;

-- ============================================
-- STEP 2: ADD COMMENTS
-- ============================================
-- Jalankan query ini setelah step 1 berhasil:

COMMENT ON COLUMN public.users.phone IS 'User phone number (optional)';
COMMENT ON COLUMN public.users.address IS 'User address (optional)';
COMMENT ON COLUMN public.users.profile_picture_url IS 'URL to user profile picture';
COMMENT ON COLUMN public.users.total_donations IS 'Total amount donated by user';
COMMENT ON COLUMN public.users.total_trips IS 'Total number of trips recorded';

-- ============================================
-- STEP 3: CREATE INDEX
-- ============================================
-- Jalankan query ini setelah step 2 berhasil:

CREATE INDEX IF NOT EXISTS idx_users_profile_picture 
ON public.users(profile_picture_url) 
WHERE profile_picture_url IS NOT NULL;

-- ============================================
-- STEP 4: CREATE STORAGE BUCKET
-- ============================================
-- Jalankan query ini setelah step 3 berhasil:

INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================
-- STEP 5: VERIFY SETUP
-- ============================================
-- Jalankan query ini untuk memverifikasi:

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
-- STEP 6: SETUP STORAGE POLICIES (MANUAL)
-- ============================================
-- Untuk storage policies, lebih baik setup manual melalui Supabase Dashboard:
-- 1. Go to Storage → Policies
-- 2. Create new policy for 'avatars' bucket
-- 3. Set policy untuk SELECT, INSERT, UPDATE, DELETE sesuai kebutuhan

-- Atau jika ingin via SQL, jalankan satu per satu:

-- Policy 1: Public read access
-- CREATE POLICY "Avatar images are publicly accessible"
-- ON storage.objects FOR SELECT
-- USING (bucket_id = 'avatars');

-- Policy 2: Users can upload their own avatar
-- CREATE POLICY "Users can upload their own avatar"
-- ON storage.objects FOR INSERT
-- WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Policy 3: Users can update their own avatar
-- CREATE POLICY "Users can update their own avatar"
-- ON storage.objects FOR UPDATE
-- USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Policy 4: Users can delete their own avatar
-- CREATE POLICY "Users can delete their own avatar"
-- ON storage.objects FOR DELETE
-- USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================
-- SETUP COMPLETE!
-- ============================================