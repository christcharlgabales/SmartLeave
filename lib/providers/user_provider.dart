// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  
  List<UserProfile> _teamMembers = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<UserProfile> get teamMembers => _teamMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadTeamMembers(String managerId) async {
    _setLoading(true);
    try {
      _teamMembers = await _userRepository.getTeamMembers(managerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    _setLoading(true);
    try {
      await _userRepository.updateUserProfile(profile);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}