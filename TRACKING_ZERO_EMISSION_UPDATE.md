# Update: Tracking dengan Emisi Nol

## Ringkasan Perubahan

Aplikasi EcoTrack sekarang mendukung penyimpanan data tracking bahkan ketika emisi karbon adalah nol (0). Ini memungkinkan pengguna untuk melacak perjalanan dengan sepeda, kendaraan listrik, atau perjalanan jarak sangat pendek.

## Perubahan yang Dilakukan

### 1. Database Schema
- **File**: `database/ecotrack_complete_schema.sql`
- **Perubahan**: Menambahkan support untuk `fuel_type = 'human'` untuk sepeda
- **File Tambahan**: `database/update_fuel_type_support.sql` untuk update database yang sudah ada

### 2. Vehicle Emission Calculator
- **File**: `lib/models/vehicle_emission_model.dart`
- **Perubahan**:
  - Mendukung vehicle type 'sepeda'/'bicycle' dengan emisi 0
  - Menangani kasus ketika emission factor tidak ditemukan (default ke 0)
  - Validasi vehicle type yang lebih fleksibel

### 3. Tracking Service
- **File**: `lib/services/tracking_service.dart`
- **Perubahan**:
  - Menghilangkan validasi yang terlalu ketat untuk distance dan emission
  - Menangani kasus emisi nol dengan graceful fallback
  - Menambahkan debug logging untuk troubleshooting
  - Otomatis menentukan fuel type berdasarkan emisi

### 4. Tracking Screen
- **File**: `lib/screens/home/tracking/tracking_screen.dart`
- **Perubahan**:
  - Memastikan data selalu disimpan meskipun distance = 0
  - Menambahkan catatan otomatis untuk perjalanan stasioner
  - Error handling yang lebih baik

### 5. Tracking Result Screen
- **File**: `lib/screens/home/tracking/tracking_result_screen.dart`
- **Perubahan**:
  - UI yang berbeda untuk emisi nol vs emisi positif
  - Pesan congratulatory untuk perjalanan ramah lingkungan
  - Tombol donasi hanya muncul jika ada emisi yang perlu di-offset

## Fitur Baru

### 1. Support Sepeda
- Sepeda sekarang dikenali sebagai kendaraan dengan emisi nol
- Fuel type otomatis diset ke 'human'
- Tampilan khusus untuk perjalanan ramah lingkungan

### 2. Perjalanan Jarak Nol
- Aplikasi dapat menyimpan tracking meskipun jarak = 0 km
- Berguna untuk testing atau perjalanan sangat pendek
- Otomatis menambahkan catatan "perjalanan stasioner"

### 3. Validasi yang Lebih Fleksibel
- Tidak lagi memblokir penyimpanan karena emisi nol
- Menangani edge cases dengan lebih baik
- Fallback ke emisi nol jika emission factor tidak ditemukan

## Cara Menggunakan

### Untuk Sepeda:
1. Pilih vehicle type "sepeda" di form tracking
2. Set CC ke 0 atau biarkan kosong
3. Lakukan tracking normal
4. Hasil akan menunjukkan emisi 0 kg CO₂
5. Pesan congratulatory akan ditampilkan

### Untuk Kendaraan Listrik:
1. Gunakan vehicle type normal (car/motorcycle)
2. Jika emission factor tidak ditemukan, otomatis akan diset ke 0
3. Fuel type otomatis diset ke 'electric'

### Untuk Perjalanan Pendek:
1. Lakukan tracking normal
2. Meskipun jarak sangat pendek atau 0, data tetap tersimpan
3. Catatan otomatis ditambahkan untuk perjalanan stasioner

## Testing

File test tersedia di `test_tracking_zero_emission.dart` untuk memverifikasi:
- Sepeda memiliki emisi nol
- Validasi vehicle type yang benar
- Fallback untuk kendaraan tidak dikenal

## Database Migration

Untuk database yang sudah ada, jalankan salah satu script berikut:

### Opsi 1: Script Otomatis (Recommended)
```sql
-- File: database/fix_bicycle_support.sql
-- Script ini akan otomatis menangani constraint yang ada
```

### Opsi 2: Manual Step-by-Step
```sql
-- File: database/update_fuel_type_support.sql
-- Jalankan step by step jika ada masalah dengan script otomatis
```

### Troubleshooting Database Error

Jika mendapat error constraint violation:
1. Jalankan `database/fix_bicycle_support.sql` terlebih dahulu
2. Pastikan tidak ada data yang melanggar constraint baru
3. Jika masih error, hapus data yang bermasalah atau update manual

## Catatan Penting

1. **Backward Compatibility**: Semua perubahan backward compatible
2. **Data Integrity**: Validasi tetap ada untuk mencegah data invalid
3. **User Experience**: UI memberikan feedback yang jelas untuk berbagai skenario
4. **Performance**: Tidak ada impact negatif pada performance

## Troubleshooting

Jika ada masalah dengan penyimpanan tracking:

1. Periksa log debug di console
2. Pastikan user sudah login (auth.currentUser tidak null)
3. Periksa koneksi database Supabase
4. Verifikasi RLS policies di Supabase dashboard

## Next Steps

1. Test dengan berbagai skenario real-world
2. Monitor error logs untuk edge cases
3. Pertimbangkan menambahkan lebih banyak vehicle types (e-scooter, dll)
4. Implementasi analytics untuk tracking zero-emission trips