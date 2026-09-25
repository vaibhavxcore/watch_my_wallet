import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:watch_my_wallet/data/local/sync_service.dart';
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

    // Show a loading indicator until the AuthProvider has finished reading from secure storage
    if (!authProvider.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final user = authProvider.user;
    final isGuest = authProvider.isGuestAuthorized;

    final String targetId = user?.id ?? (isGuest ? 'guest' : 'unauthenticated');

    if (targetId != 'unauthenticated' && targetId != _lastBoundUserId) {
      _lastBoundUserId = targetId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final migrate = user != null;
        final expenseProvider = context.read<ExpenseProvider>();
        final syncService = context.read<SyncService>();

        // 1. Set the user context and migrate data if needed
        expenseProvider.setUserId(targetId, migrateGuest: migrate).then((_) {
          if (!mounted) return;
          if (user != null) {
            // 2. Attempt sync, but ALWAYS re-initialize UI data even if sync fails
            syncService.sync().whenComplete(() {
              if (mounted) {
                expenseProvider.initialize(showLoader: false);
              }
            });
          }
        });
      });
    } else if (targetId == 'unauthenticated') {
      _lastBoundUserId = null;
    }

    if (user != null || isGuest) {
      return const MainLayout();
    } else {
      return const LoginPage();
    }
  }
}
