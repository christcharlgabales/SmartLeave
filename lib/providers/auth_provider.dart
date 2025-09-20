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
      
      // If profile doesn't exist yet (database trigger delay), retry after a delay
      if (_currentUser == null && Supabase.instance.client.auth.currentUser != null) {
        await Future.delayed(const Duration(seconds: 2));
        _currentUser = await _authRepository.getCurrentUserProfile();
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
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
        return _currentUser != null;
      }
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
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
      return response.user != null;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e.toString());
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
      _errorMessage = _extractErrorMessage(e.toString());
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

  // Helper method to extract user-friendly error messages
  String _extractErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    }
    if (error.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account before signing in.';
    }
    if (error.contains('User already registered')) {
      return 'An account with this email already exists.';
    }
    if (error.contains('Password should be at least')) {
      return 'Password must be at least 6 characters long.';
    }
    if (error.contains('Unable to validate email address')) {
      return 'Please enter a valid email address.';
    }
    if (error.contains('infinite recursion')) {
      return 'Database configuration error. Please contact support.';
    }
    return 'Something went wrong. Please try again.';
  }
}