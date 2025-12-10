-- Fix bicycle support - run this step by step
-- This script fixes the database constraints to support bicycle tracking

-- Step 1: Update trip_history table constraints
DO $$ 
BEGIN
    -- Drop existing constraints if they exist
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'trip_history_fuel_type_check' 
               AND table_name = 'trip_history') THEN
        ALTER TABLE public.trip_history DROP CONSTRAINT trip_history_fuel_type_check;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'trip_history_vehicle_type_check' 
               AND table_name = 'trip_history') THEN
        ALTER TABLE public.trip_history DROP CONSTRAINT trip_history_vehicle_type_check;
    END IF;
    
    -- Add new constraints
    ALTER TABLE public.trip_history ADD CONSTRAINT trip_history_fuel_type_check 
    CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid', 'human'));
    
    ALTER TABLE public.trip_history ADD CONSTRAINT trip_history_vehicle_type_check 
    CHECK (vehicle_type IN ('car', 'motorcycle', 'bicycle'));
END $$;

-- Step 2: Update vehicle_emission_factors table constraints
DO $$ 
BEGIN
    -- Drop existing constraints if they exist
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'vehicle_emission_factors_vehicle_type_check' 
               AND table_name = 'vehicle_emission_factors') THEN
        ALTER TABLE public.vehicle_emission_factors DROP CONSTRAINT vehicle_emission_factors_vehicle_type_check;
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints 
               WHERE constraint_name = 'vehicle_emission_factors_fuel_type_check' 
               AND table_name = 'vehicle_emission_factors') THEN
        ALTER TABLE public.vehicle_emission_factors DROP CONSTRAINT vehicle_emission_factors_fuel_type_check;
    END IF;
    
    -- Add new constraints
    ALTER TABLE public.vehicle_emission_factors ADD CONSTRAINT vehicle_emission_factors_vehicle_type_check 
    CHECK (vehicle_type IN ('car', 'motorcycle', 'bicycle'));
    
    ALTER TABLE public.vehicle_emission_factors ADD CONSTRAINT vehicle_emission_factors_fuel_type_check 
    CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid', 'human'));
END $$;

-- Step 3: Insert bicycle emission factor (only if it doesn't exist)
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) 
SELECT 'bicycle', 'human', 0, 0, 0.00, 0.00, 'Human-powered bicycles (zero emissions)'
WHERE NOT EXISTS (
    SELECT 1 FROM public.vehicle_emission_factors 
    WHERE vehicle_type = 'bicycle' AND fuel_type = 'human'
);

-- Verify the changes
SELECT 'Bicycle support added successfully' as status;
SELECT COUNT(*) as bicycle_factors FROM public.vehicle_emission_factors WHERE vehicle_type = 'bicycle';