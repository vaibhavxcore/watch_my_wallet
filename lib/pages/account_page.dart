import 'package:flutter/material.dart';
import 'package:watch_my_wallet/auth/auth_service.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _authService = AuthService();

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Are you sure?'),
          content: Text('Do you really want to logout from the app?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _authService.signOut();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: Text('Logout'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(foregroundColor: Colors.black),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_authService.getCurrentUserEmail()!),
            IconButton(
              onPressed: () {
                _showLogoutDialog();
              },
              icon: Icon(Icons.logout),
            ),
          ],
        ),
      ),
    );
  }
}
