-- ============================================
-- SIMPLE USERS TABLE UPDATE
-- ============================================
-- Script sederhana untuk menambahkan field profile ke table users
-- Jalankan script ini di Supabase SQL Editor

-- Add new columns to users table
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS total_donations DECIMAL(15, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS total_trips INTEGER DEFAULT 0;

-- Add comments for documentation
COMMENT ON COLUMN public.users.phone IS 'User phone number (optional)';
COMMENT ON COLUMN public.users.address IS 'User address (optional)';
COMMENT ON COLUMN public.users.profile_picture_url IS 'URL to user profile picture';
COMMENT ON COLUMN public.users.total_donations IS 'Total amount donated by user';
COMMENT ON COLUMN public.users.total_trips IS 'Total number of trips recorded';

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_users_profile_picture 
ON public.users(profile_picture_url) 
WHERE profile_picture_url IS NOT NULL;

-- Verify the update
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

-- ============================================
-- UPDATE COMPLETE!
-- ============================================
-- Next steps:
-- 1. Create storage bucket 'avatars' manually via Supabase Dashboard
-- 2. Set bucket to public
-- 3. Configure storage policies for user uploads
-- ============================================