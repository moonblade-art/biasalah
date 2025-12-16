# RENCANA PENGUJIAN DAN PEMANTAUAN - EcoTrack

## 1. INVENTARIS FITUR APLIKASI

### Modul Autentikasi
- **Login**: Email & password authentication
- **Register**: User registration dengan email verification
- **Forgot Password**: Password reset via email
- **OTP Verification**: Email verification system
- **Logout**: Session management

### Modul Tracking Kendaraan
- **Vehicle Selection**: Pilih jenis kendaraan (mobil, motor, sepeda, dll)
- **GPS Tracking**: Real-time location tracking
- **Trip Recording**: Rekam perjalanan dengan jarak, waktu, emisi
- **Trip History**: Lihat riwayat perjalanan
- **Emission Calculation**: Kalkulasi emisi CO₂ berdasarkan jenis kendaraan

### Modul Donasi
- **Community List**: Daftar komunitas untuk donasi
- **Donation Creation**: Buat donasi carbon offset
- **Payment Integration**: Midtrans payment gateway
- **Donation History**: Riwayat donasi
- **Payment Status**: Tracking status pending/success/failed
- **Cancel Donation**: Batalkan donasi pending

### Modul Profil
- **View Profile**: Lihat informasi profil
- **Edit Profile**: Edit nama, email, foto profil
- **Change Password**: Ubah password dengan verifikasi
- **Profile Picture Upload**: Upload foto ke Supabase Storage
- **Carbon Stats**: Lihat total emisi offset & belum offset

### Modul Riwayat
- **Trip History**: Riwayat perjalanan dengan detail
- **Offset History**: Riwayat carbon offset/donasi
- **Filter by Status**: Filter berdasarkan status (success, pending, failed)
- **History Detail**: Detail trip/donation

---

## 2. RENCANA PENGUJIAN PER FITUR

### A. Pengujian Autentikasi

#### Test Case AUTH-001: Login dengan Kredensial Valid
**Tujuan**: Verifikasi user dapat login dengan email & password yang benar  
**Langkah**:
1. Buka aplikasi
2. Masukkan email valid yang sudah terdaftar
3. Masukkan password yang benar
4. Klik tombol "Masuk"

**Expected Result**: 
- Login berhasil
- Redirect ke halaman Home
- Bottom navigation visible

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case AUTH-002: Login dengan Kredensial Invalid
**Tujuan**: Verifikasi sistem menolak kredensial salah  
**Langkah**:
1. Masukkan email valid
2. Masukkan password salah
3. Klik "Masuk"

**Expected Result**: 
- Error message "Kata sandi salah"
- Tidak redirect
- Countdown lockout setelah 5x gagal

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case AUTH-003: Register User Baru
**Tujuan**: Verifikasi pendaftaran user baru  
**Langkah**:
1. Klik "Belum punya akun? Daftar"
2. Isi nama lengkap, email, password (min 8 char, 1 uppercase, 1 lowercase, 1 number, 1 symbol)
3. Konfirmasi password
4. Klik "Daftar"

**Expected Result**: 
- Akun berhasil dibuat
- Email verifikasi terkirim
- Redirect ke halaman verifikasi

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case AUTH-004: Forgot Password
**Tujuan**: Verifikasi reset password  
**Langkah**:
1. Klik "Lupa kata sandi?"
2. Masukkan email terdaftar
3. Klik "Kirim"

**Expected Result**: 
- Email reset password terkirim
- Konfirmasi muncul di UI

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

### B. Pengujian Tracking Kendaraan

#### Test Case TRACK-001: Pilih Kendaraan dan Mulai Tracking
**Tujuan**: Verifikasi tracking dapat dimulai  
**Langkah**:
1. Buka tab "Tracking" (icon location)
2. Pilih jenis kendaraan (misal: Mobil)
3. Klik "Mulai Tracking"

**Expected Result**: 
- GPS aktif
- Map menampilkan lokasi real-time
- Timer mulai berjalan

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case TRACK-002: Stop dan Save Trip
**Tujuan**: Verifikasi trip dapat disimpan  
**Langkah**:
1. Setelah tracking berjalan, klik "Stop"
2. Masukkan judul trip (opsional)
3. Klik "Simpan"

**Expected Result**: 
- Trip tersimpan ke database
- Data: jarak, waktu, emisi CO₂, rute
- Muncul di History

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case TRACK-003: Lihat Detail Trip di History
**Tujuan**: Verifikasi detail trip dapat dilihat  
**Langkah**:
1. Buka tab "Riwayat" > "Perjalanan"
2. Klik salah satu trip
3. Lihat detail

