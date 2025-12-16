#!/bin/bash
# Manual API Testing untuk Supabase Services
# File: test_api_manual.sh

# KONFIGURASI
SUPABASE_URL="https://yfisgogkoewxllkhupka.supabase.co"
SUPABASE_ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8"

echo "==================================="
echo "EcoTrack API Manual Testing"
echo "==================================="
echo ""

# TEST 1: Login User
echo "TEST 1: Login dengan Email & Password"
echo "---------------------------------------"
read -p "Email: " USER_EMAIL
read -sp "Password: " USER_PASSWORD
echo ""

LOGIN_RESPONSE=$(curl -s -X POST \
  "$SUPABASE_URL/auth/v1/token?grant_type=password" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASSWORD\"}")

echo "Response:"
echo "$LOGIN_RESPONSE" | jq '.'

# Extract access token
ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.access_token')
USER_ID=$(echo "$LOGIN_RESPONSE" | jq -r '.user.id')

if [ "$ACCESS_TOKEN" != "null" ]; then
  echo "✅ Login BERHASIL"
  echo "User ID: $USER_ID"
  echo "Token: ${ACCESS_TOKEN:0:50}..."
else
  echo "❌ Login GAGAL"
  exit 1
fi

echo ""
echo ""

# TEST 2: Get User Profile
echo "TEST 2: Get User Profile"
echo "---------------------------------------"
PROFILE_RESPONSE=$(curl -s -X GET \
  "$SUPABASE_URL/rest/v1/users?user_id=eq.$USER_ID&select=*" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Response:"
echo "$PROFILE_RESPONSE" | jq '.'

FULL_NAME=$(echo "$PROFILE_RESPONSE" | jq -r '.[0].full_name')
EMAIL=$(echo "$PROFILE_RESPONSE" | jq -r '.[0].email')
EMISI_BELUM=$(echo "$PROFILE_RESPONSE" | jq -r '.[0].emisi_belum_offset')

echo ""
echo "📊 User Profile:"
echo "  Nama: $FULL_NAME"
echo "  Email: $EMAIL"
echo "  Emisi Belum Offset: $EMISI_BELUM kg CO₂"

echo ""
echo ""

# TEST 3: Get User Donations
echo "TEST 3: Get User Donations"
echo "---------------------------------------"
DONATIONS_RESPONSE=$(curl -s -X GET \
  "$SUPABASE_URL/rest/v1/donations?user_id=eq.$USER_ID&select=*&limit=10&order=donated_at.desc" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

echo "Response:"
echo "$DONATIONS_RESPONSE" | jq '.'

DONATION_COUNT=$(echo "$DONATIONS_RESPONSE" | jq '. | length')

echo ""
echo "📊 Donations Summary:"
echo "  Total Donations: $DONATION_COUNT"

if [ "$DONATION_COUNT" -gt 0 ]; then
  echo "$DONATIONS_RESPONSE" | jq -r '.[] | "  - Donation ID: \(.id), Amount: Rp \(.amount), Status: \(.payment_status)"'
fi

echo ""
echo ""

# TEST 4: Check Last Login
echo "TEST 4: Check User Last Login (Auth Table)"
echo "---------------------------------------"
echo "User Email: $USER_EMAIL"
echo "User ID: $USER_ID"
echo "Last Sign In: $(echo "$LOGIN_RESPONSE" | jq -r '.user.last_sign_in_at')"

echo ""
echo ""
echo "==================================="
echo "Testing Selesai!"
echo "==================================="
