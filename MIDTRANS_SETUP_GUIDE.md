# Midtrans Integration Setup Guide

## 🔑 **Credentials**
- **Merchant ID**: `YOUR_MIDTRANS_MERCHANT_ID`
- **Client Key**: `YOUR_MIDTRANS_CLIENT_KEY`
- **Server Key**: `YOUR_MIDTRANS_SERVER_KEY`

> [!IMPORTANT]
> **Security Warning**: Real production keys must never be committed to the repository. Store them securely in environment variables (.env), Supabase Secrets, or a dedicated secret manager.

## 🏗️ **Architecture**

```
Flutter App → Supabase Edge Function → Midtrans API → Payment Gateway
     ↓                    ↓                 ↓              ↓
User Interface → Backend Proxy → Payment Processing → User Payment
```

## 📋 **Setup Steps**

### 1. Deploy Supabase Edge Function
```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy the function
supabase functions deploy midtrans-payment --no-verify-jwt
```

### 2. Configure Midtrans Dashboard
1. Login to Midtrans Dashboard: https://dashboard.sandbox.midtrans.com/
2. Go to Settings → Configuration
3. Set Webhook URL:
   ```
   https://YOUR_PROJECT_REF.supabase.co/functions/v1/midtrans-payment/webhook
   ```
4. Enable webhook notifications for:
   - Payment success
   - Payment failure
   - Payment pending

### 3. Test the Integration

#### Test Payment Creation:
```bash
curl -X POST 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/midtrans-payment/create-payment' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "order_id": "TEST-123",
    "amount": 50000,
    "customer_email": "test@example.com",
    "customer_name": "Test User",
    "item_name": "Test Donation"
  }'
```

#### Test Payment Status:
```bash
curl 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/midtrans-payment/payment-status?order_id=TEST-123' \
  -H 'Authorization: Bearer YOUR_JWT_TOKEN'
```

## 🔄 **Payment Flow**

### 1. User Initiates Donation
- User selects community and carbon amount
- App calculates donation amount
- User clicks "Donasi" button

### 2. Payment Creation
- App calls `createDonation()` in DonationService
- Service calls Supabase Edge Function
- Edge Function calls Midtrans API
- Returns payment URL to app

### 3. Payment Process
- User chooses payment mode (Real/Simulation)
- For Real: Opens Midtrans payment page
- For Simulation: Marks payment as successful immediately

### 4. Payment Completion
- Midtrans sends webhook to Edge Function
- Edge Function updates donation status
- User receives notification
- Carbon offset is applied to user profile

## 🧪 **Testing Scenarios**

### Test Cases:
1. **Successful Payment**
   - Create donation → Open payment → Complete payment → Verify status
   
2. **Failed Payment**
   - Create donation → Open payment → Cancel payment → Verify status
   
3. **Expired Payment**
   - Create donation → Wait 24 hours → Check status
   
4. **Simulation Mode**
   - Create donation → Choose simulation → Verify immediate success

### Test Cards (Sandbox):
- **Success**: `4811 1111 1111 1114`
- **Failure**: `4911 1111 1111 1113`
- **Challenge**: `4411 1111 1111 1118`

## 🔒 **Security Features**

### Implemented:
- ✅ Server key stored securely in backend
- ✅ JWT authentication for API calls
- ✅ Input validation and sanitization
- ✅ Webhook signature verification
- ✅ CORS protection
- ✅ Rate limiting (via Supabase)

### Best Practices:
- 🔒 Never expose server key in client code
- 🔒 Always validate webhook signatures
- 🔒 Use HTTPS for all communications
- 🔒 Log all payment transactions
- 🔒 Implement proper error handling

## 📊 **Monitoring & Logs**

### View Function Logs:
```bash
supabase functions logs midtrans-payment
```

### Monitor Payments:
1. Check Supabase Dashboard → Functions → Logs
2. Check Midtrans Dashboard → Transactions
3. Check app database → donations table

## 🚀 **Production Deployment**

### Before Going Live:
1. Change `isDevelopment = false` in PaymentConfig
2. Update Midtrans credentials to production keys
3. Update webhook URL to production domain
4. Test with real payment methods
5. Set up monitoring and alerting

### Production Checklist:
- [ ] Production Midtrans account setup
- [ ] Production webhook configured
- [ ] SSL certificate valid
- [ ] Error monitoring setup
- [ ] Backup and recovery plan
- [ ] Load testing completed

## 🆘 **Troubleshooting**

### Common Issues:

1. **CORS Error**
   - Solution: Use backend proxy (Edge Function)
   
2. **Authentication Failed**
   - Check JWT token validity
   - Verify Supabase auth configuration
   
3. **Webhook Not Received**
   - Check webhook URL in Midtrans dashboard
   - Verify Edge Function deployment
   
4. **Payment Status Not Updated**
   - Check webhook logs
   - Verify database permissions
   
5. **Function Timeout**
   - Optimize function code
   - Check Midtrans API response time

### Debug Commands:
```bash
# Check function status
supabase functions list

# View real-time logs
supabase functions logs midtrans-payment --follow

# Test function locally
supabase functions serve midtrans-payment
```

## 📞 **Support**

- **Midtrans Documentation**: https://docs.midtrans.com/
- **Supabase Edge Functions**: https://supabase.com/docs/guides/functions
- **Flutter URL Launcher**: https://pub.dev/packages/url_launcher

## ✅ **Status**

- ✅ Backend Edge Function created
- ✅ Flutter service updated
- ✅ Payment flow implemented
- ✅ Webhook handling ready
- ✅ Testing modes available
- 🚧 Ready for deployment and testing