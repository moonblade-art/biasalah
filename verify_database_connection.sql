-- Verify Database Connection for Donations Integration
-- Run this in Supabase SQL Editor to check everything is connected

-- 1. Check if donations table exists and has correct structure
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'donations' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if required indexes exist
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'donations' 
    AND schemaname = 'public';

-- 3. Check RLS policies for donations table
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'donations';

-- 4. Check if communities table exists (required for foreign key)
SELECT COUNT(*) as community_count 
FROM public.communities;

-- 5. Check if users table exists (required for foreign key)
SELECT COUNT(*) as user_count 
FROM public.users;

-- 6. Test donation insertion (will fail if structure is wrong)
-- This is a dry run - comment out if you don't want to insert test data
/*
INSERT INTO public.donations (
    user_id,
    community_id,
    amount,
    carbon_amount,
    payment_method,
    payment_status,
    midtrans_order_id,
    notes
) VALUES (
    (SELECT user_id FROM public.users LIMIT 1),
    (SELECT id FROM public.communities LIMIT 1),
    50000.00,
    10.50,
    'midtrans',
    'pending',
    'TEST-' || extract(epoch from now()),
    'Test donation for integration verification'
) RETURNING id, created_at, payment_status;
*/

-- 7. Check recent donations (if any)
SELECT 
    id,
    user_id,
    community_id,
    amount,
    carbon_amount,
    payment_status,
    midtrans_order_id,
    created_at
FROM public.donations 
ORDER BY created_at DESC 
LIMIT 5;

-- 8. Verify donation constraints
SELECT 
    conname as constraint_name,
    contype as constraint_type,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.donations'::regclass;

-- 9. Check if Edge Functions can access donations table
-- (This will show if RLS is properly configured)
SELECT 
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'donations' 
    AND table_schema = 'public';

-- 10. Summary check
SELECT 
    'Database Structure' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'donations' AND table_schema = 'public')
        THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status,
    'Donations table exists' as description

UNION ALL

SELECT 
    'Foreign Keys' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE table_name = 'donations' AND constraint_type = 'FOREIGN KEY')
        THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status,
    'Foreign key constraints exist' as description

UNION ALL

SELECT 
    'Indexes' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_indexes WHERE tablename = 'donations' AND indexname LIKE 'idx_donations_%')
        THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status,
    'Performance indexes exist' as description

UNION ALL

SELECT 
    'RLS Policies' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'donations')
        THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status,
    'Row Level Security configured' as description;

-- Expected Results:
-- ✅ All checks should return PASS
-- ✅ Donations table should have all required columns
-- ✅ Foreign keys to users and communities should exist
-- ✅ Indexes should be present for performance
-- ✅ RLS policies should allow user access to own donations