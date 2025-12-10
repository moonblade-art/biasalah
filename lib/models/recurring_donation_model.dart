// lib/models/recurring_donation_model.dart

enum RecurringFrequency {
  weekly,
  monthly,
  quarterly,
  yearly;

  String get displayName {
    switch (this) {
      case RecurringFrequency.weekly:
        return 'Mingguan';
      case RecurringFrequency.monthly:
        return 'Bulanan';
      case RecurringFrequency.quarterly:
        return 'Triwulan';
      case RecurringFrequency.yearly:
        return 'Tahunan';
    }
  }

  int get intervalDays {
    switch (this) {
      case RecurringFrequency.weekly:
        return 7;
      case RecurringFrequency.monthly:
        return 30;
      case RecurringFrequency.quarterly:
        return 90;
      case RecurringFrequency.yearly:
        return 365;
    }
  }
}

class PaymentMethod {
  final String id;
  final String type; // 'credit_card', 'bank_transfer', 'e_wallet'
  final String displayName;
  final String? maskedNumber;
  final bool isDefault;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.displayName,
    this.maskedNumber,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      type: json['type'] as String,
      displayName: json['display_name'] as String,
      maskedNumber: json['masked_number'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'display_name': displayName,
        'masked_number': maskedNumber,
        'is_default': isDefault,
      };
}

class RecurringDonation {
  final String id;
  final String userId;
  final String communityId;
  final double carbonAmount;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final PaymentMethod paymentMethod;
  final int failedAttempts;
  final DateTime? lastProcessedAt;
  final DateTime? nextProcessingDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for joined data
  final String? communityName;
  final String? communityLocation;
  final double? communityPricePerKg;

  RecurringDonation({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.carbonAmount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.paymentMethod,
    this.failedAttempts = 0,
    this.lastProcessedAt,
    this.nextProcessingDate,
    required this.createdAt,
    required this.updatedAt,
    this.communityName,
    this.communityLocation,
    this.communityPricePerKg,
  });

  factory RecurringDonation.fromJson(Map<String, dynamic> json) {
    return RecurringDonation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      communityId: json['community_id'] as String,
      carbonAmount: (json['carbon_amount'] as num).toDouble(),
      frequency: RecurringFrequency.values.firstWhere(
        (f) => f.name == json['frequency'],
        orElse: () => RecurringFrequency.monthly,
      ),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      isActive: json['is_active'] as bool? ?? true,
      paymentMethod: PaymentMethod.fromJson(json['payment_method'] as Map<String, dynamic>),
      failedAttempts: json['failed_attempts'] as int? ?? 0,
      lastProcessedAt: json['last_processed_at'] != null 
          ? DateTime.parse(json['last_processed_at'] as String) 
          : null,
      nextProcessingDate: json['next_processing_date'] != null 
          ? DateTime.parse(json['next_processing_date'] as String) 
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      communityName: json['community_name'] as String?,
      communityLocation: json['community_location'] as String?,
      communityPricePerKg: json['community_price_per_kg'] != null 
          ? (json['community_price_per_kg'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'community_id': communityId,
        'carbon_amount': carbonAmount,
        'frequency': frequency.name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive,
        'payment_method': paymentMethod.toJson(),
        'failed_attempts': failedAttempts,
        'last_processed_at': lastProcessedAt?.toIso8601String(),
        'next_processing_date': nextProcessingDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Calculate donation amount based on community pricing
  double get donationAmount {
    if (communityPricePerKg != null) {
      return carbonAmount * communityPricePerKg!;
    }
    return carbonAmount * 5000.0; // Default price per kg
  }

  /// Get formatted donation amount
  String get formattedDonationAmount {
    return 'Rp ${donationAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// Get formatted carbon amount
  String get formattedCarbonAmount {
    return '${carbonAmount.toStringAsFixed(2)} kg CO₂';
  }

  /// Check if subscription is due for processing
  bool get isDue {
    if (!isActive || nextProcessingDate == null) return false;
    return DateTime.now().isAfter(nextProcessingDate!);
  }

  /// Check if subscription has too many failed attempts
  bool get hasExceededFailureLimit => failedAttempts >= 3;

  /// Get status display
  String get statusDisplay {
    if (!isActive) return 'Tidak Aktif';
    if (hasExceededFailureLimit) return 'Ditangguhkan';
    if (isDue) return 'Menunggu Proses';
    return 'Aktif';
  }

  /// Calculate next processing date
  DateTime calculateNextProcessingDate() {
    final baseDate = lastProcessedAt ?? startDate;
    return baseDate.add(Duration(days: frequency.intervalDays));
  }

  RecurringDonation copyWith({
    String? id,
    String? userId,
    String? communityId,
    double? carbonAmount,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    PaymentMethod? paymentMethod,
    int? failedAttempts,
    DateTime? lastProcessedAt,
    DateTime? nextProcessingDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? communityName,
    String? communityLocation,
    double? communityPricePerKg,
  }) {
    return RecurringDonation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      carbonAmount: carbonAmount ?? this.carbonAmount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastProcessedAt: lastProcessedAt ?? this.lastProcessedAt,
      nextProcessingDate: nextProcessingDate ?? this.nextProcessingDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      communityName: communityName ?? this.communityName,
      communityLocation: communityLocation ?? this.communityLocation,
      communityPricePerKg: communityPricePerKg ?? this.communityPricePerKg,
    );
  }

  @override
  String toString() {
    return 'RecurringDonation(id: $id, carbonAmount: $carbonAmount, frequency: ${frequency.name}, isActive: $isActive)';
  }
}

/// Request model for creating recurring donations
class RecurringDonationRequest {
  final String communityId;
  final double carbonAmount;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final PaymentMethod paymentMethod;

  RecurringDonationRequest({
    required this.communityId,
    required this.carbonAmount,
    required this.frequency,
    required this.startDate,
    this.endDate,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'community_id': communityId,
        'carbon_amount': carbonAmount,
        'frequency': frequency.name,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'payment_method': paymentMethod.toJson(),
      };
}