@echo off
REM Manual API Testing untuk Supabase Services
REM File: test_api_manual.bat (Windows version)

SET SUPABASE_URL=https://yfisgogkoewxllkhupka.supabase.co
SET SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8

echo ===================================
echo EcoTrack API Manual Testing
echo ===================================
echo.

REM TEST 1: Login User
echo TEST 1: Login dengan Email ^& Password
echo ---------------------------------------
set /p USER_EMAIL="Email: "
set /p USER_PASSWORD="Password: "

echo.
echo Logging in...

curl -X POST "%SUPABASE_URL%/auth/v1/token?grant_type=password" ^
  -H "apikey: %SUPABASE_ANON_KEY%" ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"%USER_EMAIL%\",\"password\":\"%USER_PASSWORD%\"}" ^
  > login_response.json

echo.
echo Response saved to login_response.json
type login_response.json

echo.
echo.
echo MANUAL TESTING COMPLETED
echo Check login_response.json for results
echo.
echo To extract access_token, use:
echo jq -r '.access_token' login_response.json
echo.
pause
