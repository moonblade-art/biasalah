# PANDUAN TEST API MANUAL

## Kenapa Service Test Tidak Bisa Dijalankan?

**Masalah**:
- `flutter test` tidak support native plugins (shared_preferences, dll)
- Supabase butuh shared_preferences untuk storage
- Tidak bisa initialize Supabase dalam test environment

**Solusi**: Test API langsung dengan HTTP requests!

---

## 🚀 Cara Test Services Secara Manual

### Metode 1: Menggunakan Dart Script (RECOMMENDED)

```bash
# 1. Install http package dulu
dart pub add http

# 2. Jalankan script
dart run scripts/test_api_dart.dart
```

**Input yang diminta:**
- Email: addinkepri2005@gmail.com (atau email Anda)
- Password: password Anda

**Output yang ditampilkan:**
```
🔐 TEST 1: Login User
✅ Login BERHASIL
User ID: xxx-xxx-xxx
Last Sign In: 2024-12-16T13:48:37.123Z

👤 TEST 2: Get User Profile  
✅ Profile found:
  Nama: Anak Baik
  Email: addinkepri2005@gmail.com
  Emisi Belum Offset: 45.5 kg CO₂

💰 TEST 3: Get User Donations
✅ Found 3 donations:
  - Amount: Rp 50000, Status: success
  ...
```

---

### Metode 2: Menggunakan cURL (Quick Test)

#### Test 1: Login dan Cek Last Sign In
```bash
curl -X POST "https://yfisgogkoewxllkhupka.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8" \
  -H "Content-Type: application/json" \
  -d '{"email":"addinkepri2005@gmail.com","password":"YOUR_PASSWORD"}'
```

**Response (contoh):**
```json
{
  "access_token": "eyJhbGc...",
  "user": {
    "id": "xxx-xxx-xxx",
    "email": "addinkepri2005@gmail.com",
    "last_sign_in_at": "2024-12-16T13:48:37.123456Z"
  }
}
```

#### Test 2: Get User Profile
```bash
# Ganti ACCESS_TOKEN dengan token dari login
# Ganti USER_ID dengan user.id dari login

curl -X GET "https://yfisgogkoewxllkhupka.supabase.co/rest/v1/users?user_id=eq.USER_ID&select=*" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8" \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

#### Test 3: Get Donations
```bash
curl -X GET "https://yfisgogkoewxllkhupka.supabase.co/rest/v1/donations?user_id=eq.USER_ID&select=*&limit=10" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8" \
  -H "Authorization: Bearer ACCESS_TOKEN"
```

---

### Metode 3: Postman / Insomnia (GUI)

1. **Import Collection** (buat folder "EcoTrack API Tests")

2. **Setup Environment Variables:**
   - `{{base_url}}`: https://yfisgogkoewxllkhupka.supabase.co
   - `{{api_key}}`: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

3. **Request 1: Login**
   - Method: POST
   - URL: `{{base_url}}/auth/v1/token?grant_type=password`
   - Headers:
     - `apikey`: `{{api_key}}`
     - `Content-Type`: `application/json`
   - Body:
     ```json
     {
       "email": "addinkepri2005@gmail.com",
       "password": "YOUR_PASSWORD"
     }
     ```

4. **Request 2: Get Profile**
   - Method: GET
   - URL: `{{base_url}}/rest/v1/users?user_id=eq.{{user_id}}&select=*`
   - Headers:
     - `apikey`: `{{api_key}}`
     - `Authorization`: `Bearer {{access_token}}`

---

## 📊 Untuk Laporan Testing

### Template Hasil Test Manual:

**Tanggal**: 16 Desember 2024  
**Tester**: [Nama Anda]  
**Metode**: Manual API Testing dengan Dart Script

| Test ID | Endpoint | Method | Status | Waktu | Hasil |
|---------|----------|--------|--------|-------|-------|
| API-001 | /auth/v1/token | POST | ✅ PASS | 0.5s | Login berhasil, last_sign_in_at: 2024-12-16T13:48:37Z |
| API-002 | /rest/v1/users | GET | ✅ PASS | 0.3s | Profile ditemukan: Anak Baik, emisi: 45.5kg |
| API-003 | /rest/v1/donations | GET | ✅ PASS | 0.4s | 3 donations ditemukan |

**Evidence**:
```
✅ Login BERHASIL
User ID: abc-123-def-456
Last Sign In: 2024-12-16T13:48:37.123456Z
Email: addinkepri2005@gmail.com
```

---

## 🎯 Quick Commands

```bash
# Install http package untuk Dart script
dart pub add http

# Run Dart API test
dart run scripts/test_api_dart.dart

# Run dengan PowerShell (Windows)
scripts\test_api_manual.bat

# Run dengan bash (Linux/Mac)
bash scripts/test_api_manual.sh
```

---

## ✅ Keuntungan Testing Manual

1. **Tidak butuh Flutter environment** - Bisa test dari mana saja
2. **Real API testing** - Test API yang sebenarnya, bukan mock
3. **Easy to document** - Copy-paste response untuk laporan
4. **Flexible** - Bisa test endpoint apa saja
5. **Fast** - Tidak perlu build Flutter app

---

## 🔍 Troubleshooting

**Error: "Invalid login credentials"**
- Cek email dan password benar
- Pastikan user sudah terdaftar di Supabase

**Error: "Connection timeout"**
- Cek koneksi internet
- Pastikan Supabase URL benar

**Error: "Unauthorized"**
- Cek access_token masih valid
- Token expired setelah 1 jam, login ulang

---

**Dibuat**: 16 Desember 2024  
**Update terakhir**: 16 Desember 2024, 20:50
