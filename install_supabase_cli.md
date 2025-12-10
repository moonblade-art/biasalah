# Install Supabase CLI di Windows

## Metode 1: Via npm (Recommended)
```bash
# Install Node.js dulu jika belum ada
# Download dari: https://nodejs.org/

# Install Supabase CLI
npm install -g supabase

# Verify installation
supabase --version
```

## Metode 2: Via Chocolatey
```bash
# Install Chocolatey dulu jika belum ada
# Jalankan PowerShell as Administrator

# Install Supabase CLI
choco install supabase

# Verify installation
supabase --version
```

## Metode 3: Via Scoop
```bash
# Install Scoop dulu jika belum ada
# Jalankan PowerShell

# Install Supabase CLI
scoop bucket add supabase https://github.com/supabase/scoop-bucket.git
scoop install supabase

# Verify installation
supabase --version
```

## Metode 4: Download Binary Manual
1. Download dari: https://github.com/supabase/cli/releases
2. Extract ke folder (misal: C:\supabase)
3. Add ke PATH environment variable
4. Restart terminal

## Setelah Install
```bash
# Login ke Supabase
supabase login

# Link ke project
supabase link --project-ref YOUR_PROJECT_REF

# Deploy function
supabase functions deploy midtrans-payment --no-verify-jwt
```