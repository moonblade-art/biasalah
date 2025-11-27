// lib/models/user_model.dart

class UserProfile {
  final String? id;
  final String userId; // Reference to auth.users.id
  final String fullName;
  final String email;
  final double emisiOffset;
  final double emisiBelum;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserProfile({
    this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.emisiOffset = 0.0,
    this.emisiBelum = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      emisiOffset: (json['emisi_offset'] as num?)?.toDouble() ?? 0.0,
      emisiBelum: (json['emisi_belum'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'emisi_offset': emisiOffset,
        'emisi_belum': emisiBelum,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Create a copy with updated values
  UserProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? email,
    double? emisiOffset,
    double? emisiBelum,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      emisiOffset: emisiOffset ?? this.emisiOffset,
      emisiBelum: emisiBelum ?? this.emisiBelum,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Validate user profile data
  bool isValid() {
    return fullName.isNotEmpty && 
           email.isNotEmpty && 
           email.contains('@') &&
           userId.isNotEmpty;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, userId: $userId, fullName: $fullName, email: $email, emisiOffset: $emisiOffset, emisiBelum: $emisiBelum)';
  }
}

// Keep the old User class for backward compatibility during migration
@Deprecated('Use UserProfile instead')
class User {
  final String name;
  final String email;
  final String password;
  final double emisiOffset;
  final double emisiBelum;

  User({
    required this.name,
    required this.email,
    required this.password,
    required this.emisiOffset,
    required this.emisiBelum,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      emisiOffset: (json['emisi_offset'] as num).toDouble(),
      emisiBelum: (json['emisi_belum'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'emisi_offset': emisiOffset,
        'emisi_belum': emisiBelum,
      };
}
