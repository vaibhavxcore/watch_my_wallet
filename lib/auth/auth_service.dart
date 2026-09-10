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
  ) {
    return _supabaseClient.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    _supabaseClient.auth.signOut();
  }

  String? getCurrentUserEmail() {
    final session = _supabaseClient.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
