-- =====================================================
-- TRIGGER TO UPDATE USER STATS FROM TRIP HISTORY
-- =====================================================
-- This trigger ensures that when a trip is inserted directly into trip_history
-- (as done by the Flutter app), the user's statistics (emisi_belum, total_distance, etc.)
-- are automatically updated.

CREATE OR REPLACE FUNCTION update_user_stats_from_trip()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'INSERT') THEN
    -- Update user stats on new trip
    UPDATE public.users
    SET 
      emisi_belum = COALESCE(emisi_belum, 0) + NEW.co2_emission,
      total_distance = COALESCE(total_distance, 0) + NEW.distance_km,
      total_trips = COALESCE(total_trips, 0) + 1,
      updated_at = NOW()
    WHERE user_id = NEW.user_id;
    
    -- Update tracking summary
    PERFORM update_tracking_summary(NEW.user_id);
    
  ELSIF (TG_OP = 'DELETE') THEN
    -- Revert user stats on trip deletion
    UPDATE public.users
    SET 
      emisi_belum = GREATEST(0, COALESCE(emisi_belum, 0) - OLD.co2_emission),
      total_distance = GREATEST(0, COALESCE(total_distance, 0) - OLD.distance_km),
      total_trips = GREATEST(0, COALESCE(total_trips, 0) - 1),
      updated_at = NOW()
    WHERE user_id = OLD.user_id;

    -- Update tracking summary
    PERFORM update_tracking_summary(OLD.user_id);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if exists to avoid duplication
DROP TRIGGER IF EXISTS trigger_update_user_stats_from_trip ON public.trip_history;

-- Create the trigger
CREATE TRIGGER trigger_update_user_stats_from_trip
AFTER INSERT OR DELETE ON public.trip_history
FOR EACH ROW
EXECUTE FUNCTION update_user_stats_from_trip();
