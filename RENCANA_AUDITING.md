# RENCANA AUDITING SISTEM ECOTRACK

## 1. Pendahuluan
Rencana auditing ini bertujuan untuk memastikan seluruh aktivitas kritis dalam sistem EcoTrack terekam dengan baik, memungkinkan penelusuran (traceability), akuntabilitas, dan deteksi dini terhadap anomali keamanan. Audit dilakukan pada tiga lapisan utama: Aplikasi (Client), Server (Edge Functions), dan Database.

---

## 2. Strategi Auditing

### 2.1 Audit Autentikasi & Akses
**Tujuan**: Memantau siapa yang mengakses sistem dan mendeteksi upaya akses ilegal.
**Mekanisme**:
*   Mencatat setiap upaya login (berhasil/gagal).
*   Mencatat pembuatan akun baru.
*   Mencatat perubahan password (reset/update).

### 2.2 Audit Transaksi Keuangan & Emisi
**Tujuan**: Menjamin integritas data donasi dan perhitungan jejak karbon.
**Mekanisme**:
*   Pencatatan status pembayaran (Pending -> Success/Failure).
*   Pencatatan perubahan saldo emisi user.
*   Pencatatan ID transaksi eksternal (Midtrans) untuk rekonsiliasi.

### 2.3 Audit Sistem & Error
**Tujuan**: Memantau kesehatan sistem dan mendeteksi bug atau serangan injeksi.
**Mekanisme**:
*   Logging error pada Edge Functions.
*   Logging payload webhook yang diterima dari pihak ketiga.

---

## 3. Implementasi Kode & Bukti Audit

Berikut adalah implementasi kode saat ini yang mendukung rencana auditing tersebut.

### A. Audit Trail Database (Layanan Donasi)
Sistem menggunakan tabel `donations` sebagai buku besar (ledger) yang mencatat siklus hidup transaksi. Fungsi SQL `process_successful_donation` bertindak sebagai *audit processor* yang memfinalisasi status.

**Bukti Kode: `supabase/migrations/20251214_process_donation.sql`**
```sql
  -- Logika ini mencatat WAKTU TEPAT (paid_at) dan ID TRANSAKSI EKSTERNAL
  -- Ini penting untuk audit keuangan (Reconcilliation)
  update donations
  set 
    payment_status = 'success',            -- Status Akhir
    midtrans_transaction_id = p_transaction_id, -- Bukti Eksternal (Audit Trail)
    paid_at = now()                        -- Timestamp Audit
  where id = p_donation_id;
```

### B. Audit Aktivitas Backend (Edge Function Logs)
Setiap permintaan ke server (contoh: pembuatan token pembayaran) dicatat log-nya. Ini memungkinkan admin melihat *siapa* yang meminta token dan *kapan*, serta apakah ada error konfigurasi.

**Bukti Kode: `supabase/functions/create-midtrans-token/index.ts`**
```typescript
  // Audit Log: Mencatat request masuk dengan User ID pelakunya
  console.log(`Processing donation request for user: ${user_id} with amount: ${transaction_details.gross_amount}`);

  // Audit Log: Mencatat jika terjadi kegagalan sistem (Error Tracking)
  } catch (error) {
    console.error('Error creating transaction:', error.message);
    // ... return error response
  }
```

### C. Audit Perubahan Data Pengguna (Edit Profile)
Meskipun saat ini belum ada tabel *history* khusus untuk profil, sistem memastikan validasi ketat sebelum perubahan diizinkan, yang secara tidak langsung menjaga integritas data audit.

**Bukti Kode: `lib/services/user_profile_service.dart`**
```dart
  // Update data profil di database
  // Supabase secara otomatis mencatat 'updated_at' jika dikonfigurasi trigger-nya
  await _supabase.from('users').update({
    'full_name': fullName,
    'email': email,
    'profile_picture_url': profilePictureUrl,
    'updated_at': DateTime.now().toIso8601String(), // Audit Timestamp
  }).eq('user_id', userId);
```

---

## 4. Rencana Pengembangan (Future Work)

Untuk meningkatkan kapabilitas auditing di masa depan, disarankan menambahkan:
1.  **Tabel `activity_logs`**: Tabel khusus untuk mencatat "Siapa melakukan Apa pada Kapan".
    *   *Schema*: `id`, `user_id`, `action_type` (e.g., 'LOGIN', 'DONATE'), `timestamp`, `metadata`.
2.  **Trigger Database Otomatis**: Membuat trigger PostgreSQL yang otomatis mengisi tabel `activity_logs` setiap kali ada INSERT/UPDATE pada tabel `donations` atau `users`.

---

## 5. Kesimpulan
Kode sistem EcoTrack saat ini telah memenuhi standar audit dasar melalui:
1.  Pencatatan Timestamp (`created_at`, `updated_at`, `paid_at`).
2.  Penyimpanan ID Referensi Eksternal (Midtrans Transaction ID).
3.  Logging Aktivitas Server (Console Logs di Edge Functions).
