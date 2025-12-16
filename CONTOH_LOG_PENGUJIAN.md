# CONTOH LOG EKSEKUSI PENGUJIAN

**Periode Pengujian**: 16 Desember 2024  
**Tester**: [Nama Anda]  
**Versi Aplikasi**: 1.0.0

---

## CONTOH PENGISIAN - Test Case AUTH-001

### Test Case AUTH-001: Login dengan Kredensial Valid
**Status**: ✅ PASS  
**Dijalankan**: 16 Des 2024, 20:30  
**Durasi**: 2 menit  

**Langkah yang Dijalankan**:
1. ✅ Buka aplikasi di Chrome
2. ✅ Masukkan email: testuser@example.com
3. ✅ Masukkan password: Test123!@#
4. ✅ Klik tombol "Masuk"

**Hasil**:
- Login berhasil
- Redirect ke halaman Home dalam < 2 detik
- Bottom navigation terlihat dengan jelas
- Tidak ada error di console

**Screenshot**: [Opsional - lampirkan jika perlu]

**Catatan**: Semua berfungsi sesuai expected result

---

## CONTOH PENGISIAN - Test Case dengan FAIL

### Test Case PROF-002: Ubah Password
**Status**: ❌ FAIL  
**Dijalankan**: 16 Des 2024, 14:20  
**Durasi**: 3 menit  

**Langkah yang Dijalankan**:
1. ✅ Buka "Edit Profil"
2. ✅ Isi "Kata Sandi Saat Ini": OldPass123!
3. ✅ Isi "Kata Sandi Baru": NewPass456!@
4. ✅ Isi "Konfirmasi Kata Sandi Baru": NewPass456!@
5. ❌ Klik "Simpan Perubahan" - ERROR

**Hasil**:
- Error muncul: "Kata sandi saat ini salah"
- Password TIDAK berhasil diubah
- Form tidak ter-clear

**Issue Created**: BUG-001  
**Severity**: Medium  
**Root Cause**: Kemungkinan bug di verifikasi password lama

**Tindakan**:
- [x] Buat issue report BUG-001
- [x] Assign ke developer untuk fix
- [ ] Re-test setelah fix

---

## TEMPLATE KOSONG UNTUK COPY-PASTE

### Test Case [ID]: [Nama Test Case]
**Status**: [ ] PASS [ ] FAIL  
**Dijalankan**: ___________  
**Durasi**: ___________  

**Langkah yang Dijalankan**:
1. 
2. 
3. 

**Hasil**:


**Screenshot**: 

**Catatan**: 

**Issue Created** (jika fail): ___________

---

## SUMMARY HARIAN

**Tanggal**: 16 Desember 2024

| Modul | Test Case Dijalankan | Pass | Fail |
|-------|---------------------|------|------|
| Autentikasi | AUTH-001, AUTH-002 | 2 | 0 |
| Profil | PROF-002 | 0 | 1 |
| **TOTAL HARI INI** | **3** | **2** | **1** |

**Issue Ditemukan**: 1 (BUG-001)  
**Catatan**: Secara keseluruhan aplikasi berjalan baik, hanya 1 bug minor di fitur change password

---

## TIPS MENGISI LOG

1. **Selalu catat tanggal & waktu** - penting untuk tracking
2. **Screenshot untuk bug** - bukti visual sangat membantu
3. **Tulis expected vs actual** - jelas bedanya apa
4. **Buat issue ID** - untuk tracking bug yang sama
5. **Update tabel summary** - untuk monitoring progress

## FORMAT ISSUE ID

- AUTH-XXX: Bug di modul autentikasi
- TRACK-XXX: Bug di modul tracking
- DON-XXX: Bug di modul donasi
- PROF-XXX: Bug di modul profil
- HIST-XXX: Bug di modul riwayat

Contoh: BUG-001 dari test PROF-002 → ID nya: PROF-001
