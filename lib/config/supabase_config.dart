// lib/config/supabase_config.dart

class SupabaseConfig {
  // Supabase project configuration
  static const String supabaseUrl = 'https://yfisgogkoewxllkhupka.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmaXNnb2drb2V3eGxsa2h1cGthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxNjUwODAsImV4cCI6MjA3OTc0MTA4MH0.AooPjUCaASz-KwzNBF26HN17mODZfgBE3uFxyJrqyv8';
  
  // Auth configuration
  static const bool enableEmailConfirmation = true;
  static const int sessionTimeoutHours = 24;
  
  // Database table names
  static const String usersTable = 'users';
  static const String tripHistoryTable = 'trip_history';
}