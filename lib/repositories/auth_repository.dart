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

  // Sign up with email and password (using database trigger for profile creation)
  Future<AuthResponse> signUp(String email, String password, String fullName) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName}, // Pass to trigger instead of manual creation
    );
    
    return response;
  }

  // Get current user profile
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // Profile might not exist yet due to trigger delay
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Get auth stream for listening to auth changes
  Stream<AuthState> get authStateStream => _client.auth.onAuthStateChange;
}