import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('登入'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              // In a real app, you would have the Google logo image here.
              // For now, we use a placeholder icon.
              icon: const Icon(Icons.login), // Image.asset('assets/images/google_logo.png', height: 24.0),
              label: const Text('使用 Google 登入'),
              onPressed: () {
                // Use the mock login function
                context.read<AuthProvider>().login();
                // Navigate back to home page after login
                context.go('/');
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
