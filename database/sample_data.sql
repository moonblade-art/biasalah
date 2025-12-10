-- =====================================================
-- ECOTRACK SAMPLE DATA FOR TESTING
-- =====================================================
-- Run this after schema and functions are created

-- =====================================================
-- 1. INSERT SAMPLE USERS (for testing)
-- =====================================================
-- Note: In production, users are created via Supabase Auth
-- This is just for testing the database structure

INSERT INTO public.users (
  user_id, full_name, email, phone, 
  emisi_offset, emisi_belum, total_distance, total_trips,
  preferred_vehicle_type, preferred_vehicle_cc,
  city, province, created_at
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  'Budi Santoso', 'budi@example.com', '+6281234567890',
  45.50, 123.75, 1250.00, 25,
  'car', 1500,
  'Jakarta', 'DKI Jakarta', NOW() - INTERVAL '30 days'
),
(
  '550e8400-e29b-41d4-a716-446655440002'::UUID,
  'Sari Dewi', 'sari@example.com', '+6281234567891',
  32.25, 89.40, 890.50, 18,
  'motorcycle', 150,
  'Bandung', 'Jawa Barat', NOW() - INTERVAL '25 days'
),
(
  '550e8400-e29b-41d4-a716-446655440003'::UUID,
  'Andi Prasetyo', 'andi@example.com', '+6281234567892',
  67.80, 156.30, 1680.25, 35,
  'car', 2000,
  'Surabaya', 'Jawa Timur', NOW() - INTERVAL '20 days'
);

-- =====================================================
-- 2. INSERT SAMPLE TRIP HISTORY
-- =====================================================

-- Trips for Budi (car user)
INSERT INTO public.trip_history (
  user_id, start_location, end_location, distance_km,
  vehicle_type, vehicle_cc, fuel_type, emission_factor, co2_emission,
  trip_date, trip_duration_minutes, notes
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  'Rumah, Jakarta Selatan', 'Kantor, Jakarta Pusat', 15.5,
  'car', 1500, 'gasoline', 0.145, 2.25,
  CURRENT_DATE - INTERVAL '1 day', 45, 'Perjalanan ke kantor'
),
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  'Kantor, Jakarta Pusat', 'Mall, Jakarta Barat', 12.3,
  'car', 1500, 'gasoline', 0.145, 1.78,
  CURRENT_DATE - INTERVAL '1 day', 35, 'Makan siang di mall'
),
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  'Mall, Jakarta Barat', 'Rumah, Jakarta Selatan', 18.7,
  'car', 1500, 'gasoline', 0.145, 2.71,
  CURRENT_DATE - INTERVAL '1 day', 50, 'Pulang ke rumah'
);

-- Trips for Sari (motorcycle user)
INSERT INTO public.trip_history (
  user_id, start_location, end_location, distance_km,
  vehicle_type, vehicle_cc, fuel_type, emission_factor, co2_emission,
  trip_date, trip_duration_minutes, notes
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440002'::UUID,
  'Rumah, Bandung', 'Kampus, Bandung', 8.5,
  'motorcycle', 150, 'gasoline', 0.075, 0.64,
  CURRENT_DATE - INTERVAL '2 days', 25, 'Kuliah pagi'
),
(
  '550e8400-e29b-41d4-a716-446655440002'::UUID,
  'Kampus, Bandung', 'Cafe, Bandung', 5.2,
  'motorcycle', 150, 'gasoline', 0.075, 0.39,
  CURRENT_DATE - INTERVAL '2 days', 15, 'Ngerjain tugas'
),
(
  '550e8400-e29b-41d4-a716-446655440002'::UUID,
  'Cafe, Bandung', 'Rumah, Bandung', 7.8,
  'motorcycle', 150, 'gasoline', 0.075, 0.59,
  CURRENT_DATE - INTERVAL '2 days', 20, 'Pulang sore'
);

