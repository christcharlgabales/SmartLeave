// lib/repositories/user_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user_profile.dart';

class UserRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  // Get user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<UserProfile> updateUserProfile(UserProfile profile) async {
    final response = await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id)
        .select()
        .single();

    return UserProfile.fromJson(response);
  }

  // Get team members (for managers)
  Future<List<UserProfile>> getTeamMembers(String managerId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('manager_id', managerId)
        .eq('is_active', true)
        .order('full_name');

    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }

  // Update leave balance
  Future<void> updateLeaveBalance(
    String userId, 
    Map<String, double> newBalance
  ) async {
    await _client
        .from('profiles')
        .update({'leave_balance': newBalance})
        .eq('id', userId);
  }

  // Get all users (for HR/Admin)
  Future<List<UserProfile>> getAllUsers() async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('is_active', true)
        .order('full_name');

    return (response as List)
        .map((json) => UserProfile.fromJson(json))
        .toList();
  }
}