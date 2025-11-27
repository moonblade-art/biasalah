-- ============================================
-- UPDATE COMMUNITY PRICES TO NEW AFFORDABLE RATES
-- ============================================
-- Script untuk mengupdate harga komunitas menjadi lebih terjangkau

-- Update existing communities with new affordable prices
UPDATE public.communities 
SET carbon_price_per_kg = CASE 
  WHEN name = 'Hutan Lindung Bogor' THEN 5000.00
  WHEN name = 'Energi Surya Bali' THEN 6000.00
  WHEN name = 'Mangrove Surabaya' THEN 4500.00
  WHEN name = 'Biogas Yogyakarta' THEN 5500.00
  WHEN name = 'Hutan Kota Jakarta' THEN 5200.00
  ELSE 5000.00 -- Default price for any other communities
END,
updated_at = NOW()
WHERE is_active = TRUE;

-- Add new communities with affordable prices
INSERT INTO public.communities (name, description, image_url, location, focus_area, carbon_price_per_kg) VALUES
('Konservasi Laut Lombok', 'Program perlindungan terumbu karang dan ekosistem laut untuk penyerapan karbon biru', 'https://example.com/ocean1.jpg', 'Lombok, NTB', 'ocean_conservation', 4800.00),
('Daur Ulang Bandung', 'Program pengelolaan sampah dan daur ulang untuk mengurangi emisi dari TPA', 'https://example.com/recycle1.jpg', 'Bandung, Jawa Barat', 'waste_management', 4700.00),
('Hutan Rakyat Malang', 'Pemberdayaan masyarakat dalam pengelolaan hutan berkelanjutan', 'https://example.com/forest2.jpg', 'Malang, Jawa Timur', 'reforestation', 4900.00)
ON CONFLICT (name) DO NOTHING; -- Avoid duplicate if already exists

-- Verify the updates
SELECT name, location, focus_area, carbon_price_per_kg, updated_at 
FROM public.communities 
WHERE is_active = TRUE 
ORDER BY carbon_price_per_kg;

-- ============================================
-- PRICE UPDATE COMPLETE!
-- ============================================
-- New price range: Rp 4,500 - Rp 6,000 per kg CO2
-- Much more affordable for users
-- ============================================