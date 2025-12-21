# 🚀 Quick Test Guide - Midtrans Integration

## ✅ **Credentials Configured**
- **Merchant ID**: `YOUR_MIDTRANS_MERCHANT_ID`
- **Client Key**: `YOUR_MIDTRANS_CLIENT_KEY`
- **Server Key**: `YOUR_MIDTRANS_SERVER_KEY`

> [!IMPORTANT]
> **Security Warning**: Real production keys must never be committed to the repository. Store them securely in environment variables (.env), Supabase Secrets, or a dedicated secret manager.

## 🔧 **Step 1: Deploy Backend**

```bash
# Install Supabase CLI (if not installed)
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the function
supabase functions deploy midtrans-payment --no-verify-jwt
```

## 🧪 **Step 2: Test Connection**

### Option A: Using Flutter Test Screen
1. Add test screen to your app navigation
2. Navigate to `MidtransTestScreen`
3. Click "Test Koneksi Midtrans"
4. Check results

### Option B: Using cURL
```bash
# Replace YOUR_PROJECT_REF and YOUR_JWT_TOKEN
curl -X GET "https://YOUR_PROJECT_REF.supabase.co/functions/v1/midtrans-payment/test-connection" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -H "apikey: YOUR_ANON_KEY" \
     -H "Content-Type: application/json"
```

## 📱 **Step 3: Test Donation Flow**

### Real Payment Test:
1. Open app → Donation screen
2. Select community and carbon amount
3. Click "Donasi" button
4. Choose "Payment Gateway Real"
5. Complete payment in Midtrans

### Simulation Test:
1. Follow steps 1-3 above
2. Choose "Simulasi (Testing)"
3. Verify donation appears in history

## 🔍 **Expected Results**

### ✅ Successful Connection Test:
```json
{
  "success": true,
  "message": "Midtrans connection successful!",
  "test_results": {
    "payment_creation": {
      "status": "success",
      "token": "present",
      "redirect_url": "present"
    },
    "status_check": {
      "status": "success",
      "transaction_status": "pending"
    }
  },
  "credentials": {
    "merchant_id": "YOUR_MIDTRANS_MERCHANT_ID",
    "client_key": "present",
    "server_key": "present"
  }
}
```

### ❌ Failed Connection (Common Issues):
```json
{
  "success": false,
  "message": "Midtrans connection failed",
  "error": "401 Unauthorized",
  "status_code": 401
}
```

## 🛠️ **Troubleshooting**

### Issue 1: 401 Unauthorized
- **Cause**: Invalid server key
- **Solution**: Verify server key in Edge Function

### Issue 2: Function Not Found
- **Cause**: Function not deployed
- **Solution**: Run deploy command again

### Issue 3: CORS Error
- **Cause**: Missing headers
- **Solution**: Check Edge Function CORS configuration

### Issue 4: JWT Token Invalid
- **Cause**: User not authenticated
- **Solution**: Ensure user is logged in

## 📊 **Monitoring**

### View Function Logs:
```bash
supabase functions logs midtrans-payment --follow
```

### Check Midtrans Dashboard:
1. Login to https://dashboard.sandbox.midtrans.com/
2. Go to Transactions
3. Look for test transactions

## 🎯 **Success Criteria**

- [ ] Edge Function deploys without errors
- [ ] Connection test returns success
- [ ] Payment creation works
- [ ] Status check works
- [ ] Flutter app can create donations
- [ ] Payment URLs are generated
- [ ] Webhook receives notifications (optional for testing)

## 📞 **Next Steps After Success**

1. **Configure Webhook** in Midtrans Dashboard:
   ```
   https://YOUR_PROJECT_REF.supabase.co/functions/v1/midtrans-payment/webhook
   ```

2. **Test Real Payment** with test cards:
   - Success: `4811 1111 1111 1114`
   - Failure: `4911 1111 1111 1113`

3. **Monitor Transactions** in both:
   - Supabase Dashboard → Functions → Logs
   - Midtrans Dashboard → Transactions

4. **Production Setup** (when ready):
   - Change credentials to production
   - Update webhook URL
   - Set `_isProduction = true`

## 🚨 **Important Notes**

- **Security**: Server key is only in backend, never in Flutter app
- **Testing**: Use sandbox environment for all tests
- **Logging**: All transactions are logged for debugging
- **Fallback**: Simulation mode available for development

## ✅ **Status Checklist**

- [x] Credentials configured
- [x] Backend Edge Function created
- [x] Flutter service updated
- [x] Test screen available
- [x] Connection test implemented
- [ ] Function deployed (your action)
- [ ] Connection test passed (your action)
- [ ] Payment flow tested (your action)