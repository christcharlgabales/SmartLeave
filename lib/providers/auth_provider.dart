// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  
  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Listen to auth changes
    _authRepository.authStateStream.listen((AuthState data) async {
      if (data.session?.user != null) {
        await _loadUserProfile();
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });

    // Load current user if already authenticated
    if (Supabase.instance.client.auth.currentUser != null) {
      await _loadUserProfile();
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      _currentUser = await _authRepository.getCurrentUserProfile();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _authRepository.signIn(email, password);
      if (response.user != null) {
        await _loadUserProfile();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signUp(String email, String password, String fullName) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final response = await _authRepository.signUp(email, password, fullName);
      if (response.user != null) {
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authRepository.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
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