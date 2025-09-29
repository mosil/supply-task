import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';

class UserProfilePage extends StatelessWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final user = authProvider.user;

    if (user == null) {
      // This should not happen if routing is correct, but as a fallback
      return const Scaffold(
        body: Center(child: Text('使用者未登入')),
      );
    }

    final publishedTasks = taskProvider.getPublishedTasksByUser(user.uid);
    final claimedTasks = taskProvider.getClaimedTasksByUser(user.uid);

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
              context.read<AuthProvider>().signOut();
              // The router redirect will handle navigation to login page
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
          if (publishedTasks.isNotEmpty)
            ElevatedButton(
              child: const Text('我發布的任務'),
              onPressed: () => context.go('/my-tasks/published'),
            ),
          const SizedBox(height: 12),
          if (claimedTasks.isNotEmpty)
            ElevatedButton(
              child: const Text('我承接的任務'),
              onPressed: () => context.go('/my-tasks/claimed'),
            ),
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
