// lib/models/dummy_users.dart
import 'user_model.dart';

final List<User> dummyUsers = [
User(
  idPengguna: 1,
  email: "hady@example.com",
  kataSandiHash: "hashed_password",
  roles: "user",
  dibuatPada: DateTime.now(),
  diperbaruiPada: DateTime.now(),
  passwordUpdatedAt: DateTime.now(),
  passwordLevel: 2,
  emisiOffset: 5.0,
  emisiBelum: 6.0,
),
User(
  idPengguna: 2,
  email: "addin@example.com",
  kataSandiHash: "hashed_password",
  roles: "user",
  dibuatPada: DateTime.now(),
  diperbaruiPada: DateTime.now(),
  passwordUpdatedAt: DateTime.now(),
  passwordLevel: 2,
  emisiOffset: 3.0,
  emisiBelum: 2.0,
),
];
