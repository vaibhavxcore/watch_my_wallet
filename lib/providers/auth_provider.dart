import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isGuestAuthorized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGuestAuthorized => _isGuestAuthorized;

  void initialize() {
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _isGuestAuthorized = false;
      }
      notifyListeners();
    });
  }

  void continueOffline() {
    _isGuestAuthorized = true;
    _error = null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    _isGuestAuthorized = false;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
    } catch (e) {
      _error = e.toString().contains('Invalid login credentials')
          ? 'Invalid email or password.'
          : 'Sign in failed. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    _isGuestAuthorized = false;
    notifyListeners();
    try {
      await _authService.signUpWithEmailAndPassword(email, password);
    } catch (e) {
      _error = 'Sign up failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isGuestAuthorized = false;
    await _authService.signOut();
    notifyListeners();
  }
}
