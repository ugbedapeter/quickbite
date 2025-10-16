// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:quickbite/model/user_model.dart';
import 'package:quickbite/pages/auth/login_page.dart';
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
      // ignore: unused_local_variable
      final resp = await SupabaseService.instance.signIn(
        email: email,
        password: password,
      );
      if (context.mounted) {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => DashboardPage()),
        // );
        notifyListeners();
      } else {
        setError('Login failed: No user returned.');
      }
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

      notifyListeners();
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
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
        _currentUser = await SupabaseService.instance.getUserProfile(user.id);
        notifyListeners();
      } else {
        _currentUser = null;
      }
    } catch (e) {
      setError(e.toString());
    } finally {
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
