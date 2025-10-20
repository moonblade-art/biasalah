// lib/models/user_model.dart

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
