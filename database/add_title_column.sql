-- Add title and route_points columns to trip_history table
ALTER TABLE public.trip_history 
ADD COLUMN IF NOT EXISTS title TEXT,
ADD COLUMN IF NOT EXISTS route_points JSONB;

-- Update existing trips to have a default title
UPDATE public.trip_history
SET title = COALESCE(
  CASE 
    WHEN start_location IS NOT NULL AND end_location IS NOT NULL THEN start_location || ' ke ' || end_location
    WHEN start_location IS NOT NULL THEN 'Perjalanan dari ' || start_location
    ELSE 'Perjalanan ' || TO_CHAR(trip_date, 'DD Mon YYYY')
  END,
  'Perjalanan Tanpa Judul'
)
WHERE title IS NULL;
