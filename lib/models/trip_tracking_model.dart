import 'package:latlong2/latlong.dart';

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
  final double? startLatitude;
  final double? startLongitude;
  final double? endLatitude;
  final double? endLongitude;
  final DateTime tripDate;
  final int? tripDurationMinutes;
  final String? notes;
  final String? title;
  final List<LatLng>? routePoints;
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
    this.startLatitude,
    this.startLongitude,
    this.endLatitude,
    this.endLongitude,
    required this.tripDate,
    this.tripDurationMinutes,
    this.notes,
    this.title,
    this.routePoints,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripTracking.fromJson(Map<String, dynamic> json) {
    return TripTracking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      vehicleType: json['vehicle_type'] as String,
      engineCC: (json['vehicle_cc'] ?? json['engine_cc'] ?? 1500) as int,
      distanceKm: (json['distance_km'] ?? json['distance'] ?? 0).toDouble(),
      emissionKg: (json['co2_emission'] ?? json['emission_kg'] ?? json['emission'] ?? 0).toDouble(),
      emissionFactor: (json['emission_factor'] ?? 0.15).toDouble(),
      startLocation: json['start_location'] as String?,
      endLocation: json['end_location'] as String?,
      startLatitude: json['start_latitude'] != null 
          ? (json['start_latitude'] as num).toDouble() 
          : null,
      startLongitude: json['start_longitude'] != null 
          ? (json['start_longitude'] as num).toDouble() 
          : null,
      endLatitude: json['end_latitude'] != null 
          ? (json['end_latitude'] as num).toDouble() 
          : null,
      endLongitude: json['end_longitude'] != null 
          ? (json['end_longitude'] as num).toDouble() 
          : null,
      tripDate: json['trip_date'] != null 
          ? DateTime.parse(json['trip_date'] as String)
          : DateTime.parse(json['created_at'] as String),
      tripDurationMinutes: json['trip_duration_minutes'] as int?,
      notes: json['notes'] as String?,
      title: json['title'] as String?,
      routePoints: (json['route_points'] as List?)
          ?.map((point) => LatLng(
                (point['lat'] ?? point['latitude'] as num).toDouble(),
                (point['lng'] ?? point['longitude'] as num).toDouble(),
              ))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'vehicle_type': vehicleType,
      'engine_cc': engineCC,
      'distance_km': distanceKm,
      'emission_kg': emissionKg,
      'emission_factor': emissionFactor,
      'start_location': startLocation,
      'end_location': endLocation,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'end_latitude': endLatitude,
      'end_longitude': endLongitude,
      'trip_date': tripDate.toIso8601String().split('T')[0],
      'trip_duration_minutes': tripDurationMinutes,
      'notes': notes,
      'title': title,
      'route_points': routePoints?.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper getters
  String get vehicleTypeDisplay {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return 'Mobil';
      case 'motorcycle':
        return 'Motor';
      case 'bus':
        return 'Bus';
      case 'truck':
        return 'Truk';
      default:
        return vehicleType;
    }
  }

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedEmission => '${emissionKg.toStringAsFixed(2)} kg CO₂';
  String get formattedEmissionFactor => '${emissionFactor.toStringAsFixed(4)} kg/km';

  String get routeDescription {
    if (startLocation != null && endLocation != null) {
      return '$startLocation → $endLocation';
    } else if (startLocation != null) {
      return 'Dari $startLocation';
    } else if (endLocation != null) {
      return 'Ke $endLocation';
    } else {
      return 'Perjalanan ${formattedDistance}';
    }
  }

  String get durationDescription {
    if (tripDurationMinutes == null) return '';
    
    final hours = tripDurationMinutes! ~/ 60;
    final minutes = tripDurationMinutes! % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Calculate carbon offset cost (assuming Rp 5,000 per kg CO2)
  double get offsetCost => emissionKg * 5000;
  String get formattedOffsetCost => 'Rp ${offsetCost.toStringAsFixed(0)}';

  // Calculate tree equivalent (assuming 21 kg CO2 per tree per year)
  double get treeEquivalent => emissionKg / 21;
  String get formattedTreeEquivalent => '${treeEquivalent.toStringAsFixed(1)} pohon';

  @override
  String toString() {
    return 'TripTracking(id: $id, vehicleType: $vehicleType, distance: $formattedDistance, emission: $formattedEmission)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TripTracking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}