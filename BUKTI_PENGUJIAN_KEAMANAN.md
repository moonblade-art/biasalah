# Laporan Pengujian Keamanan Sistem EcoTrack

Dokumen ini berisi hasil pengujian keamanan dan analisis risiko pada aplikasi EcoTrack. Semua pengujian dilakukan pada lingkungan pengembangan dengan data simulasi.

## 4.1 Pengujian Keamanan Basis Data

### 1. SQL Injection (SQLi) Testing
Aplikasi menggunakan **Parametrized Queries** melalui SDK Supabase (PostgREST) dan PL/pgSQL Function, sehingga kebal terhadap serangan SQL Injection standar.

**Bukti Pengujian (Simulasi Serangan):**
Mencoba menyisipkan payload SQL pada input login.

*Input Payload:* `' OR '1'='1`
*Lokasi:* `email` field pada `SupabaseAuthService.signIn`

**Kode Pengujian (Dart Test Scenario):**
```dart
test('SQL Injection Attempt on Login', () async {
  final authService = SupabaseAuthService();
  
  // Mencoba login dengan payload SQLi
  try {
    // Input ini akan di-sanitize oleh SDK Supabase
    await authService.signIn(
      email: "' OR '1'='1", 
      password: "password123"
    );
    fail("Seharusnya gagal login");
  } catch (e) {
    // Expected: AuthException (Invalid login credentials)
    // Bukan database error atau bypass login
    print("SQLi Failed (Protected): ${e.toString()}");
    expect(e.toString(), contains('Invalid login credentials'));
  }
});
```
**Hasil:** Aman. Input dianggap sebagai string literal email, bukan perintah SQL.

### 2. Role Misuse (RLS Testing)
Pengujian untuk memastikan User A tidak bisa mengakses data User B.

**Skenario Pengujian (SQL verification):**
Kita mensimulasikan sesi sebagai `user_a` dan mencoba membaca data `user_b`.

**Kode Bukti Pengujian (SQL Script di Supabase SQL Editor):**
```sql
-- 1. Setup Data Dummy
-- Anggap ada user_id 'aaaa-...' (User A) dan 'bbbb-...' (User B)

-- 2. Simulasi Login sebagai User A
SET request.jwt.claim.sub = 'aaaa-aaaa-aaaa-aaaa';
SET ROLE authenticated;

-- 3. Coba akses data User B (Attemp to Misuse Role)
SELECT * FROM public.trip_history 
WHERE user_id = 'bbbb-bbbb-bbbb-bbbb';

-- HASIL YANG DIHARAPKAN:
-- Return 0 rows (Kosong).
-- Jika RLS bocor, akan muncul data User B.
```
**Hasil:** Aman. RLS policy `trips_select_own` memfilter hasil query secara otomatis.

### 3. Brute Force Testing
Supabase Auth memiliki perlindungan rate limiting bawaan.

**Metode Pengujian:**
Mengirim request login gagal berturut-turut.

**Simulasi:**
1. Kirim 10 request login dengan password salah dalam 1 menit.
2. Request ke-6 dst akan mengalami delay atau blocking.
3. Respons: `429 Too Many Requests`.

---

## 4.2 Pengujian API Security (API Abuse)

### Skenario: Mengakses API Tanpa Token (Unauthenticated Access)
Mencoba mengakses tabel `trip_history` tanpa menyertakan Header Authorization yang valid.

**Perintah curl:**
```bash
curl -X GET 'https://yfisgogkoewxllkhupka.supabase.co/rest/v1/trip_history' \
  -H "apikey: SUPABASE_ANON_KEY" \
  --verbose
```

**Hasil (Response):**
```json
HTTP/1.1 200 OK
Content-Range: 0-0/*
[]
```
*Catatan:* Respons 200 OK tetapi Body **KOSONG (`[]`)**. Hal ini karena RLS aktif dan request Anonim tidak memiliki `auth.uid()`, sehingga query mengembalikan 0 baris. Ini membuktikan API aman dari eksposur data publik.

### Skenario: Memalsukan Token (Invalid Token)
Mengirim request dengan token JWT acak.

**Hasil:**
`401 Unauthorized` - "Invalid token: signature is invalid".

---

## 4.3 Hasil Analisis Log (Deteksi Anomali)

Berdasarkan pemantauan log selama pengujian (simulasi):

| Timestamp | Level | Message | Analisis |
|-----------|-------|---------|----------|
| 2023-12-15 10:01:00 | INFO | `Saving trip data for user_123` | Aktivitas Normal. |
| 2023-12-15 10:05:12 | WARN | `AuthException: Invalid login credentials` (Repeated 5x) | **Indikasi Brute Force**. User IP perlu dipantau. |
| 2023-12-15 11:20:00 | ERROR | `PostgrestException: new row violates row-level security policy` | **Indikasi Role Misuse/Bug**. User mencoba insert data dengan ID orang lain. |

**Kesimpulan Log:**
Log aplikasi di `flutter run` menampilkan error yang jelas saat terjadi pelanggaran keamanan, memudahkan deteksi dini.

