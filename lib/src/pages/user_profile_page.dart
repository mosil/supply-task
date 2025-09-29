import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    if (user == null) {
      // This should not happen if routing is correct, but as a fallback
      return const Scaffold(
        body: Center(child: Text('使用者未登入')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('使用者資料'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.go('/profile/edit');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthProvider>().logout();
              context.go('/');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoTile('Email', user.email),
          _buildInfoTile('顯示名稱', user.displayName),
          _buildInfoTile('聯絡資訊', user.contactInfo),
          _buildInfoTile('聯絡電話', user.phoneNumber),
          const Divider(height: 48),
          // TODO: Add buttons for published/claimed tasks
        ],
      ),
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
    );
  }
}
