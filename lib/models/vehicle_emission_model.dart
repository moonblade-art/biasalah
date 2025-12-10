// lib/models/vehicle_emission_model.dart

class VehicleEmissionFactor {
  final String vehicleType; // 'car' or 'motorcycle'
  final int ccMin;
  final int ccMax;
  final double emissionMin; // kg CO2 per km
  final double emissionMax; // kg CO2 per km
  final double emissionAverage; // calculated average

  VehicleEmissionFactor({
    required this.vehicleType,
    required this.ccMin,
    required this.ccMax,
    required this.emissionMin,
    required this.emissionMax,
  }) : emissionAverage = (emissionMin + emissionMax) / 2;

  factory VehicleEmissionFactor.fromJson(Map<String, dynamic> json) {
    return VehicleEmissionFactor(
      vehicleType: json['vehicle_type'] as String,
      ccMin: json['cc_min'] as int,
      ccMax: json['cc_max'] as int,
      emissionMin: (json['emission_min'] as num).toDouble(),
      emissionMax: (json['emission_max'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'vehicle_type': vehicleType,
        'cc_min': ccMin,
        'cc_max': ccMax,
        'emission_min': emissionMin,
        'emission_max': emissionMax,
        'emission_average': emissionAverage,
      };

  /// Check if CC falls within this range
  bool isInRange(int cc) {
    return cc >= ccMin && (ccMax == 0 ? true : cc <= ccMax);
  }

  /// Get display name for CC range
  String get ccRangeDisplay {
    if (ccMax == 0) {
      return '${ccMin}+ cc';
    }
    return '$ccMin-$ccMax cc';
  }

  /// Get emission range display
  String get emissionRangeDisplay {
    return '${emissionMin.toStringAsFixed(2)}-${emissionMax.toStringAsFixed(2)} kg/km';
  }

  @override
  String toString() {
    return 'VehicleEmissionFactor($vehicleType: $ccRangeDisplay = $emissionRangeDisplay)';
  }
}

class VehicleEmissionCalculator {
  // Predefined emission factors based on the document
  static final List<VehicleEmissionFactor> _emissionFactors = [
    // MOBIL BENSIN
    VehicleEmissionFactor(
      vehicleType: 'car',
      ccMin: 0,
      ccMax: 999,
      emissionMin: 0.11,
      emissionMax: 0.13,
    ),
    VehicleEmissionFactor(
      vehicleType: 'car',
      ccMin: 1000,
      ccMax: 1400,
      emissionMin: 0.13,
      emissionMax: 0.16,
    ),
    VehicleEmissionFactor(
      vehicleType: 'car',
      ccMin: 1401,
      ccMax: 2000,
      emissionMin: 0.16,
      emissionMax: 0.21,
    ),
    VehicleEmissionFactor(
      vehicleType: 'car',
      ccMin: 2001,
      ccMax: 3000,
      emissionMin: 0.21,
      emissionMax: 0.28,
    ),
    VehicleEmissionFactor(
      vehicleType: 'car',
      ccMin: 3001,
      ccMax: 0, // 0 means no upper limit
      emissionMin: 0.28,
      emissionMax: 0.40,
    ),
    
    // MOTOR
    VehicleEmissionFactor(
      vehicleType: 'motorcycle',
      ccMin: 0,
      ccMax: 124,
      emissionMin: 0.04,
      emissionMax: 0.06,
    ),
    VehicleEmissionFactor(
      vehicleType: 'motorcycle',
      ccMin: 125,
      ccMax: 250,
      emissionMin: 0.06,
      emissionMax: 0.09,
    ),
    VehicleEmissionFactor(
      vehicleType: 'motorcycle',
      ccMin: 251,
      ccMax: 500,
      emissionMin: 0.09,
      emissionMax: 0.12,
    ),
    VehicleEmissionFactor(
      vehicleType: 'motorcycle',
      ccMin: 501,
      ccMax: 750,
      emissionMin: 0.12,
      emissionMax: 0.15,
    ),
    VehicleEmissionFactor(
      vehicleType: 'motorcycle',
      ccMin: 751,
      ccMax: 0, // 0 means no upper limit
      emissionMin: 0.15,
      emissionMax: 0.20,
    ),
  ];

  /// Get emission factor for specific vehicle type and CC
  static VehicleEmissionFactor? getEmissionFactor(String vehicleType, int cc) {
    // Map vehicle type to standard format
    final mappedType = _mapVehicleType(vehicleType);
    
    // Handle special cases for zero-emission vehicles
    if (mappedType == 'bicycle') {
      return VehicleEmissionFactor(
        vehicleType: 'bicycle',
        ccMin: 0,
        ccMax: 0,
        emissionMin: 0.0,
        emissionMax: 0.0,
      );
    }
    
    try {
      return _emissionFactors.firstWhere(
        (factor) => factor.vehicleType == mappedType && factor.isInRange(cc),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate total emission for a trip
  static double calculateEmission({
    required String vehicleType,
    required int engineCC,
    required double distanceKm,
  }) {
    // Map vehicle type to standard format
    final mappedType = _mapVehicleType(vehicleType);
    
    // Handle special cases for zero-emission vehicles
    if (mappedType == 'bicycle') {
      return 0.0; // Bicycles have zero emissions
    }
    
    final factor = getEmissionFactor(mappedType, engineCC);
    if (factor == null) {
      // If no factor found, assume zero emission (could be electric or other zero-emission vehicle)
      return 0.0;
    }
    
    return factor.emissionAverage * distanceKm;
  }

  /// Get all available emission factors
  static List<VehicleEmissionFactor> getAllEmissionFactors() {
    return List.unmodifiable(_emissionFactors);
  }

  /// Get emission factors by vehicle type
  static List<VehicleEmissionFactor> getEmissionFactorsByType(String vehicleType) {
    return _emissionFactors.where((factor) => factor.vehicleType == vehicleType).toList();
  }

  /// Calculate carbon offset from donation
  static Map<String, dynamic> calculateCarbonOffset(double donationAmount) {
    const double rupiahPerTree = 10000;
    const double co2PerTreeKg = 21;
    
    final treeCount = (donationAmount / rupiahPerTree).floor();
    final co2Offset = treeCount * co2PerTreeKg;
    
    return {
      'donation_amount': donationAmount,
      'tree_count': treeCount,
      'co2_offset_kg': co2Offset,
      'rupiah_per_tree': rupiahPerTree,
      'co2_per_tree_kg': co2PerTreeKg,
    };
  }

  /// Validate vehicle type
  static bool isValidVehicleType(String vehicleType) {
    return vehicleType == 'car' || 
           vehicleType == 'motorcycle' || 
           vehicleType.toLowerCase() == 'sepeda' || 
           vehicleType.toLowerCase() == 'bicycle';
  }

  /// Get vehicle type display name
  static String getVehicleTypeDisplayName(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return 'Mobil';
      case 'motorcycle':
        return 'Motor';
      case 'sepeda':
      case 'bicycle':
        return 'Sepeda';
      default:
        return vehicleType;
    }
  }

  /// Map vehicle type from UI to standard database format
  static String _mapVehicleType(String vehicleType) {
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
        return vehicleType; // Return as-is if no mapping found
    }
  }
}

/// Trip tracking model
class TripTracking {
  final String id;
  final String userId;
  final String vehicleType;
  final int engineCC;
  final double distanceKm;
  final double emissionKg;
  final double emissionFactor;
  final String? startLocation;
  final String? endLocation;
  final DateTime tripDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripTracking({
    required this.id,
    required this.userId,
    required this.vehicleType,
    required this.engineCC,
    required this.distanceKm,
    required this.emissionKg,
    required this.emissionFactor,
    this.startLocation,
    this.endLocation,
    required this.tripDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripTracking.fromJson(Map<String, dynamic> json) {
    return TripTracking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleType: json['vehicle_type'] as String,
      engineCC: json['engine_cc'] as int,
      distanceKm: (json['distance_km'] as num).toDouble(),
      emissionKg: (json['emission_kg'] as num).toDouble(),
      emissionFactor: (json['emission_factor'] as num).toDouble(),
      startLocation: json['start_location'] as String?,
      endLocation: json['end_location'] as String?,
      tripDate: DateTime.parse(json['trip_date'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vehicle_type': vehicleType,
        'engine_cc': engineCC,
        'distance_km': distanceKm,
        'emission_kg': emissionKg,
        'emission_factor': emissionFactor,
        'start_location': startLocation,
        'end_location': endLocation,
        'trip_date': tripDate.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Get formatted emission
  String get formattedEmission {
    return '${emissionKg.toStringAsFixed(2)} kg CO₂';
  }

  /// Get formatted distance
  String get formattedDistance {
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Get vehicle type display name
  String get vehicleTypeDisplayName {
    return VehicleEmissionCalculator.getVehicleTypeDisplayName(vehicleType);
  }

  /// Get formatted trip date
  String get formattedTripDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${tripDate.day} ${months[tripDate.month - 1]} ${tripDate.year}';
  }

  @override
  String toString() {
    return 'TripTracking(id: $id, vehicleType: $vehicleType, distance: ${distanceKm}km, emission: ${emissionKg}kg)';
  }
}