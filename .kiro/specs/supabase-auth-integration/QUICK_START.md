# 🚀 Quick Start Guide - Supabase Integration

## ⚡ Setup Cepat (5 Menit)

### 1️⃣ Setup Database di Supabase (2 menit)

1. Buka [Supabase Dashboard](https://app.supabase.com)
2. Pilih project Anda
3. Klik **SQL Editor** di sidebar kiri
4. Klik **New Query**
5. Copy seluruh isi file `supabase-schema.sql`
6. Paste ke SQL Editor
7. Klik **Run** (atau tekan Ctrl+Enter)
8. Tunggu sampai muncul "Success. No rows returned"

✅ **Database siap!** Tabel `users` dan `trip_history` sudah dibuat dengan Row Level Security.

### 2️⃣ Enable Email Authentication (1 menit)

1. Di Supabase Dashboard, klik **Authentication** → **Providers**
2. Cari **Email** provider
3. Toggle **Enable Email provider** menjadi ON
4. **Enable email confirmations** → ON (untuk verifikasi email)
5. Klik **Save**

✅ **Email auth aktif!**

### 3️⃣ Konfigurasi Email Templates (Opsional - 2 menit)

1. Klik **Authentication** → **Email Templates**
2. Edit template **Confirm signup**:
   ```
   Subject: Verifikasi Email EcoTrack
   
   Halo,
   
   Terima kasih telah mendaftar di EcoTrack!
   Klik link di bawah untuk verifikasi email Anda:
   
   {{ .ConfirmationURL }}
   
   Link ini akan kadaluarsa dalam 24 jam.
   
   Salam,
   Tim EcoTrack
   ```

3. Edit template **Reset password**:
   ```
   Subject: Reset Password EcoTrack
   
   Halo,
   
   Anda meminta reset password untuk akun EcoTrack Anda.
   Klik link di bawah untuk membuat password baru:
   
   {{ .ConfirmationURL }}
   
   Jika Anda tidak meminta reset password, abaikan email ini.
   
   Salam,
   Tim EcoTrack
   ```

4. Klik **Save** untuk setiap template

✅ **Email templates siap!**

---

## 📋 Informasi Koneksi Anda

```dart
Supabase URL: https://yfisgogkoewxllkhupka.supabase.co
Anon Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8
```

---

## 🔧 Implementasi di Flutter

### Step 1: Tambah Dependencies

Tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.5.0
  shared_preferences: ^2.3.2  # Sudah ada
```

Jalankan:
```bash
flutter pub get
```

### Step 2: Struktur File yang Akan Dibuat

```
lib/
├── config/
│   └── supabase_config.dart          # Konfigurasi Supabase
├── services/
│   ├── supabase_auth_service.dart    # Service untuk autentikasi
│   └── user_profile_service.dart     # Service untuk profil user
├── models/
│   └── user_profile.dart             # Model user profile (update)
└── screens/auth/
    ├── login_screen.dart             # Update dengan Supabase
    ├── register_page.dart            # Update dengan Supabase
    ├── forgot_password_page.dart     # Update dengan Supabase
    └── verify_page.dart              # Update untuk verifikasi
```

---

## 📝 Task List untuk Implementasi

Buka file `.kiro/specs/supabase-auth-integration/tasks.md` untuk melihat task list lengkap.

**Urutan implementasi:**
1. ✅ Setup Supabase di dashboard (SELESAI - Anda baru saja melakukan ini!)
2. ⏳ Setup konfigurasi di Flutter
3. ⏳ Buat service classes
4. ⏳ Update UI screens
5. ⏳ Testing

---

## 🧪 Testing Setelah Implementasi

### Test Registration Flow:
1. Buka app → Klik "Daftar"
2. Isi form registrasi
3. Klik "Daftar"
4. Cek email untuk link verifikasi
5. Klik link verifikasi
6. Login dengan akun baru

### Test Login Flow:
1. Buka app → Klik "Masuk"
2. Masukkan email & password
3. Klik "Masuk"
4. Harus masuk ke home screen

### Test Forgot Password:
1. Klik "Lupa kata sandi?"
2. Masukkan email
3. Cek email untuk link reset
4. Klik link dan buat password baru
5. Login dengan password baru

---

## 🔍 Verifikasi Database

Setelah registrasi pertama, cek di Supabase:

1. **Table Editor** → **auth.users** → Harus ada user baru
2. **Table Editor** → **public.users** → Harus ada profile dengan emisi_offset = 0, emisi_belum = 0
3. **Authentication** → **Users** → Harus muncul user dengan status "Confirmed" (setelah verifikasi email)

---

## ❗ Troubleshooting

### Error: "Email not confirmed"
- User belum klik link verifikasi di email
- Cek spam folder
- Atau disable email confirmation di Supabase (tidak disarankan untuk production)

### Error: "Invalid API key"
- Pastikan Anon Key benar
- Cek di Supabase Dashboard → Settings → API

### Error: "Row Level Security policy violation"
- Pastikan SQL script sudah dijalankan dengan benar
- Cek policies di Table Editor → users → Policies

### Email tidak terkirim
- Cek Supabase logs: Authentication → Logs
- Untuk development, bisa lihat link verifikasi di logs
- Untuk production, setup SMTP custom di Settings → Auth

---

## 📚 Resources

- [Supabase Flutter Docs](https://supabase.com/docs/reference/dart/introduction)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

---

## 🎯 Next Steps

Sekarang Anda siap untuk mulai implementasi! 

**Untuk memulai coding:**
1. Buka file `tasks.md` di folder ini
2. Klik "Start task" pada task pertama
3. Atau minta saya untuk mulai implementasi dengan mengatakan: "Mulai task 1"

**Estimasi waktu total implementasi:** 2-3 jam untuk semua fitur autentikasi.

---

**Good luck! 🚀**
