import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Access the values from the .env file
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Initialize Supabase with values from .env
  static Future<void> initialize() async {
    await dotenv.load(); // Ensure the .env file is loaded

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