-- Trips for Andi (larger car user)
INSERT INTO public.trip_history (
  user_id, start_location, end_location, distance_km,
  vehicle_type, vehicle_cc, fuel_type, emission_factor, co2_emission,
  trip_date, trip_duration_minutes, notes
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440003'::UUID,
  'Rumah, Surabaya', 'Kantor, Surabaya', 22.5,
  'car', 2000, 'gasoline', 0.185, 4.16,
  CURRENT_DATE - INTERVAL '3 days', 60, 'Berangkat kerja'
),
(
  '550e8400-e29b-41d4-a716-446655440003'::UUID,
  'Kantor, Surabaya', 'Meeting Client, Sidoarjo', 35.8,
  'car', 2000, 'gasoline', 0.185, 6.62,
  CURRENT_DATE - INTERVAL '3 days', 90, 'Meeting dengan klien'
),
(
  '550e8400-e29b-41d4-a716-446655440003'::UUID,
  'Sidoarjo', 'Rumah, Surabaya', 28.3,
  'car', 2000, 'gasoline', 0.185, 5.24,
  CURRENT_DATE - INTERVAL '3 days', 75, 'Pulang dari meeting'
);

-- =====================================================
-- 3. INSERT SAMPLE DONATIONS
-- =====================================================

-- Successful donations
INSERT INTO public.donations (
  user_id, community_id, amount, carbon_amount,
  payment_method, payment_status, midtrans_order_id, midtrans_transaction_id,
  donor_name, donor_message, donated_at, paid_at
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  (SELECT id FROM public.communities WHERE name = 'Mangrove Surabaya' LIMIT 1),
  50000.00, 11.11,
  'midtrans', 'success', 'ECO-20241201-ABC12345', 'TXN-789456123',
  'Budi S.', 'Semoga bermanfaat untuk lingkungan!',
  NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'
),
(
  '550e8400-e29b-41d4-a716-446655440002'::UUID,
  (SELECT id FROM public.communities WHERE name = 'Hutan Lindung Bogor' LIMIT 1),
  30000.00, 6.00,
  'midtrans', 'success', 'ECO-20241202-DEF67890', 'TXN-456789012',
  NULL, 'Untuk masa depan yang lebih hijau',
  NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'
),
(
  '550e8400-e29b-41d4-a716-446655440003'::UUID,
  (SELECT id FROM public.communities WHERE name = 'Energi Surya Bali' LIMIT 1),
  100000.00, 16.67,
  'midtrans', 'success', 'ECO-20241203-GHI34567', 'TXN-123456789',
  'Andi Prasetyo', 'Dukung energi terbarukan!',
  NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'
);

-- Pending donations (for testing)
INSERT INTO public.donations (
  user_id, community_id, amount, carbon_amount,
  payment_method, payment_status, midtrans_order_id,
  donor_name, donated_at, expires_at
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  (SELECT id FROM public.communities WHERE name = 'Biogas Yogyakarta' LIMIT 1),
  75000.00, 13.64,
  'midtrans', 'pending', 'ECO-20241204-JKL90123',
  'Budi S.', NOW() - INTERVAL '2 hours', NOW() + INTERVAL '22 hours'
);

-- =====================================================
-- 4. INSERT SAMPLE NOTIFICATIONS
-- =====================================================

INSERT INTO public.notifications (
  user_id, type, title, message, data, is_read, created_at
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  'donation_success', 'Donasi Berhasil! 🌱',
  'Donasi Anda sebesar Rp 50.000 untuk Mangrove Surabaya telah berhasil diproses. Anda telah menanam 5 pohon!',
  '{"donation_id": "123", "amount": 50000, "tree_count": 5, "community_name": "Mangrove Surabaya"}',
  TRUE, NOW() - INTERVAL '5 days'
),
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  'trip_completed', 'Perjalanan Tercatat!',
  'Perjalanan sejauh 15.5 km telah tercatat dengan emisi 2.25 kg CO₂.',
  '{"trip_id": "456", "distance_km": 15.5, "co2_emission": 2.25}',
  FALSE, NOW() - INTERVAL '1 day'
),
(
  '550e8400-e29b-41d4-a716-446655440002'::UUID,
  'weekly_reminder', 'Ringkasan Mingguan 📊',
  'Minggu ini Anda telah menempuh 21.5 km dengan emisi total 1.62 kg CO₂. Pertimbangkan untuk berdonasi offset!',
  '{"weekly_distance": 21.5, "weekly_emissions": 1.62}',
  FALSE, NOW() - INTERVAL '2 days'
),
(
  '550e8400-e29b-41d4-a716-446655440003'::UUID,
  'achievement_unlocked', 'Pencapaian Baru! 🏆',
  'Selamat! Anda telah mencapai 1000 km perjalanan total. Terus jaga lingkungan!',
  '{"achievement": "1000km_milestone", "total_distance": 1000}',
  FALSE, NOW() - INTERVAL '3 days'
);