**Expected Result**: 
- Menampilkan: judul, tanggal, jarak, waktu, emisi
- Peta rute perjalanan
- Informasi kendaraan

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

### C. Pengujian Donasi

#### Test Case DON-001: Buat Donasi Carbon Offset
**Tujuan**: Verifikasi donasi dapat dibuat  
**Langkah**:
1. Buka tab "Donasi"
2. Pilih komunitas dari daftar
3. Masukkan jumlah karbon (kg CO₂)
4. Klik "Donasi Rp xxx"

**Expected Result**: 
- Donation record dibuat
- Payment URL Midtrans terbuka
- Status: pending

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case DON-002: Bayar Donasi Pending
**Tujuan**: Verifikasi payment retry  
**Langkah**:
1. Buka "Riwayat" > "Offset Karbon"
2. Cari donasi dengan status "Pending"
3. Klik tombol "Bayar"

**Expected Result**: 
- Payment URL terbuka kembali
- User dapat melanjutkan pembayaran

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case DON-003: Batalkan Donasi Pending
**Tujuan**: Verifikasi donasi dapat dibatalkan  
**Langkah**:
1. Buka "Riwayat" > "Offset Karbon"
2. Cari donasi pending
3. Klik "Batal"
4. Konfirmasi "Ya, Batalkan"

**Expected Result**: 
- Donasi status berubah jadi "cancelled"
- List refresh
- Snackbar konfirmasi muncul

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case DON-004: Filter Donasi by Status
**Tujuan**: Verifikasi filter berfungsi  
**Langkah**:
1. Buka "Riwayat" > "Offset Karbon"
2. Klik filter "Berhasil"
3. Klik filter "Pending"
4. Klik filter "Gagal"

**Expected Result**: 
- List hanya menampilkan donasi sesuai filter
- Counter badge menunjukkan jumlah yang benar

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

### D. Pengujian Profil

#### Test Case PROF-001: Edit Profil (Nama)
**Tujuan**: Verifikasi nama dapat diubah  
**Langkah**:
1. Buka tab "Profil"
2. Klik "Edit Profil"
3. Ubah nama
4. Klik "Simpan Perubahan"

**Expected Result**: 
- Nama berhasil diupdate
- Snackbar "Profil berhasil diperbarui"
- Kembali ke halaman profil

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case PROF-002: Ubah Password
**Tujuan**: Verifikasi password dapat diubah  
**Langkah**:
1. Buka "Edit Profil"
2. Isi "Kata Sandi Saat Ini"
3. Isi "Kata Sandi Baru" (dengan validasi)
4. Isi "Konfirmasi Kata Sandi Baru"
5. Klik "Simpan Perubahan"

**Expected Result**: 
- Password berhasil diubah
- Snackbar "Password berhasil diubah"
- Form password di-clear

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case PROF-003: Ubah Password Saja (Tanpa Edit Profil)
**Tujuan**: Verifikasi password dapat diubah tanpa ubah profil  
**Langkah**:
1. Buka "Edit Profil"
2. JANGAN ubah nama/email
3. Isi password lama & baru
4. Klik "Simpan"

**Expected Result**: 
- TIDAK ada error "Tidak ada data yang diupdate"
- Password berhasil diubah
- Snackbar "Password berhasil diubah"

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case PROF-004: Upload Foto Profil
**Tujuan**: Verifikasi upload foto  
**Langkah**:
1. Klik foto profil di Edit Profile
2. Pilih "Galeri" atau "Kamera"
3. Pilih gambar
4. Klik "Simpan Perubahan"

**Expected Result**: 
- Foto terupload ke Supabase Storage
- Foto profil ter-update di UI
- URL tersimpan di database

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

### E. Pengujian Riwayat

#### Test Case HIST-001: Tab Switching (Perjalanan ↔ Offset Karbon)
**Tujuan**: Verifikasi tab navigation  
**Langkah**:
1. Buka tab "Riwayat"
2. Klik tab "Perjalanan"
3. Klik tab "Offset Karbon"

**Expected Result**: 
- Tab berubah dengan smooth animation
- Data loading pada tab yang dipilih
- Indicator aktif di tab yang benar

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

#### Test Case HIST-002: Navigation dari Donasi ke History
**Tujuan**: Verifikasi navigation setelah donasi  
**Langkah**:
1. Buat donasi baru
2. Setelah payment dialog

