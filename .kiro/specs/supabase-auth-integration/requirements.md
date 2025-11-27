# Requirements Document

## Introduction

Sistem autentikasi EcoTrack saat ini menggunakan dummy JSON file untuk login. Sistem perlu diintegrasikan dengan Supabase untuk menyediakan autentikasi yang aman dan real-time dengan fitur login, registrasi, verifikasi email, dan reset password.

## Glossary

- **Supabase**: Platform Backend-as-a-Service yang menyediakan database PostgreSQL dan autentikasi
- **Auth System**: Sistem autentikasi Supabase yang mengelola user authentication
- **Email Verification**: Proses verifikasi email pengguna melalui kode OTP atau link
- **Password Reset**: Proses reset password melalui email verification
- **User Profile**: Data profil pengguna yang disimpan di database
- **Session**: Sesi autentikasi pengguna yang aktif

## Requirements

### Requirement 1

**User Story:** Sebagai pengguna baru, saya ingin mendaftar akun dengan email dan password, sehingga saya dapat menggunakan aplikasi EcoTrack

#### Acceptance Criteria

1. WHEN pengguna mengisi form registrasi dengan nama, email, dan password THEN sistem SHALL membuat akun baru di Supabase Auth
2. WHEN akun berhasil dibuat THEN sistem SHALL mengirim email verifikasi ke alamat email pengguna
3. WHEN email atau password tidak valid THEN sistem SHALL menampilkan pesan error yang jelas
4. WHEN email sudah terdaftar THEN sistem SHALL menampilkan pesan bahwa email sudah digunakan
5. WHEN registrasi berhasil THEN sistem SHALL mengarahkan pengguna ke halaman verifikasi email

### Requirement 2

**User Story:** Sebagai pengguna terdaftar, saya ingin login dengan email dan password, sehingga saya dapat mengakses akun saya

#### Acceptance Criteria

1. WHEN pengguna memasukkan email dan password yang benar THEN sistem SHALL mengautentikasi pengguna dan membuat session
2. WHEN autentikasi berhasil THEN sistem SHALL mengarahkan pengguna ke halaman home
3. WHEN email atau password salah THEN sistem SHALL menampilkan pesan error "Email atau password salah"
4. WHEN email belum diverifikasi THEN sistem SHALL menampilkan pesan untuk verifikasi email terlebih dahulu
5. WHEN terjadi error koneksi THEN sistem SHALL menampilkan pesan error yang informatif

### Requirement 3

**User Story:** Sebagai pengguna yang lupa password, saya ingin mereset password melalui email, sehingga saya dapat mengakses akun saya kembali

#### Acceptance Criteria

1. WHEN pengguna memasukkan email terdaftar di halaman lupa password THEN sistem SHALL mengirim email reset password
2. WHEN email reset password terkirim THEN sistem SHALL mengarahkan ke halaman verifikasi kode
3. WHEN pengguna memasukkan kode verifikasi yang benar THEN sistem SHALL mengizinkan pengguna membuat password baru
4. WHEN password baru valid THEN sistem SHALL mengupdate password di Supabase Auth
5. WHEN email tidak terdaftar THEN sistem SHALL menampilkan pesan bahwa email tidak ditemukan

### Requirement 4

**User Story:** Sebagai pengguna, saya ingin data profil saya disimpan di database, sehingga informasi emisi saya tersimpan dengan aman

#### Acceptance Criteria

1. WHEN pengguna berhasil registrasi THEN sistem SHALL membuat record profil di tabel users dengan emisi_offset dan emisi_belum bernilai 0
2. WHEN pengguna login THEN sistem SHALL mengambil data profil dari database
3. WHEN data profil berhasil diambil THEN sistem SHALL menyimpan data di state management aplikasi
4. WHEN terjadi error database THEN sistem SHALL menampilkan pesan error dan tetap mengizinkan login
5. THE sistem SHALL menyimpan user_id dari Supabase Auth sebagai foreign key di tabel users

### Requirement 5

**User Story:** Sebagai developer, saya ingin konfigurasi Supabase yang mudah, sehingga integrasi dapat dilakukan dengan cepat

#### Acceptance Criteria

1. THE sistem SHALL menggunakan environment variables untuk menyimpan Supabase URL dan API key
2. THE sistem SHALL menyediakan service class untuk mengelola operasi Supabase
3. THE sistem SHALL menangani error dengan graceful error handling
4. THE sistem SHALL menyediakan loading state untuk semua operasi async
5. THE sistem SHALL menggunakan supabase_flutter package versi terbaru
