// lib/config/supabase_config.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  
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

// lib/repositories/auth_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );
    
    // Create profile after successful signup
    if (response.user != null) {
      await createProfile(response.user!.id, email, fullName);
    }
    
    return response;
  }

  // Create user profile
  Future<void> createProfile(String userId, String email, String fullName) async {
    await _client.from('profiles').insert({
      'id': userId,
      'email': email,
      'full_name': fullName,
      'role': 'employee',
      'is_active': true,
      'leave_balance': {},
    });
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final userId = SupabaseConfig.currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserProfile.fromJson(response);
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get auth stream for listening to auth changes
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;
}