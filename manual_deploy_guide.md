# Manual Deploy Edge Function via Supabase Dashboard

## 🎯 **Cara Deploy Tanpa CLI**

### Step 1: Buka Supabase Dashboard
1. Login ke https://supabase.com/dashboard
2. Pilih project EcoTrack Anda
3. Go to **Edge Functions** di sidebar kiri

### Step 2: Create New Function
1. Click **"Create a new function"**
2. Function name: `midtrans-payment`
3. Copy paste code dari file `supabase/functions/midtrans-payment/index.ts`

### Step 3: Deploy Function
1. Paste semua code ke editor
2. Click **"Deploy function"**
3. Wait for deployment to complete

## 📋 **Code to Copy-Paste**

### File: index.ts
```typescript
// Copy semua content dari supabase/functions/midtrans-payment/index.ts
// Paste ke Supabase Dashboard Edge Function editor
```

## 🧪 **Test Function After Deploy**

### Test URL:
```
https://YOUR_PROJECT_REF.supabase.co/functions/v1/midtrans-payment/test-connection
```

### Test via Browser/Postman:
1. Method: GET
2. URL: Function URL + `/test-connection`
3. Headers:
   - `Authorization: Bearer YOUR_ANON_KEY`
   - `apikey: YOUR_ANON_KEY`

## 🔍 **Get Your Project Details**

### Project Reference:
- Dashboard → Settings → General → Reference ID

### Anon Key:
- Dashboard → Settings → API → anon/public key

## ✅ **Verification Steps**

1. Function appears in Edge Functions list
2. Status shows "Active" 
3. Test endpoint returns success
4. Logs show no errors

## 🚨 **Common Issues**

### Issue 1: Function Not Found
- Check function name is exactly `midtrans-payment`
- Verify deployment completed successfully

### Issue 2: Authorization Error
- Check anon key is correct
- Verify project reference ID

### Issue 3: Code Errors
- Check TypeScript syntax
- Verify all imports are correct
- Check console logs for errors