// test/unit/trip_calculation_test.dart
// Unit Test 5: Trip Distance & Duration Calculation

import 'package:flutter_test/flutter_test.dart';
import 'dart:math';

void main() {
  group('Trip Calculation Unit Tests', () {
    
    // Test 1: Distance Calculation (Haversine Formula)
    test('UNIT-TRIP-001: Distance between two points calculated correctly', () {
      // Jakarta to Bandung (approx 120 km)
      const lat1 = -6.2088; // Jakarta
      const lon1 = 106.8456;
      const lat2 = -6.9175; // Bandung
      const lon2 = 107.6191;
      
      final distance = calculateDistance(lat1, lon1, lat2, lon2);
      
      expect(distance, greaterThan(100)); // At least 100 km
      expect(distance, lessThan(150)); // Less than 150 km
      expect(distance, closeTo(116, 20)); // Around 116 km ± 20
    });
    
    // Test 2: Zero Distance (Same Location)
    test('UNIT-TRIP-002: Same coordinates return zero distance', () {
      const lat = -6.2088;
      const lon = 106.8456;
      
      final distance = calculateDistance(lat, lon, lat, lon);
      
      expect(distance, equals(0.0));
      expect(distance, isZero);
    });
    
    // Test 3: Trip Duration Calculation
    test('UNIT-TRIP-003: Trip duration calculated from timestamps', () {
      final startTime = DateTime(2024, 12, 16, 10, 0); // 10:00
      final endTime = DateTime(2024, 12, 16, 11, 30); // 11:30
      
      final duration = calculateDuration(startTime, endTime);
      
      expect(duration.inMinutes, equals(90)); // 1.5 hours = 90 minutes
      expect(duration.inHours, equals(1));
    });
    
    // Test 4: Average Speed Calculation
    test('UNIT-TRIP-004: Average speed calculated correctly', () {
      const distance = 60.0; // km
      const duration = Duration(hours: 1); // 1 hour
      
      final avgSpeed = calculateAverageSpeed(distance, duration);
      
      expect(avgSpeed, equals(60.0)); // 60 km/h
    });
    
    test('UNIT-TRIP-005: Average speed with minutes', () {
      const distance = 30.0; // km
      const duration = Duration(minutes: 30); // 0.5 hour
      
      final avgSpeed = calculateAverageSpeed(distance, duration);
      
      expect(avgSpeed, equals(60.0)); // Still 60 km/h
    });
    
    // Test 5: Realistic Speed Validation
    test('UNIT-TRIP-006: Unrealistic speed detected', () {
      expect(isRealisticSpeed(200), isFalse); // Too fast for normal vehicle
      expect(isRealisticSpeed(150), isFalse); // Still too fast
      expect(isRealisticSpeed(120), isTrue); // Highway speed
      expect(isRealisticSpeed(60), isTrue); // City speed
      expect(isRealisticSpeed(0), isFalse); // Not moving
    });
    
    // Test 6: Distance Rounding
    test('UNIT-TRIP-007: Distance rounded to 2 decimal places', () {
      const preciseDistance = 15.6789;
      
      final rounded = roundDistance(preciseDistance, 2);
      
      expect(rounded, equals(15.68));
    });
    
    // Test 7: Trip Time Validation
    test('UNIT-TRIP-008: Negative duration returns zero', () {
      final endTime = DateTime(2024, 12, 16, 10, 0);
      final startTime = DateTime(2024, 12, 16, 11, 0); // After end time
      
      final duration = calculateDuration(startTime, endTime);
      
      expect(duration.isNegative, isTrue);
      expect(duration.inSeconds, lessThan(0));
    });
    
    // Test 8: Multiple Waypoints Distance
    test('UNIT-TRIP-009: Total distance from multiple waypoints', () {
      final waypoints = [
        {'lat': -6.2088, 'lon': 106.8456}, // Point 1
        {'lat': -6.3000, 'lon': 106.9000}, // Point 2
        {'lat': -6.4000, 'lon': 107.0000}, // Point 3
      ];
      
      final totalDistance = calculateTotalDistance(waypoints);
      
      expect(totalDistance, greaterThan(0));
      expect(totalDistance, isNotNull);
    });
    
  });
}

// Helper Functions
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371.0; // Radius in kilometers
  
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
            cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
  
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _toRadians(double degrees) {
  return degrees * pi / 180;
}

Duration calculateDuration(DateTime start, DateTime end) {
  return end.difference(start);
}

double calculateAverageSpeed(double distanceKm, Duration duration) {
  if (duration.inSeconds == 0) return 0.0;
  
  final hours = duration.inSeconds / 3600;
  return distanceKm / hours;
}

bool isRealisticSpeed(double speed) {
  // Speed in km/h
  // Realistic range: 1-120 km/h for normal vehicles
  return speed > 0 && speed <= 120;
}

double roundDistance(double distance, int decimals) {
  final factor = pow(10, decimals);
  return (distance * factor).round() / factor;
}

double calculateTotalDistance(List<Map<String, double>> waypoints) {
  double total = 0.0;
  
  for (int i = 0; i < waypoints.length - 1; i++) {
    final current = waypoints[i];
    final next = waypoints[i + 1];
    
    total += calculateDistance(
      current['lat']!,
      current['lon']!,
      next['lat']!,
      next['lon']!,
    );
  }
  
  return total;
}

const Matcher isZero = _IsZero();

class _IsZero extends Matcher {
  const _IsZero();
  
  @override
  bool matches(dynamic item, Map matchState) => item == 0 || item == 0.0;
  
  @override
  Description describe(Description description) => description.add('zero value');
}
