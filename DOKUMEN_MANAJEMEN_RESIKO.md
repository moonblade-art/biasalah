# DOKUMEN HASIL MANAJEMEN RESIKO

**Tugas Minggu Ke** : 10
**KEAMANAN BASIS DATA**

**KELOMPOK / TIM** : PBL-TRPL-313
**TOPIK/JUDUL** : Implementasi Sistem Perhitungan Jejak Karbon Kendaraan Dan Emisi Transportasi Berbasis Mobile Untuk Meningkatkan Kesadaran Lingkungan Pengguna
**KELAS** : TRPL 3C PAGI

**ANGGOTA TIM** :
*   4342401090 - Hady Wiranata
*   4342401073 - Fahri Andrean Saputra
*   4342401071 - Ibra Marioka
*   4342401084 - Hermansa
*   4342401076 - Muhammad Addin
*   4342401083 - Nayla Nur Nabila

**PROGRAM STUDI TEKNOLOGI REKAYASA PERANGKAT LUNAK**
**JURUSAN TEKNIK INFORMATIKA**
**POLITEKNIK NEGERI BATAM**
**2025**

---

## DAFTAR ISI

1.  [BAB I PENDAHULUAN](#bab-i-pendahuluan)
2.  [BAB II MONITORING DESAIN SISTEM DAN KEAMANAN](#bab-ii-monitoring-desain-sistem-dan-keamanan)
3.  [LAMPIRAN: BUKTI IMPLEMENTASI KODE](#lampiran-bukti-implementasi-kode)

---

## BAB I
## PENDAHULUAN

### Deskripsi Umum Perangkat Lunak-PBL

Sistem EcoTrack merupakan perangkat lunak berbasis mobile yang dikembangkan untuk membantu pengguna dalam menghitung, memantau, serta mengevaluasi jejak karbon yang dihasilkan dari aktivitas transportasi sehari-hari. Sistem ini bertujuan untuk meningkatkan kesadaran masyarakat terhadap dampak lingkungan akibat penggunaan kendaraan bermotor, sekaligus memberikan alternatif solusi melalui rekomendasi transportasi ramah lingkungan dan fitur donasi sebagai bentuk kompensasi emisi karbon.

EcoTrack terdiri dari dua komponen utama, yaitu aplikasi mobile berbasis Android yang digunakan oleh pengguna, serta platform admin berbasis web yang digunakan untuk pengelolaan data sistem. Kedua komponen tersebut terhubung melalui backend API terintegrasi yang bertanggung jawab dalam memproses logika bisnis, pengelolaan data, dan keamanan basis data.

Pengguna aplikasi EcoTrack dapat melakukan pencatatan perjalanan transportasi, melihat hasil perhitungan emisi karbon berdasarkan jenis kendaraan dan jarak tempuh, mengakses riwayat penggunaan, menerima notifikasi, serta melakukan donasi karbon. Sementara itu, admin memiliki kewenangan untuk mengelola data faktor emisi kendaraan, komunitas penerima donasi, serta memantau data transaksi dan penggunaan sistem melalui dashboard admin.

Dalam konteks keamanan basis data, sistem EcoTrack menyimpan berbagai jenis data penting, seperti informasi akun pengguna, riwayat perjalanan, data emisi karbon, serta data transaksi donasi. Oleh karena itu, penerapan kontrol keamanan basis data menjadi aspek krusial untuk menjamin kerahasiaan (*confidentiality*), integritas (*integrity*), dan ketersediaan (*availability*) data.

Arsitektur sistem EcoTrack dirancang menggunakan pendekatan client-server, di mana aplikasi mobile dan web admin hanya dapat mengakses database melalui backend API. Akses langsung ke database oleh klien tidak diperkenankan, sehingga risiko manipulasi data dapat diminimalkan.

### User Stories

#### Fungsional Fitur MF1 – Autentikasi Pengguna
**User Story:** Sebagai pengguna aplikasi, saya ingin dapat melakukan login menggunakan email dan password agar saya dapat mengakses fitur EcoTrack secara aman.
**Kriteria Penerimaan:** Pengguna harus berhasil login menggunakan kredensial yang valid. Sistem menyimpan password dalam bentuk hash dan hanya pengguna yang terautentikasi yang dapat mengakses data pribadi.

#### Fungsional Fitur MF2 – Pencatatan Perjalanan
**User Story:** Sebagai pengguna, saya ingin mencatat perjalanan transportasi yang saya lakukan sehingga sistem dapat menghitung emisi karbon yang dihasilkan.
**Kriteria Penerimaan:** Sistem menyimpan data perjalanan ke dalam database dan mengaitkannya dengan akun pengguna yang sedang login.

#### Fungsional Fitur MF3 – Perhitungan Emisi Karbon
**User Story:** Sebagai pengguna, saya ingin melihat hasil perhitungan emisi karbon berdasarkan perjalanan saya agar saya mengetahui dampak lingkungan dari aktivitas transportasi.
**Kriteria Penerimaan:** Nilai emisi dihitung berdasarkan faktor emisi kendaraan dan jarak tempuh, kemudian disimpan secara aman di database.

#### Fungsional Fitur MF4 – Riwayat Emisi
**User Story:** Sebagai pengguna, saya ingin melihat riwayat emisi karbon saya sehingga saya dapat memantau perkembangan kontribusi emisi dari waktu ke waktu.
**Kriteria Penerimaan:** Data riwayat hanya dapat diakses oleh pengguna yang bersangkutan dan tidak dapat diubah secara langsung.

#### Fungsional Fitur MF5 – Donasi Karbon
**User Story:** Sebagai pengguna, saya ingin melakukan donasi karbon agar dapat berkontribusi dalam pengurangan dampak lingkungan.
**Kriteria Penerimaan:** Transaksi donasi dicatat ke dalam database dengan status yang jelas dan dilindungi dari akses tidak sah.

#### Fungsional Fitur MF6 – Notifikasi
**User Story:** Sebagai pengguna, saya ingin menerima notifikasi terkait aktivitas akun dan donasi agar saya selalu mendapatkan informasi terbaru.
**Kriteria Penerimaan:** Notifikasi tersimpan di database dan hanya dapat diakses oleh pengguna terkait.

#### Fungsional Fitur MF7 – Pengelolaan Data oleh Admin
**User Story:** Sebagai admin, saya ingin mengelola data faktor emisi dan komunitas agar sistem tetap berjalan sesuai ketentuan.
**Kriteria Penerimaan:** Akses admin dibatasi melalui role-based access control dan seluruh aktivitas admin tercatat dalam sistem.

### Skema Basis Data

Skema basis data EcoTrack terdiri dari beberapa tabel utama yang saling terhubung melalui relasi foreign key. Tabel users menjadi pusat data pengguna yang menyimpan informasi identitas dan kredensial akun. Tabel ini berelasi dengan tabel pelacakan_emisi, ringkasan_emisi, donasi, dan notifikasi.

Setiap data perjalanan dan emisi disimpan dengan referensi ke pengguna yang melakukan aktivitas tersebut. Tabel donasi menyimpan informasi transaksi yang terhubung dengan tabel komunitas sebagai penerima donasi. Relasi antar tabel dirancang untuk menjaga integritas data serta mempermudah proses auditing dan monitoring keamanan.

---

## BAB II
## MONITORING DESAIN SISTEM DAN KEAMANAN

### Identifikasi Aktor / Role

Sistem EcoTrack menerapkan mekanisme kontrol akses berbasis peran atau *Role-Based Access Control* (RBAC) untuk memastikan bahwa setiap pengguna hanya dapat mengakses fitur dan data sesuai dengan kewenangannya. Terdapat dua aktor utama dalam sistem ini, yaitu User dan Admin.

1.  **User**: Pengguna aplikasi mobile EcoTrack. Hanya memiliki akses terhadap data miliknya sendiri.
2.  **Admin**: Pengelola sistem melalui platform web. Memiliki akses data master namun tetap dibatasi untuk data sensitif pengguna.

### Daftar Hak Akses / Privilege

Hak akses dirancang berdasarkan prinsip *least privilege*:

*   **Hak Autentikasi Pengguna**: Login/Logout aman.
*   **Hak Akses Data Pribadi**: Pembatasan query berdasarkan `user_id`.
*   **Hak Pencatatan dan Perhitungan Emisi**: Read-only untuk data historis.
*   **Hak Donasi Karbon**: Transaksi aman dan tercatat.
*   **Hak Administratif (Admin)**: Pengelolaan data master dengan logging.

### Identifikasi Risiko Keamanan

1.  **Injection Attacks**: Diminigasi dengan ORM dan prepared statements.
2.  **Broken Authentication**: Diminigasi dengan JWT dan validasi sesi.
3.  **Data Breaches**: Diminigasi dengan Hashing Password (Bcrypt) dan HTTPS.
4.  **Malware**: Diminigasi dengan pembatasan akses server-side.
5.  **Weak Cryptography**: Menggunakan standar industri (TLS 1.2+, Strong Hashing).

### Rencana Auditing

EcoTrack menerapkan auditing pada level:
1.  **Auth Logs**: Mencatat login berhasil/gagal.
2.  **Database WAL**: Mencatat perubahan state data (transaksi).
3.  **App Logs**: Mencatat aktivitas API dan Webhook (e.g. Midtrans Payment).

### API Security

1.  **HTTPS/TLS**: Enkripsi *in-transit*.
2.  **JWT Authorization**: Validasi token pada setiap request.
3.  **Secure Webhook**: Validasi sumber request dan penggunaan Service Role Key di server (bukan client).

---

## LAMPIRAN: BUKTI IMPLEMENTASI KODE

Berikut adalah potongan kode asli dari sistem EcoTrack yang membuktikan penerapan keamanan di atas.

### 1. Keamanan Password (Input Validation & Policy)

**Lokasi File:** `lib/screens/auth/register_page.dart`
**Deskripsi:** Penerapan validasi ketat menggunakan Regex untuk memastikan password memiliki kompleksitas tinggi (Min 8 karakter, Huruf Besar, Kecil, Angka, Simbol).

```dart
    // Validasi Panjang Karakter
    if (_password.text.length < 8) {
      _showError('Password minimal 8 karakter');
      return;
    }
    // Validasi Huruf Besar (Uppercase)
    if (!RegExp(r'[A-Z]').hasMatch(_password.text)) {
      _showError('Password harus ada huruf besar (A-Z)');
      return;
    }
    // Validasi Huruf Kecil (Lowercase)
    if (!RegExp(r'[a-z]').hasMatch(_password.text)) {
      _showError('Password harus ada huruf kecil (a-z)');
      return;
    }
    // Validasi Angka (Numeric)
    if (!RegExp(r'[0-9]').hasMatch(_password.text)) {
      _showError('Password harus ada angka (0-9)');
      return;
    }
    // Validasi Simbol
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(_password.text)) {
      _showError('Password harus ada simbol (!@#\$%^&*)');
      return;
    }
```

### 2. Keamanan Database (Atomic Transaction & Security Definer)

**Lokasi File:** `supabase/migrations/20251214_process_donation.sql`
**Deskripsi:** Menggunakan PostgreSQL Function dengan `SECURITY DEFINER` untuk memproses donasi sensitif. Fungsi ini menjamin atomisitas (semua sukses atau semua gagal) dan mencegah *Race Condition* dengan `FOR UPDATE`.

```sql
create or replace function process_successful_donation(
  p_donation_id uuid,
  p_transaction_id text
)
returns void
language plpgsql
security definer -- Bypass RLS untuk update sistem yang aman
as $$
declare
  v_donation_amount numeric;
  v_carbon_amount numeric;
  v_user_id uuid;
  v_current_status text;
begin
  -- 1. Lock Row untuk mencegah Race Condition
  select amount, carbon_amount, user_id, payment_status
  into v_donation_amount, v_carbon_amount, v_user_id, v_current_status
  from donations
  where id = p_donation_id
  for update;

  -- 2. Idempotency Check (Cegah proses ganda)
  if v_current_status = 'success' then
    return;
  end if;

  -- 3. Update Status Donasi
  update donations
  set 
    payment_status = 'success',
    midtrans_transaction_id = p_transaction_id,
    paid_at = now()
  where id = p_donation_id;

  -- 4. Update Saldo User (Atomic)
  update users
  set 
    emisi_belum = greatest(0, emisi_belum - v_carbon_amount),
    emisi_offset = emisi_offset + v_carbon_amount
  where user_id = v_user_id;
end;
$$;
```

### 3. Keamanan API (Environment Variables & Error Handling)

**Lokasi File:** `supabase/functions/create-midtrans-token/index.ts`
**Deskripsi:** Pengelolaan *Secret Keys* server-side (tidak terekspos di aplikasi mobile) dan penanganan CORS serta Error yang aman.

```typescript
// Mengambil Server Key dari Environment Variable (Aman)
const SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY') || '';

// Membersihkan input key untuk menghindari karakter tersembunyi
const cleanServerKey = SERVER_KEY.trim().replace(/[\r\n]+/g, '');

// Validasi Key sebelum request ke Pihak Ketiga
if (!cleanServerKey || cleanServerKey.startsWith('SB-Mid-client') || cleanServerKey.startsWith('Mid-client')) {
  throw new Error('Konfigurasi Server Key Salah: Terdeteksi Client Key');
}

// Otorisasi Basic Auth standar Midtrans
const authString = btoa(`${cleanServerKey}:`);

// Request ke Midtrans API
const response = await fetch(apiUrl, {
  method: 'POST',
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': `Basic ${authString}`, // Header Auth Aman
  },
  body: JSON.stringify(payload),
});
```
