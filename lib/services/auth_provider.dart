// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:quickbite/model/user_model.dart';

import 'package:quickbite/services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = true; // Start with true for initial load
  String? _error;
  UserModel? _currentUser;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get loading => _isLoading;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    clearError();

    try {
      await SupabaseService.instance.signIn(email: email, password: password);
      await loadCurrentUser(); // Reload user data after sign-in
    } catch (e) {
      final errorMessage = _getAuthErrorMessage(e);
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await SupabaseService.instance.signOut();
      _currentUser = null;
      notifyListeners(); // This will trigger the router redirect
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = SupabaseService.instance.currentUser;
      if (user != null) {
        // Even if we can't get the profile, we can still consider the user logged in
        // with basic information from the auth user
        _currentUser = UserModel(
          id: user.id,
          email: user.email ?? '',
          name: user.email?.split('@')[0] ?? 'User',

          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      } else {
        _currentUser = null;
      }
    } catch (e) {
      // If there's an error, we'll still set the user to null but won't throw
      _currentUser = null;
      setError(e.toString());
    } finally {
      // Always set loading to false
      setLoading(false);
    }
  }

  String _getAuthErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('invalid email or password')) {
      return 'Invalid email or password. Please check your credentials.';
    }

    if (errorString.contains('email already in use')) {
      return 'This email is already registered. Please use a different email or try logging in.';
    }

    if (errorString.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your connection and try again.';
    }

    if (errorString.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    }

    return 'Authentication failed. Please try again.';
  }
}
