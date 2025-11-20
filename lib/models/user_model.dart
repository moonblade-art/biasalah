class User {
  final int idPengguna;
  final String email;
  final String kataSandiHash;
  final String roles;
  final DateTime dibuatPada;
  final DateTime diperbaruiPada;
  final DateTime passwordUpdatedAt;
  final int passwordLevel;
  final double emisiOffset;
  final double emisiBelum;

  User({
    required this.idPengguna,
    required this.email,
    required this.kataSandiHash,
    required this.roles,
    required this.dibuatPada,
    required this.diperbaruiPada,
    required this.passwordUpdatedAt,
    required this.passwordLevel,
    required this.emisiOffset,
    required this.emisiBelum,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idPengguna: json['id_pengguna'] as int,
      email: json['email'] as String,
      kataSandiHash: json['kata_sandi_hash'] as String,
      roles: json['roles'] as String,
      dibuatPada: DateTime.parse(json['dibuat_pada']),
      diperbaruiPada: DateTime.parse(json['diperbarui_pada']),
      passwordUpdatedAt: DateTime.parse(json['password_updated_at']),
      passwordLevel: json['password_level'] as int,
      emisiOffset: (json['emisi_offset'] as num).toDouble(),
      emisiBelum: (json['emisi_belum'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id_pengguna': idPengguna,
    'email': email,
    'kata_sandi_hash': kataSandiHash,
    'roles': roles,
    'dibuat_pada': dibuatPada.toIso8601String(),
    'diperbarui_pada': diperbaruiPada.toIso8601String(),
    'password_updated_at': passwordUpdatedAt.toIso8601String(),
    'password_level': passwordLevel,
    'emisi_offset': emisiOffset,
    'emisi_belum': emisiBelum,
  };

  // Tambahkan getter untuk name dari email (sebagai alternatif)
  String get name {
    // Ambil nama dari bagian sebelum @ di email
    return email.split('@').first;
  }
}