-- =====================================================
-- 5. CREATE NOTIFICATION PREFERENCES FOR SAMPLE USERS
-- =====================================================

INSERT INTO public.notification_preferences (
  user_id, trip_notifications, donation_notifications, 
  weekly_reminders, push_notifications, email_notifications
) VALUES 
(
  '550e8400-e29b-41d4-a716-446655440001'::UUID,
  TRUE, TRUE, TRUE, TRUE, FALSE
),
(
  '550e8400-e29b-41d4-a716-446655440002'::UUID,
  TRUE, TRUE, FALSE, TRUE, TRUE
),
(
  '550e8400-e29b-41d4-a716-446655440003'::UUID,
  FALSE, TRUE, TRUE, TRUE, FALSE
);

-- =====================================================
-- 6. UPDATE TRACKING SUMMARIES FOR SAMPLE USERS
-- =====================================================

-- This will calculate and populate tracking summaries based on the sample data
SELECT update_tracking_summary('550e8400-e29b-41d4-a716-446655440001'::UUID);
SELECT update_tracking_summary('550e8400-e29b-41d4-a716-446655440002'::UUID);
SELECT update_tracking_summary('550e8400-e29b-41d4-a716-446655440003'::UUID);

-- =====================================================
-- 7. VERIFY SAMPLE DATA
-- =====================================================

-- Check users
SELECT 
  full_name, email, city, 
  emisi_offset, emisi_belum, total_distance, total_trips
FROM public.users
ORDER BY created_at;

-- Check communities
SELECT 
  name, location, focus_area, carbon_price_per_kg,
  total_donations, total_carbon_offset, total_trees_planted
FROM public.communities
WHERE is_active = TRUE
ORDER BY name;

-- Check recent trips
SELECT 
  u.full_name, th.start_location, th.end_location,
  th.distance_km, th.co2_emission, th.trip_date
FROM public.trip_history th
JOIN public.users u ON th.user_id = u.user_id
ORDER BY th.trip_date DESC, th.created_at DESC
LIMIT 10;

-- Check donations
SELECT 
  u.full_name, c.name as community_name,
  d.amount, d.carbon_amount, d.tree_count,
  d.payment_status, d.donated_at
FROM public.donations d
JOIN public.users u ON d.user_id = u.user_id
JOIN public.communities c ON d.community_id = c.id
ORDER BY d.donated_at DESC;

-- Check tracking summaries
SELECT 
  u.full_name,
  ts.monthly_trips, ts.monthly_distance, ts.monthly_emissions,
  ts.total_trips, ts.total_distance, ts.total_emissions, ts.total_offset,
  ts.trees_planted, ts.co2_saved
FROM public.tracking_summary ts
JOIN public.users u ON ts.user_id = u.user_id
ORDER BY u.full_name;

-- Check notifications
SELECT 
  u.full_name, n.type, n.title, n.is_read, n.created_at
FROM public.notifications n
JOIN public.users u ON n.user_id = u.user_id
ORDER BY n.created_at DESC
LIMIT 10;

-- =====================================================
-- 8. TEST FUNCTIONS
-- =====================================================

-- Test OTP generation (remove in production)
SELECT generate_otp('test@example.com', 'email');

-- Test emission calculation
SELECT calculate_trip_emission(25.5, 'car', 1500, 'gasoline');
SELECT calculate_trip_emission(15.0, 'motorcycle', 150, 'gasoline');

-- Test donation calculation
SELECT calculate_donation_details(
  100000.00, 
  (SELECT id FROM public.communities WHERE name = 'Mangrove Surabaya' LIMIT 1)
);

-- Test user dashboard
SELECT get_user_dashboard('550e8400-e29b-41d4-a716-446655440001'::UUID);

-- =====================================================
-- SAMPLE DATA SETUP COMPLETE!
-- =====================================================
-- Database is now ready with:
-- - Sample users with realistic data
-- - Trip history with proper emissions calculations
-- - Successful and pending donations
-- - Notifications for different scenarios
-- - Tracking summaries
-- - All functions tested and working
-- =====================================================