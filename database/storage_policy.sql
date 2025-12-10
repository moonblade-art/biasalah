-- =====================================================
-- STORAGE RLS POLICIES FOR AVATARS
-- =====================================================
-- This file sets up RLS for the 'avatars' storage bucket.
-- It ensures users can only upload/delete their own avatars.

-- 1. Create the bucket if it doesn't exist (idempotent)
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Enable RLS on objects table (Usually enabled by default, skipping to avoid permission error)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Avatars Public Read" ON storage.objects;
DROP POLICY IF EXISTS "Avatars Insert Own" ON storage.objects;
DROP POLICY IF EXISTS "Avatars Update Own" ON storage.objects;
DROP POLICY IF EXISTS "Avatars Delete Own" ON storage.objects;

-- 4. Create Policies

-- READ: Everyone can view avatars (public profile pictures)
CREATE POLICY "Avatars Public Read"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'avatars');

-- INSERT: Authenticated users can upload to their own folder (userId/filename)
CREATE POLICY "Avatars Insert Own"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- UPDATE: Authenticated users can update their own files
CREATE POLICY "Avatars Update Own"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- DELETE: Authenticated users can delete their own files
CREATE POLICY "Avatars Delete Own"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'avatars' AND
  (storage.foldername(name))[1] = auth.uid()::text
);

-- =====================================================
-- VERIFICATION
-- =====================================================
-- Check if policies are applied
SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';
