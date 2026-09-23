import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/pages/main_layout.dart';
import 'package:watch_my_wallet/providers/auth_provider.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';

import '../pages/login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _lastBoundUserId;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final isGuest = authProvider.isGuestAuthorized;

    // Determine what the target user ID should be in the ExpenseProvider
    final String targetId = user?.id ?? 'guest';

    // sync ExpenseProvider user id whenever Auth state or guest Status changes
    if (targetId != _lastBoundUserId) {
      _lastBoundUserId = targetId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // If we have a real user, we migrate guest data if they were just a guest
        final migrate = user != null;
        context.read<ExpenseProvider>().setUserId(
          targetId,
          migrateGuest: migrate,
        );
      });
    }

    if (user != null || isGuest) {
      return const MainLayout();
    } else {
      return const LoginPage();
    }
  }
}
