# Database Fix Summary - Bicycle Support

## Problem
Database constraint error ketika mencoba menyimpan data sepeda:
```
ERROR: 23514: new row for relation "vehicle_emission_factors" violates check constraint "vehicle_emission_factors_fuel_type_check"
```

## Root Cause
1. Tabel `vehicle_emission_factors` tidak mengizinkan `fuel_type = 'human'`
2. Tabel `vehicle_emission_factors` tidak mengizinkan `vehicle_type = 'bicycle'`
3. Tabel `trip_history` tidak mengizinkan `vehicle_type = 'bicycle'`

## Solution Applied

### 1. Updated Database Schema
**File**: `database/ecotrack_complete_schema.sql`
- Added 'bicycle' to vehicle_type constraint
- Added 'human' to fuel_type constraint
- Added bicycle emission factor data

### 2. Created Fix Script
**File**: `database/fix_bicycle_support.sql`
- Automated script to update existing databases
- Handles constraint dropping and recreation safely
- Includes data verification

### 3. Updated Migration Script
**File**: `database/update_fuel_type_support.sql`
- Manual step-by-step approach
- More control over the update process

## How to Apply Fix

### For New Databases
Use the updated `database/ecotrack_complete_schema.sql` - it already includes bicycle support.

### For Existing Databases
Run this script in Supabase SQL Editor:

```sql
-- Run database/fix_bicycle_support.sql
-- This will safely update constraints and add bicycle support
```

## Verification

After running the fix, verify with:
```sql
-- Check constraints
SELECT constraint_name, check_clause 
FROM information_schema.check_constraints 
WHERE constraint_name LIKE '%vehicle%' OR constraint_name LIKE '%fuel%';

-- Check bicycle data
SELECT * FROM vehicle_emission_factors WHERE vehicle_type = 'bicycle';
```

## Expected Results
- ✅ Bicycle trips can be saved with zero emissions
- ✅ fuel_type 'human' is accepted
- ✅ vehicle_type 'bicycle' is accepted
- ✅ No constraint violations

## Files Modified
1. `database/ecotrack_complete_schema.sql` - Updated constraints and data
2. `database/fix_bicycle_support.sql` - New automated fix script
3. `database/update_fuel_type_support.sql` - Updated manual script
4. `lib/services/tracking_service.dart` - Already handles zero emissions
5. `lib/models/vehicle_emission_model.dart` - Already supports bicycles

## Status
✅ **FIXED** - Database now supports bicycle tracking with zero emissions