**Expected Result**: 
- Redirect ke tab "Riwayat"
- Bottom nav visible
- Tab "Offset Karbon" aktif (atau dapat diakses)

**Status**: [ ] Pass [ ] Fail  
**Catatan**: _______________________

---

## 3. TEMPLATE PEMANTAUAN PENGUJIAN

### Status Keseluruhan Pengujian

| Modul | Total Test Case | Pass | Fail | Pending | % Complete |
|-------|----------------|------|------|---------|------------|
| Autentikasi | 4 | 0 | 0 | 4 | 0% |
| Tracking | 3 | 0 | 0 | 3 | 0% |
| Donasi | 4 | 0 | 0 | 4 | 0% |
| Profil | 4 | 0 | 0 | 4 | 0% |
| Riwayat | 2 | 0 | 0 | 2 | 0% |
| **TOTAL** | **17** | **0** | **0** | **17** | **0%** |

---

### Log Eksekusi Pengujian

| No | Test Case ID | Tester | Tanggal | Waktu | Status | Issue ID | Catatan |
|----|-------------|---------|---------|-------|--------|----------|---------|
| 1 | AUTH-001 | | | | | | |
| 2 | AUTH-002 | | | | | | |
| 3 | AUTH-003 | | | | | | |
| ... | ... | | | | | | |

---

### Template Laporan Issue

**Issue ID**: BUG-001  
**Test Case ID**: AUTH-002  
**Severity**: [ ] Critical [ ] High [ ] Medium [ ] Low  
**Deskripsi Masalah**: 
_[Jelaskan bug yang ditemukan]_

**Langkah Reproduksi**:
1. 
2. 
3. 

**Expected Result**: 
_[Apa yang seharusnya terjadi]_

**Actual Result**: 
_[Apa yang benar-benar terjadi]_

**Screenshot/Log**: 
_[Lampirkan jika ada]_

**Status**: [ ] Open [ ] In Progress [ ] Fixed [ ] Closed  
**Assigned To**: _______________________  
**Target Fix Date**: _______________________

---

## 4. PENGENDALIAN PENGUJIAN

### Kriteria Pass/Fail

**Pass**: 
- Semua langkah berhasil dieksekusi tanpa error
- Output sesuai expected result
- Tidak ada crash atau freeze

**Fail**: 
- Ada error/exception yang muncul
- Output tidak sesuai expected result
- Aplikasi crash atau tidak responsif
- Data tidak tersimpan dengan benar

### Tindakan Korektif

Jika ditemukan **Fail**:
1. ✅ Catat di log issue dengan detail lengkap
2. ✅ Tentukan severity (Critical/High/Medium/Low)
3. ✅ Assign ke developer untuk perbaikan
4. ✅ Re-test setelah fix
5. ✅ Update status di tracking table

### Frekuensi Pemantauan

- **Harian**: Update log eksekusi untuk test yang sudah dijalankan
- **Mingguan**: Review % completion dan issue summary
- **Sprint End**: Full regression test semua fitur

---

## 5. CARA MENJALANKAN PENGUJIAN MANUAL

### Persiapan
```bash
# 1. Pastikan database Supabase aktif
# 2. Jalankan aplikasi di Chrome
flutter run -d chrome

# Atau build untuk testing
flutter build web
```

### Eksekusi Test Case
1. Buka dokumen ini
2. Pilih test case yang akan dijalankan
3. Ikuti langkah-langkah dengan TELITI
4. Catat hasilnya di kolom Status
5. Jika fail, buat laporan issue
6. Update tabel monitoring

### Tips Pengujian
- ✅ Test satu fitur pada satu waktu
- ✅ Gunakan akun test khusus (bukan akun production)
- ✅ Clear cache browser sebelum test autentikasi
- ✅ Screenshot setiap bug yang ditemukan
- ✅ Test di berbagai kondisi (online/offline jika relevan)

---

## 6. CHECKLIST SEBELUM RELEASE

- [ ] Semua test case AUTH Pass
- [ ] Semua test case TRACK Pass
- [ ] Semua test case DON Pass
- [ ] Semua test case PROF Pass
- [ ] Semua test case HIST Pass
- [ ] Tidak ada Critical/High severity issue yang open
- [ ] Performance testing (load time < 3s)
- [ ] Security testing (OWASP Top 10)
- [ ] Browser compatibility (Chrome, Edge, Firefox)
- [ ] Mobile responsive testing

---

**Disiapkan oleh**: _______________________  
**Tanggal**: _______________________  
**Versi Dokumen**: 1.0
