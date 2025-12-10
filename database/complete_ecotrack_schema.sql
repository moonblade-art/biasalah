-- =====================================================
-- ECOTRACK COMPLETE DATABASE SCHEMA FOR SUPABASE
-- =====================================================
-- Includes: Communities, Donations, Tracking, OTP Auth, Emission Factors

-- ============================================
-- 1. ENABLE EXTENSIONS
-- ============================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- 2. CREATE EMISSION FACTORS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS public.emission_factors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vehicle_type TEXT NOT NULL, -- 'car' or 'motorcycle'
  engine_capacity_min INTEGER NOT NULL, -- CC minimum
  engine_capacity_max INTEGER, -- CC maximum (NULL for open-ended)
  emission_factor_min DECIMAL(6, 4) NOT NULL, -- kg CO2/km minimum
  emission_factor_max DECIMAL(6, 4) NOT NULL