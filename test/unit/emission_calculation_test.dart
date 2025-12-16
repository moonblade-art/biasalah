// test/unit/emission_calculation_test.dart
// Unit Test 2: Emission Calculation Logic

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Emission Calculation Unit Tests', () {
    
    // Test 1: Car Emission Calculation
    test('UNIT-EMISSION-001: Car CO₂ calculation is correct', () {
      // Arrange
      final vehicleType = 'car';
      final distance = 10.0; // km
      final expectedEmission = 2.31; // kg CO₂ (0.231 kg/km)
      
      // Act
      final result = calculateEmission(vehicleType, distance);
      
      // Assert - assertEquals with tolerance
      expect(result, closeTo(expectedEmission, 0.01));
      expect(result, greaterThan(0));
    });
    
    // Test 2: Motorcycle Emission
    test('UNIT-EMISSION-002: Motorcycle CO₂ calculation', () {
      final result = calculateEmission('motorcycle', 10.0);
      final expected = 1.17; // 0.117 kg/km
      
      expect(result, closeTo(expected, 0.01));
    });
    
    // Test 3: Bicycle (Zero Emission)
    test('UNIT-EMISSION-003: Bicycle has zero emission', () {
      final result = calculateEmission('bicycle', 10.0);
      
      expect(result, equals(0.0)); // assertEquals
      expect(result, isZero); // Custom matcher
    });
    
    // Test 4: Electric Vehicle (Low Emission)
    test('UNIT-EMISSION-004: Electric vehicle has low emission', () {
      final result = calculateEmission('electric', 10.0);
      final gasResult = calculateEmission('car', 10.0);
      
      expect(result, lessThan(gasResult)); // EV < Gas car
      expect(result, greaterThan(0));
    });
    
    // Test 5: Different Distances
    test('UNIT-EMISSION-005: Emission scales with distance', () {
      final distance1 = 10.0;
      final distance2 = 20.0;
      
      final emission1 = calculateEmission('car', distance1);
      final emission2 = calculateEmission('car', distance2);
      
      expect(emission2, closeTo(emission1 * 2, 0.01)); // Double distance = double emission
    });
    
    // Test 6: Zero Distance
    test('UNIT-EMISSION-006: Zero distance returns zero emission', () {
      final result = calculateEmission('car', 0.0);
      
      expect(result, equals(0.0));
      expect(result, isZero);
    });
    
    // Test 7: Negative Distance Handling
    test('UNIT-EMISSION-007: Negative distance returns zero', () {
      final result = calculateEmission('car', -10.0);
      
      expect(result, equals(0.0)); // Should not be negative
    });
    
    // Test 8: Emission Factor Validation
    test('UNIT-EMISSION-008: Emission factors are not null', () {
      final carFactor = getEmissionFactor('car');
      final bikeFactor = getEmissionFactor('bicycle');
      
      expect(carFactor, isNotNull); // assertNotNull
      expect(bikeFactor, isNotNull);
      expect(bikeFactor, equals(0.0));
    });
    
  });
}

// Helper Functions
const Map<String, double> emissionFactors = {
  'car': 0.231, // kg CO₂ per km
  'motorcycle': 0.117,
  'bus': 0.089,
  'bicycle': 0.0,
  'walking': 0.0,
  'electric': 0.050,
};

double calculateEmission(String vehicleType, double distance) {
  if (distance < 0) return 0.0;
  
  final factor = emissionFactors[vehicleType.toLowerCase()] ?? 0.0;
  return factor * distance;
}

double? getEmissionFactor(String vehicleType) {
  return emissionFactors[vehicleType.toLowerCase()];
}

// Custom matcher
const Matcher isZero = _IsZero();

class _IsZero extends Matcher {
  const _IsZero();
  
  @override
  bool matches(dynamic item, Map matchState) {
    return item == 0 || item == 0.0;
  }
  
  @override
  Description describe(Description description) =>
      description.add('zero value');
}
