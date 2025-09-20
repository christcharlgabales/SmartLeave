// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://igwvqebnplzvtapuxlqy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlnd3ZxZWJucGx6dnRhcHV4bHF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgzODYxNzUsImV4cCI6MjA3Mzk2MjE3NX0.hdjOW-mXLnN2zB4MaCQVFEo_mdcO30VUBZ7510Mqm2w';
  
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Set to false in production
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser => client.auth.currentUser;
  static String? get currentUserId => currentUser?.id;
}

