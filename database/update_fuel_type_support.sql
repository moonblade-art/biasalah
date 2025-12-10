-- Update fuel type constraint to support 'human' for bicycles
-- This allows tracking of bicycle trips with zero emissions

-- First, update trip_history table constraints
ALTER TABLE public.trip_history DROP CONSTRAINT IF EXISTS trip_history_fuel_type_check;
ALTER TABLE public.trip_history ADD CONSTRAINT trip_history_fuel_type_check 
CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid', 'human'));

ALTER TABLE public.trip_history DROP CONSTRAINT IF EXISTS trip_history_vehicle_type_check;
ALTER TABLE public.trip_history ADD CONSTRAINT trip_history_vehicle_type_check 
CHECK (vehicle_type IN ('car', 'motorcycle', 'bicycle'));

-- Update vehicle_emission_factors table constraints
ALTER TABLE public.vehicle_emission_factors DROP CONSTRAINT IF EXISTS vehicle_emission_factors_vehicle_type_check;
ALTER TABLE public.vehicle_emission_factors ADD CONSTRAINT vehicle_emission_factors_vehicle_type_check 
CHECK (vehicle_type IN ('car', 'motorcycle', 'bicycle'));

ALTER TABLE public.vehicle_emission_factors DROP CONSTRAINT IF EXISTS vehicle_emission_factors_fuel_type_check;
ALTER TABLE public.vehicle_emission_factors ADD CONSTRAINT vehicle_emission_factors_fuel_type_check 
CHECK (fuel_type IN ('gasoline', 'diesel', 'electric', 'hybrid', 'human'));

-- Now insert bicycle emission factor
INSERT INTO public.vehicle_emission_factors (vehicle_type, fuel_type, cc_min, cc_max, emission_factor_min, emission_factor_max, description) VALUES
('bicycle', 'human', 0, 0, 0.00, 0.00, 'Human-powered bicycles (zero emissions)')
ON CONFLICT DO NOTHING;

-- Update communities table constraint if needed
ALTER TABLE public.communities DROP CONSTRAINT IF EXISTS communities_focus_area_check;
ALTER TABLE public.communities ADD CONSTRAINT communities_focus_area_check 
CHECK (focus_area IN (
  'reforestation', 'renewable_energy', 'waste_management', 
  'ocean_conservation', 'urban_forest', 'agriculture'
));

COMMENT ON TABLE public.trip_history IS 'Stores all user trip tracking data including zero-emission trips';
COMMENT ON COLUMN public.trip_history.fuel_type IS 'Type of fuel used: gasoline, diesel, electric, hybrid, or human (for bicycles)';
COMMENT ON COLUMN public.trip_history.co2_emission IS 'CO2 emission in kg - can be 0.0 for zero-emission vehicles';