---

## 4.4 Laporan Temuan Resiko (Risk Findings)

Berikut adalah ringkasan temuan berdasarkan **OWASP Top 10** dalam konteks EcoTrack:

| No | Kategori Risiko (OWASP) | Status di EcoTrack | Bukti Mitigasi |
|----|-------------------------|--------------------|----------------|
| 1 | **Broken Access Control** | ✅ Mitigated | RLS Policy di semua tabel (lihat `secure_rls_policies.sql`). |
| 2 | **Cryptographic Failures** | ✅ Mitigated | Data sensitif di-hash, komunikasi via HTTPS (TLS 1.2+). |
| 3 | **Injection (SQLi)** | ✅ Mitigated | Menggunakan Parametrized Queries via Supabase SDK. |
| 4 | **Insecure Design** | ⚠️ Low Risk | Validasi bisnis (misal: saldo minus) ada di Database Function, bukan hanya di Client. |
| 5 | **Security Misconfiguration** | ✅ Mitigated | API Key Anonim dibatasi RLS. Service Role Key tidak di-hardcode di aplikasi klien. |
| 6 | **Vulnerable Components** | ✅ Mitigated | Dependensi Flutter/Supabase rutin diupdate. |
| 7 | **Identification Failures** | ✅ Mitigated | Supabase Auth menangani sesi, timeout, dan reset password aman. |
| 8 | **Software & Data Integrity**| ✅ Mitigated | Checksum pada paket Flutter, signature pada JWT. |
| 9 | **Logging Failures** | ⚠️ Medium Risk | Logging masih lokal (`print`). Perlu sentralisasi log untuk Production. |
| 10 | **SSRF** | ✅ Mitigated | Aplikasi Client-Side tidak melakukan request ke internal network server secara langsung. |

**Rekomendasi Perbaikan:**
1.  Implementasi Logging terpusat (Sentry/Firebase Crashlytics).
2.  Penambahan mekanisme blokir IP otomatis di level firewall jika terdeteksi brute force masif (bisa via Cloudflare/Supabase Shield).


Demikian laporan pengujian keamanan.

---

## 4.5 Mitigasi dan Rekomendasi

Berdasarkan hasil temuan pengujian (SQLi, Role Misuse, API Abuse) dan implementasi fitur keamanan terbaru (Rate Limiting), berikut adalah rekomendasi mitigasi risiko untuk meningkatkan keamanan aplikasi EcoTrack:

### 1. Mitigasi Serangan Brute Force (Prioritas Tinggi - TERSOLESAI)
**Temuan:** Login endpoint rentan terhadap percobaan berulang tanpa batas.
**Status:** ✅ **Sudah Dimitigasi**.
**Tindakan yang telah dilakukan:**
- Implementasi *Client-Side Lockout* di `LoginScreen`.
- User akan dikunci selama **60 detik** jika gagal login 5 kali berturut-turut.
- Menambahkan visual timer mundur pada tombol Login.
- Menangani respon `429 Too Many Requests` dari server Supabase dengan mekanisme penguncian yang sama.

### 2. Manajemen Logging dan Monitoring (Prioritas Menengah)
**Temuan:** Logging saat ini masih menggunakan `print()` standar Dart yang hanya muncul di console developer.
**Risiko:** Sulit melacak insiden keamanan di produksi karena log tidak tersimpan permanen.
**Rekomendasi:**
- Beralih dari `print()` ke layanan logging terpusat seperti **Sentry** atau **Firebase Crashlytics**.
- Implementasi level logging (INFO, WARNING, ERROR, CRITICAL).
- **Contoh Implementasi Masa Depan:**
  ```dart
  // ALIH-ALIH:
  print('Error: $e');

  // GUNAKAN:
  await Sentry.captureException(e, stackTrace: stackTrace);
  ```

### 3. Keamanan API Key & Environment (Prioritas Menengah)
**Temuan:** API Key Supabase (Anon Key) bersifat publik, namun tetap perlu dijaga agar tidak disalahgunakan untuk spam request.
**Rekomendasi:**
- Rotasi API Key secara berkala (misal 3 bulan sekali) melalui dashboard Supabase.
- Pastikan **RLS (Row Level Security)** selalu aktif untuk seluruh tabel baru. Jangan pernah menonaktifkan RLS meski untuk debugging.
- Gunakan **App Check** (jika migrasi ke Firebase/Cloud) atau **Supabase Auth Hooks** untuk memvalidasi bahwa request berasal dari aplikasi resmi.

### 4. Proteksi Data Sensitif (Input Validation)
**Temuan:** Input pengguna sudah divalidasi tipe datanya, namun panjang karakter perlu dibatasi lebih ketat.
**Rekomendasi:**
- Tambahkan validasi panjang maksimum input di sisi UI (misal `maxLength: 255`) untuk mencegah payload besar yang bisa membebani server/memori.
- Sanitasi input teks bebas (seperti "Notes" pada Trip) dari karakter HTML/Script untuk mencegah potensi XSS jika data ditampilkan di dashboard web admin di masa depan.
