# 🚀 Quick Setup - Test Midtrans Tanpa CLI

## 🎯 **Situasi Saat Ini**
- Supabase CLI belum terinstall
- Integrasi Midtrans sudah siap
- Database donations sudah tersambung
- Perlu test payment flow

## ⚡ **Solusi Cepat (5 Menit)**

### **Step 1: Test Database Connection**
1. Buka Supabase Dashboard: https://supabase.com/dashboard
2. Pilih project EcoTrack
3. Go to **SQL Editor**
4. Copy-paste isi file `verify_database_connection.sql`
5. Run query
6. Pastikan semua check return "✅ PASS"

### **Step 2: Test Flutter Integration**
1. Buka Flutter app
2. Go to Donation screen
3. Pilih komunitas dan jumlah karbon
4. Click "Donasi"
5. Pilih "Payment Gateway Real"
6. Check console logs untuk melihat proses

### **Step 3: Verify Database Record**
1. Kembali ke Supabase Dashboard → SQL Editor
2. Run query:
   ```sql
   SELECT * FROM public.donations ORDER BY created_at DESC LIMIT 5;
   ```
3. Pastikan donation record muncul dengan status 'pending'

## 🧪 **Expected Results**

### ✅ **Successful Test**:
```
Console Logs:
=== Creating Midtrans Payment ===
Order ID: DONATION-1234567890
Amount: 50000.0
🧪 Attempting direct Midtrans API call for testing...
📥 Midtrans response status: 201
✅ Direct Midtrans payment URL created: https://app.sandbox.midtrans.com/...
```

### ✅ **Database Record**:
```sql
id | user_id | amount | payment_status | midtrans_order_id | created_at
---|---------|--------|----------------|-------------------|------------
xxx| xxx     | 50000  | pending        | DONATION-123...   | 2024-12-02...
```

## 🔧 **Troubleshooting**

### **Issue 1: CORS Error**
- **Expected**: Direct API call mungkin gagal karena CORS
- **Solution**: App akan fallback ke mock URL
- **Status**: Normal untuk testing

### **Issue 2: Database Permission Error**
- **Check**: RLS policies di Supabase
- **Solution**: Run database verification SQL

### **Issue 3: Authentication Error**
- **Check**: User sudah login di app
- **Solution**: Logout dan login ulang

## 📊 **Success Criteria**

- [ ] Database verification query returns all ✅ PASS
- [ ] Flutter app dapat create donation record
- [ ] Payment URL generated (real atau mock)
- [ ] Donation muncul di database dengan status 'pending'
- [ ] Console logs menunjukkan proses payment creation

## 🚀 **Next Steps (Optional)**

### **Install CLI untuk Production**:
```bash
# Via npm (recommended)
npm install -g supabase

# Atau via chocolatey
choco install supabase
```

### **Deploy Edge Function**:
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase functions deploy midtrans-payment --no-verify-jwt
```

## 📝 **Summary**

**CURRENT STATUS**: 
- ✅ Database integration ready
- ✅ Flutter service ready  
- ✅ Midtrans credentials configured
- ✅ Fallback testing mechanism active
- 🚧 Edge Function deployment pending (optional)

**TESTING APPROACH**:
1. Direct Midtrans API call (may fail due to CORS)
2. Fallback to Edge Function (if deployed)
3. Final fallback to mock URL (for testing)

**RESULT**: You can test the complete donation flow right now, even without CLI!