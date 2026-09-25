import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isGuestAuthorized = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isGuestAuthorized => _isGuestAuthorized;
  bool get isInitialized => _isInitialized;

  String? get username => _user?.userMetadata?['username'] as String?;

  Future<void> initialize() async {
    _user = Supabase.instance.client.auth.currentUser;

    // Check if guest mode was previously selected
    final isGuest = await _storage.read(key: 'is_guest_mode');
    if (_user == null && isGuest == 'true') {
      _isGuestAuthorized = true;
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      _user = data.session?.user;
      if (_user != null) {
        _isGuestAuthorized = false;
        await _storage.write(key: 'is_guest_mode', value: 'false');
      }
      notifyListeners();
    });

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> continueOffline() async {
    _isGuestAuthorized = true;
    _error = null;
    await _storage.write(key: 'is_guest_mode', value: 'true');
    notifyListeners();
  }

  String _cleanErrorMessage(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('network') ||
        lower.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    }
    return message;
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      _isGuestAuthorized = false;
      await _storage.write(key: 'is_guest_mode', value: 'false');
    } on AuthException catch (e) {
      _error = _cleanErrorMessage(e.message);
    } catch (e) {
      _error = _cleanErrorMessage(e.toString());
      if (_error == e.toString()) {
        _error = 'Sign in failed. Please check your connection.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String username) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signUpWithEmailAndPassword(email, password, username);
    } on AuthException catch (e) {
      _error = _cleanErrorMessage(e.message);
    } catch (e) {
      _error = _cleanErrorMessage(e.toString());
      if (_error == e.toString()) {
        _error = 'Sign up failed. Please try again.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isGuestAuthorized = false;
    await _storage.delete(key: 'is_guest_mode');
    await _authService.signOut();
    notifyListeners();
  }
}
