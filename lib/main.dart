import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watch_my_wallet/screens/splash_screen.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://ogszlpztuzbiynfpaawl.supabase.co',
    publishableKey: 'sb_publishable_ZPInXnFqS3L59Lv1bJpHqA_B_Qx85pv',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
