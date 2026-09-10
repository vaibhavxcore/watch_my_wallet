import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../auth/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomeState();
}

class _HomeState extends State<HomePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Color myColor = Colors.blue;
  Color appbarColor = Colors.blueGrey;
  final _authService = AuthService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
    if (kDebugMode) {
      appbarColor = Colors.red;
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: appbarColor,
        title: Text('My Wallet'),
        actions: [
          IconButton(
            onPressed: () {
              _showLogoutDialog();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),

      body: Center(child: Text("Welcome to Watch My Wallet")),
    );
  }
}
