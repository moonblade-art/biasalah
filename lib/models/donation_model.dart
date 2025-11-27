// lib/models/donation_model.dart

class Donation {
  final String id;
  final String userId;
  final String communityId;
  final double amount;
  final double carbonAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String? transactionId;
  final String? midtransOrderId;
  final String? paymentUrl;
  final String? notes;
  final DateTime donatedAt;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for joined data
  final String? communityName;
  final String? communityLocation;
  final String? communityFocusArea;

  Donation({
    required this.id,
    required this.userId,
    required this.communityId,
    required this.amount,
    required this.carbonAmount,
    required this.paymentMethod,
    this.paymentStatus = 'pending',
    this.transactionId,
    this.midtransOrderId,
    this.paymentUrl,
    this.notes,
    required this.donatedAt,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    this.communityName,
    this.communityLocation,
    this.communityFocusArea,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      communityId: json['community_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      carbonAmount: (json['carbon_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String,
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      transactionId: json['transaction_id'] as String?,
      midtransOrderId: json['midtrans_order_id'] as String?,
      paymentUrl: json['payment_url'] as String?,
      notes: json['notes'] as String?,
      donatedAt: DateTime.parse(json['donated_at'] as String),
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      communityName: json['community_name'] as String?,
      communityLocation: json['community_location'] as String?,
      communityFocusArea: json['community_focus_area'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'community_id': communityId,
        'amount': amount,
        'carbon_amount': carbonAmount,
        'payment_method': paymentMethod,
        'payment_status': paymentStatus,
        'transaction_id': transactionId,
        'midtrans_order_id': midtransOrderId,
        'payment_url': paymentUrl,
        'notes': notes,
        'donated_at': donatedAt.toIso8601String(),
        'paid_at': paidAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  /// Get formatted donation amount
  String get formattedAmount {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  /// Get formatted carbon amount
  String get formattedCarbonAmount {
    return '${carbonAmount.toStringAsFixed(2)} kg CO₂';
  }

  /// Get payment status display name
  String get paymentStatusDisplayName {
    switch (paymentStatus) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'success':
        return 'Berhasil';
      case 'failed':
        return 'Gagal';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return paymentStatus;
    }
  }

  /// Get payment method display name
  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case 'midtrans':
        return 'Midtrans';
      case 'bank_transfer':
        return 'Transfer Bank';
      case 'e_wallet':
        return 'E-Wallet';
      case 'credit_card':
        return 'Kartu Kredit';
      default:
        return paymentMethod;
    }
  }

  /// Check if donation is successful
  bool get isSuccessful => paymentStatus == 'success';

  /// Check if donation is pending
  bool get isPending => paymentStatus == 'pending';

  /// Check if donation is failed
  bool get isFailed => paymentStatus == 'failed' || paymentStatus == 'cancelled';

  /// Get status color
  String get statusColor {
    switch (paymentStatus) {
      case 'success':
        return '#4CAF50'; // Green
      case 'pending':
        return '#FF9800'; // Orange
      case 'failed':
      case 'cancelled':
        return '#F44336'; // Red
      default:
        return '#9E9E9E'; // Grey
    }
  }

  /// Format donated date
  String get formattedDonatedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    
    return '${donatedAt.day} ${months[donatedAt.month - 1]} ${donatedAt.year}';
  }

  /// Format donated time
  String get formattedDonatedTime {
    return '${donatedAt.hour.toString().padLeft(2, '0')}:${donatedAt.minute.toString().padLeft(2, '0')}';
  }

  Donation copyWith({
    String? id,
    String? userId,
    String? communityId,
    double? amount,
    double? carbonAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? transactionId,
    String? midtransOrderId,
    String? paymentUrl,
    String? notes,
    DateTime? donatedAt,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? communityName,
    String? communityLocation,
    String? communityFocusArea,
  }) {
    return Donation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      communityId: communityId ?? this.communityId,
      amount: amount ?? this.amount,
      carbonAmount: carbonAmount ?? this.carbonAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      midtransOrderId: midtransOrderId ?? this.midtransOrderId,
      paymentUrl: paymentUrl ?? this.paymentUrl,
      notes: notes ?? this.notes,
      donatedAt: donatedAt ?? this.donatedAt,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      communityName: communityName ?? this.communityName,
      communityLocation: communityLocation ?? this.communityLocation,
      communityFocusArea: communityFocusArea ?? this.communityFocusArea,
    );
  }

  @override
  String toString() {
    return 'Donation(id: $id, amount: $amount, carbonAmount: $carbonAmount, status: $paymentStatus)';
  }
}

/// Donation request model for creating new donations
class DonationRequest {
  final String communityId;
  final double carbonAmount;
  final String paymentMethod;
  final String? notes;

  DonationRequest({
    required this.communityId,
    required this.carbonAmount,
    this.paymentMethod = 'midtrans',
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'community_id': communityId,
        'carbon_amount': carbonAmount,
        'payment_method': paymentMethod,
        'notes': notes,
      };
}