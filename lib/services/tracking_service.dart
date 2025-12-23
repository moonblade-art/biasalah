// lib/services/tracking_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_emission_model.dart';

import '../models/trip_tracking_model.dart' as trip_model;
import 'auth_exception.dart' as app_auth;

class TrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Add a new trip tracking record
  Future<trip_model.TripTracking> addTrip({
    required String userId,
    required String vehicleType,
    required int engineCC,
    required double distanceKm,
    String? startLocation,
    String? endLocation,
    double? startLatitude,
    double? startLongitude,
    double? endLatitude,
    double? endLongitude,
    DateTime? tripDate,
    int? tripDurationMinutes,
    String? notes,
    String? title,
    List<Map<String, double>>? routePoints,
  }) async {
    try {
      // Calculate emission using the emission calculator
      double emission = 0.0;
      double emissionFactorValue = 0.0;
      
      try {
        emission = VehicleEmissionCalculator.calculateEmission(
          vehicleType: vehicleType,
          engineCC: engineCC,
          distanceKm: distanceKm,
        );

        final emissionFactor = VehicleEmissionCalculator.getEmissionFactor(vehicleType, engineCC);
        if (emissionFactor != null) {
          emissionFactorValue = emissionFactor.emissionAverage;
        }
      } catch (e) {
        // If emission calculation fails, use zero emission (for bicycles, etc.)
        print('Using zero emission for vehicle type: $vehicleType, CC: $engineCC');
        emission = 0.0;
        emissionFactorValue = 0.0;
      }

      // Determine fuel type based on vehicle type and emission
      String fuelType = 'gasoline'; // default
      if (emission == 0.0) {
        if (vehicleType.toLowerCase().contains('sepeda') || vehicleType.toLowerCase().contains('bicycle')) {
          fuelType = 'human'; // For bicycles
        } else {
          fuelType = 'electric'; // For electric vehicles
        }
      }

      // Map vehicle type to database-compatible values
      String dbVehicleType = _mapVehicleTypeToDb(vehicleType);
      
      final tripData = {
        'user_id': userId,
        'vehicle_type': dbVehicleType,
        'vehicle_cc': engineCC,
        'fuel_type': fuelType,
        'distance': distanceKm,
        'distance_km': distanceKm,
        'emission': emission,
        'co2_emission': emission,
        'emission_factor': emissionFactorValue,
        'start_location': startLocation,
        'end_location': endLocation,
        'start_latitude': startLatitude,
        'start_longitude': startLongitude,
        'end_latitude': endLatitude,
        'end_longitude': endLongitude,
        'trip_date': (tripDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'trip_duration_minutes': tripDurationMinutes,
        'notes': notes,
        'title': title,
        'route_points': routePoints,
      };

      print('Saving trip data: $tripData'); // Debug log

      final response = await _supabase
          .from('trip_history')
          .insert(tripData)
          .select()
          .single();

      print('Trip saved successfully: ${response['id']}'); // Debug log

      return trip_model.TripTracking.fromJson(response);
    } on PostgrestException catch (e) {
      print('PostgrestException: ${e.message}'); // Debug log
      throw app_auth.AppAuthException('Gagal menambah perjalanan: ${e.message}', 'add_trip_failed');
    } catch (e) {
      print('General exception: ${e.toString()}'); // Debug log
      throw app_auth.AppAuthException('Gagal menambah perjalanan: ${e.toString()}', 'add_trip_failed');
    }
  }

  /// Get user's trip history
  Future<List<trip_model.TripTracking>> getUserTrips({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    String? vehicleType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Simple query without complex filters for now
      final response = await _supabase
          .from('trip_history')
          .select()
          .order('trip_date', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // Filter results in memory (not ideal but works for now)
      List<Map<String, dynamic>> filteredResults = (response)
          .where((trip) => trip['user_id'] == userId)
          .toList();

      if (startDate != null) {
        final startDateStr = startDate.toIso8601String().split('T')[0];
        filteredResults = filteredResults
            .where((trip) => trip['trip_date'] != null && trip['trip_date'].compareTo(startDateStr) >= 0)
            .toList();
      }

      if (endDate != null) {
        final endDateStr = endDate.toIso8601String().split('T')[0];
        filteredResults = filteredResults
            .where((trip) => trip['trip_date'] != null && trip['trip_date'].compareTo(endDateStr) <= 0)
            .toList();
      }

      if (vehicleType != null) {
        filteredResults = filteredResults
            .where((trip) => trip['vehicle_type'] == vehicleType)
            .toList();
      }

      return filteredResults
          .map((json) => trip_model.TripTracking.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat riwayat perjalanan: ${e.message}', 'get_trips_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat riwayat perjalanan: ${e.toString()}', 'get_trips_failed');
    }
  }

  /// Get user's tracking summary
  Future<Map<String, dynamic>> getUserTrackingSummary({
    required String userId,
    String summaryType = 'daily',
    DateTime? date,
  }) async {
    try {
      final targetDate = date ?? DateTime.now();
      
      final response = await _supabase
          .from('tracking_summary')
          .select()
          .maybeSingle();

      if (response == null) {
        // Return default values if no summary exists
        return {
          'user_id': userId,
          'summary_date': targetDate.toIso8601String().split('T')[0],
          'summary_type': summaryType,
          'total_trips': 0,
          'total_distance_km': 0.0,
          'total_emission_kg': 0.0,
          'total_donations': 0.0,
          'total_offset_kg': 0.0,
          'net_emission_kg': 0.0,
        };
      }

      return response;
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat ringkasan tracking: ${e.message}', 'get_summary_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat ringkasan tracking: ${e.toString()}', 'get_summary_failed');
    }
  }

  /// Get user's emission statistics by period
  Future<List<Map<String, dynamic>>> getUserEmissionStats({
    required String userId,
    required String period, // 'daily', 'weekly', 'monthly'
    int days = 30,
  }) async {
    try {
      // Statistics for the last [days] days

      final response = await _supabase
          .from('tracking_summary')
          .select()
          .order('summary_date', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat statistik emisi: ${e.message}', 'get_stats_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat statistik emisi: ${e.toString()}', 'get_stats_failed');
    }
  }

  /// Update trip tracking record
  Future<trip_model.TripTracking> updateTrip({
    required String tripId,
    String? startLocation,
    String? endLocation,
    String? notes,
    String? title,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (startLocation != null) updateData['start_location'] = startLocation;
      if (endLocation != null) updateData['end_location'] = endLocation;
      if (notes != null) updateData['notes'] = notes;
      if (title != null) updateData['title'] = title;

      if (updateData.isEmpty) {
        throw app_auth.AppAuthException('Tidak ada data yang diperbarui', 'no_update_data');
      }

      final response = await _supabase
          .from('trip_history')
          .update(updateData)
          .eq('id', tripId)
          .select()
          .single();

      return trip_model.TripTracking.fromJson(response);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memperbarui perjalanan: ${e.message}', 'update_trip_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memperbarui perjalanan: ${e.toString()}', 'update_trip_failed');
    }
  }

  /// Delete trip tracking record
  Future<void> deleteTrip(String tripId) async {
    try {
      await _supabase
          .from('trip_history')
          .delete()
          .eq('id', tripId);
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal menghapus perjalanan: ${e.message}', 'delete_trip_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal menghapus perjalanan: ${e.toString()}', 'delete_trip_failed');
    }
  }

  /// Get available vehicle emission factors
  Future<List<VehicleEmissionFactor>> getEmissionFactors({String? vehicleType}) async {
    try {
      var query = _supabase
          .from('vehicle_emission_factors')
          .select()
          .order('vehicle_type')
          .order('cc_min');

      final response = await query;

      return (response as List)
          .map((json) => VehicleEmissionFactor.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat faktor emisi: ${e.message}', 'get_factors_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat faktor emisi: ${e.toString()}', 'get_factors_failed');
    }
  }

  /// Calculate emission for given parameters (without saving)
  double calculateEmission({
    required String vehicleType,
    required int engineCC,
    required double distanceKm,
  }) {
    return VehicleEmissionCalculator.calculateEmission(
      vehicleType: vehicleType,
      engineCC: engineCC,
      distanceKm: distanceKm,
    );
  }

  /// Get emission factor for specific vehicle
  VehicleEmissionFactor? getEmissionFactor(String vehicleType, int engineCC) {
    return VehicleEmissionCalculator.getEmissionFactor(vehicleType, engineCC);
  }

  /// Validate trip data
  Map<String, String> validateTripData({
    required String vehicleType,
    required int engineCC,
    required double distanceKm,
  }) {
    final errors = <String, String>{};

    if (!VehicleEmissionCalculator.isValidVehicleType(vehicleType)) {
      errors['vehicleType'] = 'Jenis kendaraan tidak valid';
    }

    // Allow zero CC for bicycles or electric vehicles
    if (engineCC < 0) {
      errors['engineCC'] = 'Kapasitas mesin tidak boleh negatif';
    }

    // Allow zero distance for stationary tracking or very short trips
    if (distanceKm < 0) {
      errors['distanceKm'] = 'Jarak tempuh tidak boleh negatif';
    }

    if (distanceKm > 10000) {
      errors['distanceKm'] = 'Jarak tempuh terlalu jauh (maksimal 10,000 km)';
    }

    // Check if emission factor exists, but allow zero emission vehicles
    try {
      VehicleEmissionCalculator.getEmissionFactor(vehicleType, engineCC);
    } catch (e) {
      // Only add error if it's not a zero-emission vehicle type
      if (vehicleType.toLowerCase() != 'sepeda' && vehicleType.toLowerCase() != 'bicycle') {
        errors['engineCC'] = 'Tidak ada faktor emisi untuk kapasitas mesin ini';
      }
    }

    return errors;
  }

  /// Get user's carbon footprint overview
  Future<Map<String, dynamic>> getUserCarbonFootprint(String userId) async {
    try {
      // Get user data with totals
      final userResponse = await _supabase
          .from('users')
          .select('total_emission_kg, total_offset_kg, total_donations')
          .single();

      final totalEmission = (userResponse['total_emission_kg'] as num?)?.toDouble() ?? 0.0;
      final totalOffset = (userResponse['total_offset_kg'] as num?)?.toDouble() ?? 0.0;
      final totalDonations = (userResponse['total_donations'] as num?)?.toDouble() ?? 0.0;

      // Get recent trips count
      final recentTripsResponse = await _supabase
          .from('trip_history')
          .select('id');

      final recentTripsCount = (recentTripsResponse as List).length;

      // Calculate carbon offset from donations
      final carbonOffsetInfo = VehicleEmissionCalculator.calculateCarbonOffset(totalDonations);

      return {
        'total_emission_kg': totalEmission,
        'total_offset_kg': totalOffset,
        'net_emission_kg': totalEmission - totalOffset,
        'total_donations': totalDonations,
        'recent_trips_count': recentTripsCount,
        'offset_percentage': totalEmission > 0 ? (totalOffset / totalEmission * 100) : 0.0,
        'carbon_offset_info': carbonOffsetInfo,
      };
    } on PostgrestException catch (e) {
      throw app_auth.AppAuthException('Gagal memuat jejak karbon: ${e.message}', 'get_footprint_failed');
    } catch (e) {
      throw app_auth.AppAuthException('Gagal memuat jejak karbon: ${e.toString()}', 'get_footprint_failed');
    }
  }

  /// Get popular vehicle configurations
  Future<List<Map<String, dynamic>>> getPopularVehicleConfigs() async {
    try {
      final response = await _supabase
          .from('trip_history')
          .select('vehicle_type, vehicle_cc')
          .limit(1000);

      // Group by vehicle type and engine CC
      final Map<String, Map<String, dynamic>> vehicleStats = {};
      
      for (final trip in response) {
        final vehicleType = trip['vehicle_type'] as String;
        final engineCC = (trip['vehicle_cc'] ?? 1500) as int;
        final key = '$vehicleType-$engineCC';
        
        vehicleStats[key] ??= <String, dynamic>{
          'vehicle_type': vehicleType,
          'engine_cc': engineCC,
          'count': 0,
        };
        vehicleStats[key]!['count'] = (vehicleStats[key]!['count'] as int) + 1;
      }

      // Sort by popularity and return top 10
      final sortedConfigs = vehicleStats.values.toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      return sortedConfigs.take(10).map((config) => {
        'vehicle_type': config['vehicle_type'],
        'engine_cc': config['engine_cc'],
        'count': config['count'],
        'vehicle_type_display': VehicleEmissionCalculator.getVehicleTypeDisplayName(config['vehicle_type'] as String),
      }).toList();
    } catch (e) {
      // Return default popular configurations if query fails
      return [
        {'vehicle_type': 'motorcycle', 'engine_cc': 150, 'vehicle_type_display': 'Motor'},
        {'vehicle_type': 'car', 'engine_cc': 1500, 'vehicle_type_display': 'Mobil'},
        {'vehicle_type': 'motorcycle', 'engine_cc': 125, 'vehicle_type_display': 'Motor'},
        {'vehicle_type': 'car', 'engine_cc': 1200, 'vehicle_type_display': 'Mobil'},
      ];
    }
  }

  /// Refresh user tracking summary (force recalculation)
  Future<void> refreshUserSummary(String userId) async {
    try {
      await _supabase.rpc('update_tracking_summary', params: {'p_user_id': userId});
    } catch (e) {
      // If stored procedure doesn't exist, we can still continue
      print('Warning: Could not refresh tracking summary: $e');
    }
  }

  /// Map vehicle type from UI to database-compatible values
  String _mapVehicleTypeToDb(String vehicleType) {
    final type = vehicleType.toLowerCase();
    
    if (type.contains('sepeda') || type.contains('bicycle')) {
      return 'bicycle';
    } else if (type.contains('motor') || type.contains('motorcycle')) {
      return 'motorcycle';
    } else if (type.contains('mobil') || type.contains('car')) {
      return 'car';
    }
    
    // Default mapping based on common values
    switch (type) {
      case 'sepeda':
      case 'bicycle':
        return 'bicycle';
      case 'motor':
      case 'motorcycle':
        return 'motorcycle';
      case 'mobil':
      case 'car':
        return 'car';
      default:
        // If unknown, try to guess or default to car
        print('Unknown vehicle type: $vehicleType, defaulting to car');
        return 'car';
    }
  }
}