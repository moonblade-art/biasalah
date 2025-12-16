# Implementasi Keamanan Sistem EcoTrack

Dokumen ini berisi bukti implementasi keamanan pada aplikasi EcoTrack berdasarkan kode sumber yang ada.

## 3.1 Implementasi Access Control (RBAC dan Least Privilege)

Sistem menggunakan **Row Level Security (RLS)** dari Supabase untuk memastikan pengguna hanya dapat mengakses data mereka sendiri (*least privilege*). Kebijakan ini diterapkan langsung pada level database.

**Bukti Kode (`database/secure_rls_policies.sql`):**

```sql
-- RBAC: Membatasi akses hanya untuk user yang terautentikasi ('authenticated')
-- Least Privilege: User hanya bisa melihat/mengubah data milik sendiri (auth.uid() = user_id)

-- 1. Kebijakan untuk Tabel Users
CREATE POLICY "users_select_own" ON public.users
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "users_update_own" ON public.users
  AS PERMISSIVE FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 2. Kebijakan untuk Riwayat Perjalanan (Trip History)
CREATE POLICY "trips_select_own" ON public.trip_history
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 3. Kebijakan untuk Donasi
CREATE POLICY "donations_select_own" ON public.donations
  AS PERMISSIVE FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);
```

Selain itu, fungsi sensitif menggunakan `SECURITY DEFINER` untuk membatasi akses langsung ke tabel dan mengenkapsulasi logika bisnis (seperti verifikasi pembayaran).

**Bukti Kode (`database/process_donation.sql`):**
```sql
create or replace function process_successful_donation(
  p_donation_id uuid,
  p_transaction_id text
)
returns void
language plpgsql
security definer -- Berjalan dengan privileges pembuat fungsi (bypass RLS aman)
as $$
  -- Logika update saldo dan status dilakukan di sini secara terisolasi
$$;
```

## 3.2 Implementasi API Security

Keamanan API diimplementasikan menggunakan mekanisme autentikasi Supabase yang berbasis Token (JWT). API Key publik (Anon Key) digunakan untuk inisialisasi, namun akses data tetap dibatasi oleh RLS dan validasi Token pengguna.

**Bukti Kode (`lib/config/supabase_config.dart`):**
```dart
class SupabaseConfig {
  // Supabase project configuration
  static const String supabaseUrl = 'https://yfisgogkoewxllkhupka.supabase.co';
  // API Key (Anon) digunakan untuk koneksi awal
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
  
  // Konfigurasi sesi (Token Security)
  static const int sessionTimeoutHours = 24;
}
```

**Bukti Kode (`lib/services/supabase_auth_service.dart`):**
```dart
// Menggunakan SDK Supabase yang menangani pengiriman Token Bearer secara otomatis pada setiap request
class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Login menghasilkan sesi aman dengan JWT
  Future<AuthResponse> signIn(...) async {
    final response = await _supabase.auth.signInWithPassword(...);
    // Token dikelola otomatis oleh SDK
    return response;
  }
}
```

## 3.3 Implementasi Logging dan Audit Trail

### Logging Aplikasi
Logging dilakukan di level aplikasi untuk mencatat aktivitas penting seperti penyimpanan perjalanan dan error handling.

**Bukti Kode (`lib/services/tracking_service.dart`):**
```dart
// Pencatatan aktivitas penyimpanan data
print('Saving trip data: $tripData'); // Debug log

final response = await _supabase
    .from('trip_history')
    .insert(tripData)
    .select()
    .single();

print('Trip saved successfully: ${response['id']}'); // Konfirmasi sukses
```

### Audit Trail Data
Setiap perjalanan yang dilakukan pengguna dicatat dalam tabel `trip_history` yang berfungsi sebagai audit trail aktivitas pengguna. Tanggal pembuatan dan pengubahan data dicatat secara otomatis oleh database.

**Bukti Struktur Tabel (Tercermin dari Logika Insert):**
```dart
final tripData = {
  'user_id': userId, // Identitas Pelaku
  'trip_date': (tripDate ?? DateTime.now())..., // Waktu Aktivitas
  'route_points': routePoints, // Detail Aktivitas
  // ...
};
```

## 3.4 Implementasi Perlindungan Basis Data

### Enkripsi Password
Password pengguna tidak disimpan dalam teks biasa (plain text). Supabase Auth secara otomatis melakukan *hashing* (menggunakan bcrypt atau argon2) sebelum menyimpan password ke database.

**Bukti Kode (`lib/services/supabase_auth_service.dart`):**
```dart
// Password dikirim ke backend Supabase untuk di-hash dan diverifikasi
final response = await _supabase.auth.signUp(
  email: email,
  password: password, // Password raw dikirim via HTTPS
);
```

### Integritas dan Konsistensi Data
Penggunaan transaksi database dan mekanisme penguncian (`FOR UPDATE`) untuk mencegah *race condition* pada data sensitif seperti saldo emisi saat donasi diproses.

**Bukti Kode (`supabase/migrations/20251214_process_donation.sql`):**
```sql
  -- Mengunci baris data untuk mencegah perubahan konkuren (Data Protection)
  select amount, carbon_amount, user_id
  into ...
  from donations
  where id = p_donation_id
  for update; -- Locking mechanism
```

## 3.5 Gap antara Desain Awal dan Implementasi

Berdasarkan analisis implementasi saat ini:

1.  **Logging**: Saat ini logging masih menggunakan `print` (standar output) yang efektif untuk debugging pengembangan. Untuk lingkungan produksi skala besar (Enterprise), disarankan menggunakan layanan logging terpusat (seperti Sentry atau Crashlytics) untuk retensi dan analisis log yang lebih baik. Namun untuk skala saat ini, implementasi sudah memadai.
2.  **Audit Trail**: Audit trail perubahan data (siapa mengubah apa dan kapan) untuk tabel master data admin belum terlihat secara eksplisit (misal tabel `audit_logs` khusus). Namun, audit aktivitas utama pengguna (Trip dan Donasi) sudah terimplementasi dengan baik melalui tabel transaksi masing-masing.

Secara umum, implementasi keamanan inti (RBAC, Enkripsi, API Security) sudah sesuai dengan standar best practice modern menggunakan Supabase.
