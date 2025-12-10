#!/bin/bash

# Deploy and Test Midtrans Integration
# Make sure you have Supabase CLI installed and logged in

echo "🚀 Deploying Midtrans Payment Edge Function..."

# Deploy the function
echo "📦 Deploying function..."
supabase functions deploy midtrans-payment --no-verify-jwt

if [ $? -eq 0 ]; then
    echo "✅ Function deployed successfully!"
    
    # Test the connection
    echo "🧪 Testing Midtrans connection..."
    
    # Get your project URL (replace with your actual project ref)
    PROJECT_REF="your-project-ref"
    ANON_KEY="your-anon-key"
    
    echo "📡 Testing connection endpoint..."
    curl -X GET "https://${PROJECT_REF}.supabase.co/functions/v1/midtrans-payment/test-connection" \
         -H "Authorization: Bearer ${ANON_KEY}" \
         -H "Content-Type: application/json" \
         -w "\n\nResponse Time: %{time_total}s\n" \
         -s | jq '.'
    
    echo ""
    echo "🎯 Next steps:"
    echo "1. Update PROJECT_REF and ANON_KEY in this script"
    echo "2. Run the test again with your actual credentials"
    echo "3. Test the Flutter app donation flow"
    echo "4. Configure webhook in Midtrans dashboard"
    
else
    echo "❌ Function deployment failed!"
    exit 1
fi