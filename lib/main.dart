import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_my_wallet/providers/auth_provider.dart';
import 'package:watch_my_wallet/providers/expense_provider.dart';
import 'package:watch_my_wallet/screens/splash_screen.dart';
import 'package:watch_my_wallet/data/local/local_database.dart';

Future<void> main() async {
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
  late final Future<LocalDatabase> _localDatabase = LocalDatabase.open(
    key: 'watch-my-wallet-local-key',
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LocalDatabase>(
      future: _localDatabase,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildLoadingApp();
        }
        if (snapshot.hasError) {
          return _buildErrorApp(snapshot.error.toString());
        }

        final localDatabase = snapshot.data!;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
            ChangeNotifierProvider(
              create: (_) => ExpenseProvider(localDatabase)..initialize(),
            ),
          ],
          child: _buildApp(),
        );
      },
    );
  }

  Widget _buildApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Watch My Wallet',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }

  Widget _buildLoadingApp() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Watch My Wallet',
      theme: ThemeData(useMaterial3: true, primarySwatch: Colors.blue),
      home: const Scaffold(body: Center(child: FlutterLogo(size: 100))),
    );
  }

  Widget _buildErrorApp(String error) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Watch My Wallet',
      home: Scaffold(body: Center(child: Text('Local storage failed: $error'))),
    );
  }
}
