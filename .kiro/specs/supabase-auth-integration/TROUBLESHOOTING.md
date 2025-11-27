# 🔧 **TROUBLESHOOTING GUIDE**

## ❌ **Common SQL Errors**

### **Error: syntax error at or near "NOT"**
```
ERROR: 42601: syntax error at or near "NOT" 
LINE 34: CREATE POLICY IF NOT EXISTS "Avatar images are publicly accessible"
```

**Penyebab:** PostgreSQL tidak mendukung `IF NOT EXISTS` untuk `CREATE POLICY`

**Solusi:**
1. Gunakan `DROP POLICY IF EXISTS` terlebih dahulu
2. Atau setup storage policies manual via Dashboard
3. Gunakan script `simple-users-update.sql` yang sudah diperbaiki

### **Error: relation "storage.objects" does not exist**
**Penyebab:** Storage belum diaktifkan di Supabase project

**Solusi:**
1. Go to Supabase Dashboard → Storage
2. Initialize storage jika belum
3. Create bucket manual via Dashboard

### **Error: column already exists**
**Penyebab:** Column sudah ada dari run sebelumnya

**Solusi:** Script sudah menggunakan `ADD COLUMN IF NOT EXISTS`, jadi aman untuk dijalankan ulang

## ✅ **Recommended Setup Steps**

### **Step 1: Update Users Table**
Jalankan script ini di SQL Editor:
```sql
-- File: simple-users-update.sql
ALTER TABLE public.users 
ADD COLUMN IF NOT EXISTS phone TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS profile_picture_url TEXT,
ADD COLUMN IF NOT EXISTS total_donations DECIMAL(15, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS total_trips INTEGER DEFAULT 0;
```

### **Step 2: Setup Storage Manual**
1. **Dashboard** → **Storage** → **New Bucket**
2. Name: `avatars`
3. Public: `ON`
4. Save

### **Step 3: Setup Policies Manual**
1. **Storage** → **Policies** → **New Policy**
2. Create policies untuk SELECT, INSERT, UPDATE, DELETE
3. Use templates dari guide

### **Step 4: Verify Setup**
```sql
-- Check columns
SELECT column_name FROM information_schema.columns
WHERE table_name = 'users' AND table_schema = 'public'
AND column_name IN ('phone', 'address', 'profile_picture_url');

-- Check bucket
SELECT * FROM storage.buckets WHERE id = 'avatars';
```

## 🚀 **Alternative: Skip Storage Setup**

Jika storage setup bermasalah, aplikasi tetap bisa berjalan:

### **Temporary Solution:**
1. Hanya jalankan users table update
2. Profile picture akan menggunakan default avatar
3. Upload feature akan disabled sementara
4. Setup storage nanti setelah aplikasi running

### **Code Changes (Optional):**
```dart
// Di UserProfileService, comment out upload method
Future<String> uploadProfilePicture(String userId, File imageFile) async {
  // Temporary: return placeholder URL
  return 'https://via.placeholder.com/150';
  
  // TODO: Implement actual upload after storage setup
}
```

## 📝 **Verification Checklist**

### **Database:**
- [ ] Users table memiliki column baru (phone, address, profile_picture_url, total_donations, total_trips)
- [ ] Index idx_users_profile_picture created
- [ ] Comments added to columns

### **Storage:**
- [ ] Bucket 'avatars' exists
- [ ] Bucket is public
- [ ] Policies configured (SELECT, INSERT, UPDATE, DELETE)

### **App Testing:**
- [ ] Edit profile screen loads
- [ ] Form validation works
- [ ] Image picker works (if storage setup)
- [ ] Profile update saves to database
- [ ] Statistics screen shows real data
- [ ] Profile picture displays (if uploaded)

## 🆘 **Need Help?**

Jika masih ada masalah:
1. Check Supabase logs di Dashboard
2. Verify RLS policies di Authentication → Policies
3. Test dengan simple SQL queries dulu
4. Pastikan user sudah login dan authenticated

**Aplikasi tetap bisa berjalan tanpa storage setup, hanya upload gambar yang tidak berfungsi.**