// lib/models/community_model.dart

import 'package:flutter/material.dart';

class Community {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final String location;
  final String focusArea;
  final double carbonPricePerKg;
  final double totalDonations;
  final double totalCarbonOffset;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Community({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.location,
    required this.focusArea,
    required this.carbonPricePerKg,
    this.totalDonations = 0.0,
    this.totalCarbonOffset = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String,
      focusArea: json['focus_area'] as String,
      carbonPricePerKg: (json['carbon_price_per_kg'] as num).toDouble(),
      totalDonations: (json['total_donations'] as num?)?.toDouble() ?? 0.0,
      totalCarbonOffset: (json['total_carbon_offset'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'image_url': imageUrl,
        'location': location,
        'focus_area': focusArea,
        'carbon_price_per_kg': carbonPricePerKg,
        'total_donations': totalDonations,
        'total_carbon_offset': totalCarbonOffset,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Get formatted price per kg
  String get formattedPricePerKg {
    return 'Rp ${carbonPricePerKg.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// Get focus area display name
  String get focusAreaDisplayName {
    switch (focusArea) {
      case 'reforestation':
        return 'Reboisasi';
      case 'renewable_energy':
        return 'Energi Terbarukan';
      case 'waste_management':
        return 'Pengelolaan Limbah';
      case 'ocean_conservation':
        return 'Konservasi Laut';
      case 'urban_forest':
        return 'Hutan Kota';
      default:
        return focusArea;
    }
  }

  /// Calculate donation amount for given carbon amount
  double calculateDonationAmount(double carbonKg) {
    return carbonKg * carbonPricePerKg;
  }

  /// Calculate carbon amount for given donation amount
  double calculateCarbonAmount(double donationAmount) {
    return donationAmount / carbonPricePerKg;
  }

  /// Get formatted total donations
  String get formattedTotalDonations {
    return 'Rp ${totalDonations.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// Get formatted total carbon offset
  String get formattedTotalCarbonOffset {
    return '${totalCarbonOffset.toStringAsFixed(2)} kg CO₂';
  }

  /// Get focus area icon
  IconData get focusAreaIcon {
    switch (focusArea) {
      case 'reforestation':
        return Icons.forest;
      case 'renewable_energy':
        return Icons.wb_sunny;
      case 'waste_management':
        return Icons.recycling;
      case 'ocean_conservation':
        return Icons.waves;
      case 'urban_forest':
        return Icons.park;
      default:
        return Icons.eco;
    }
  }

  /// Get focus area color
  Color get focusAreaColor {
    switch (focusArea) {
      case 'reforestation':
        return Colors.green;
      case 'renewable_energy':
        return Colors.orange;
      case 'waste_management':
        return Colors.blue;
      case 'ocean_conservation':
        return Colors.cyan;
      case 'urban_forest':
        return Colors.lightGreen;
      default:
        return Colors.grey;
    }
  }

  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? location,
    String? focusArea,
    double? carbonPricePerKg,
    double? totalDonations,
    double? totalCarbonOffset,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      focusArea: focusArea ?? this.focusArea,
      carbonPricePerKg: carbonPricePerKg ?? this.carbonPricePerKg,
      totalDonations: totalDonations ?? this.totalDonations,
      totalCarbonOffset: totalCarbonOffset ?? this.totalCarbonOffset,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Community(id: $id, name: $name, location: $location, focusArea: $focusArea)';
  }
}