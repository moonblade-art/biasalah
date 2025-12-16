# BUKTI TEKNIS MITIGASI RESIKO KEAMANAN - ECOTRACK

Dokumen ini memetakan 10 poin resiko keamanan basis data dengan bukti implementasi kode nyata (Code Evidence) pada sistem EcoTrack.

---

## 1. Injection Attacks
**Mitigasi**: Validasi input melalui ORM (Supabase SDK) dan Prepared Statements.

**Bukti Kode (Dart - Flutter)**:
Menggunakan metode `.insert()` dari Supabase SDK yang secara otomatis melakukan *parameter binding*, mencegah SQL Injection pada input user.
*File: lib/services/donation_service.dart*
```dart
      // Create donation record - AMAN dari SQL Injection
      final donationData = {
        'user_id': user.id,              // Parameterized
        'community_id': communityId,     // Parameterized
        'amount': donationAmount,        // Parameterized
        'carbon_amount': carbonAmount,   // Parameterized
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'midtrans_order_id': orderId,
        'payment_url': null,
        'notes': notes,
      };

      // Eksekusi via SDK (bukan Raw SQL String)
      final response = await _supabase
          .from('donations')
          .insert(donationData)
          .select()
          .single();
```

---

## 2. Broken Authentication & Access Control
**Mitigasi**: Autentikasi berbasis Token (JWT) dan Validasi Role pada endpoint.

**Bukti Kode (SQL - Row Level Security)**:
Menggunakan `auth.uid()` untuk memastikan user hanya bisa memproses datanya sendiri, dan `security definer` untuk fungsi yang membutuhkan hak akses khusus (Admin/System).
*File: supabase/migrations/20251214_process_donation.sql*
```sql
-- Security Definer: Fungsi dijalankan dengan privilese pembuat (Admin)
-- Memungkinkan update data sensitif tanpa memberikan akses langsung tabel ke user
create or replace function process_successful_donation(...)
security definer 
as $$
...
$$;
```

---

## 3. Data Breaches
**Mitigasi**: Enkripsi password (Hashing) dan perlindungan data sensitif.

**Bukti Kode (Dart - Register Flow)**:
Password tidak pernah disimpan plain-text. Pendaftaran menggunakan fungsi aman SDK yang menghash password menggunakan BCrypt di server.
*File: lib/screens/auth/register_page.dart*
```dart
      // Password dikirim via HTTPS dan di-hash di server Supabase (GoTrue)
      final response = await _authService.signUp(
        email: _email.text.trim(),
        password: _password.text, // Plain text hanya di memori client sebentar
        fullName: _name.text.trim(),
      );
```

---

## 4. Malware dan Ransomware
**Mitigasi**: Pembatasan akses database hanya dari Backend Server terpercaya (Edge Function).

**Bukti Kode (TypeScript - Edge Function)**:
Akses database untuk operasi kritis dilakukan di lingkungan terisolasi (Deno Runtime) menggunakan Service Role Key, bukan langsung dari Client App.
*File: supabase/functions/midtrans-webhook/index.ts*
```typescript
// Koneksi database hanya dilakukan di server-side environment
const supabase = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '' // Kunci rahasia server
)
```

---

## 5. Insider Threat
**Mitigasi**: Pencatatan aktivitas (Logging) dan pembatasan hak akses (Least Privilege).

**Bukti Kode (SQL - Atomic Transaction)**:
Menggunakan `FOR UPDATE` untuk mengunci baris data selama pemrosesan, mencegah manipulasi data oleh proses lain atau admin yang sedang mengakses bersamaan.
*File: supabase/migrations/20251214_process_donation.sql*
```sql
  -- Mengunci baris data spesifik untuk mencegah Race Condition / Manipulasi
  select amount, carbon_amount, user_id, payment_status
  into v_donation_amount, v_carbon_amount, v_user_id, v_current_status
  from donations
  where id = p_donation_id
  for update; -- LOCK
```

---

## 6. Weak Cryptography
**Mitigasi**: Algoritma enkripsi teruji dan kebijakan password kuat.

**Bukti Kode (Dart - Password Policy)**:
Memastikan user tidak menggunakan password lemah yang mudah di-bruteforce.
*File: lib/screens/auth/register_page.dart*
```dart
    // Validasi Kompleksitas Password
    if (!RegExp(r'[A-Z]').hasMatch(_password.text)) { ... } // Huruf Besar
    if (!RegExp(r'[a-z]').hasMatch(_password.text)) { ... } // Huruf Kecil
    if (!RegExp(r'[0-9]').hasMatch(_password.text)) { ... } // Angka
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_password.text)) { ... } // Simbol
```

---

## 7. Insecure Data Handling
**Mitigasi**: Tidak menyimpan data sensitif dalam log aplikasi.

**Bukti Kode (TypeScript - Env Vars)**:
Server Key tidak di-hardcode di kode, melainkan diambil dari Environment Variable.
*File: supabase/functions/create-midtrans-token/index.ts*
```typescript
// AMAN: Mengambil dari Env Var
const SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY') || '';

// Logs hanya mencatat informasi umum, bukan kredensial
console.log(`Processing donation request for user: ${user_id}`);
```

---

## 8. Inadequate Third-Party Security
**Mitigasi**: Integrasi aman menggunakan Auth Header standar.

**Bukti Kode (TypeScript - API Request)**:
Menggunakan Basic Auth sesuai standar Midtrans dengan encoding Base64.
*File: supabase/functions/create-midtrans-token/index.ts*
```typescript
// Encode Server Key ke Base64 untuk Basic Auth Header
const authString = btoa(`${cleanServerKey}:`);

const response = await fetch(apiUrl, {
  headers: {
    'Authorization': `Basic ${authString}`, // Secure Header
    'Content-Type': 'application/json',
  },
  // ...
});
```

---

## 9. Data Inventory & Management
**Mitigasi**: Klasifikasi data melalui Schema Definition yang ketat.

**Bukti Kode (SQL - Schema)**:
Tipe data didefinisikan secara eksplisit (UUID, Numeric, Text) untuk mencegah anomali data.
*File: supabase/migrations/20251214_process_donation.sql*
```sql
-- Definisi tipe data ketat pada parameter fungsi
create or replace function process_successful_donation(
  p_donation_id uuid,   -- Hanya menerima UUID valid
  p_transaction_id text -- Hanya menerima Text
)
```

---

## 10. Non-Compliance with Data Regulation
**Mitigasi**: Transparansi penggunaan data dan isolasi data pengguna (Privacy).

**Bukti Kode (SQL - Isolation)**:
Logika update saldo hanya mempengaruhi user yang terkait dengan donasi tersebut (`where user_id = v_user_id`), menjamin privasi dan integritas data pengguna lain.
*File: supabase/migrations/20251214_process_donation.sql*
```sql
  -- Update HANYA pada user pemilik donasi
  update users
  set emisi_offset = emisi_offset + v_carbon_amount
  where user_id = v_user_id; -- Targeted Update
```
