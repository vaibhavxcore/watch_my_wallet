import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/pages/main_layout.dart';
import 'package:watch_my_wallet/providers/auth_provider.dart';
import '../pages/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Consume AuthProvider instead of using StreamBuilder directly
    final authProvider = context.watch<AuthProvider>();

    if (authProvider.user != null) {
      return const MainLayout();
    } else {
      return const LoginPage();
    }
  }
}
