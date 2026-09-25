import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_my_wallet/data/local/local_database.dart';
import 'package:watch_my_wallet/data/local/security_manager.dart';
import 'package:watch_my_wallet/providers/auth_provider.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';
import 'package:watch_my_wallet/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ogszlpztuzbiynfpaawl.supabase.co',
    publishableKey: 'sb_publishable_ZPInXnFqS3L59Lv1bJpHqA_B_Qx85pv',
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final _dbFuture = SecurityManager.getDatabaseKey().then(
    (k) => LocalDatabase.open(key: k),
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalDatabase>(
      future: _dbFuture,
      builder: (context, snapshot) {
        // While database is loading, show splash screen
        if (!snapshot.hasData) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SplashScreen(),
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
            ChangeNotifierProvider(
              create: (_) => ExpenseProvider(snapshot.data!)..initialize(),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Watch My Wallet',
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}
