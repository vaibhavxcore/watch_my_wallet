import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
    String username,
  ) {
    return _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
  }

  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  String? getCurrentUsername() {
    final user = _supabaseClient.auth.currentUser;
    return user?.userMetadata?['username'] as String?;
  }

  String? getCurrentUserEmail() {
    return _supabaseClient.auth.currentUser?.email;
  }

  String? getCurrentUserUid() {
    return _supabaseClient.auth.currentUser?.id;
  }
}
