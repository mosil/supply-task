import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: InkWell(
        onTap: () => context.go('/task/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.name, style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: FutureBuilder<UserProfile?>(
                      future: context.read<AuthProvider>().getUserById(task.publisherId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('讀取中...', style: TextStyle(color: Colors.grey));
                        }
                        final publisherName = snapshot.data?.displayName ?? '[未知使用者]';
                        return Text(publisherName, style: textTheme.bodySmall);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(DateFormat('yyyy/MM/dd').format(task.publishedAt), style: textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              _buildStatusChip(task.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    Color chipColor;
    String label;

    switch (status) {
      case TaskStatus.claimed:
        chipColor = Colors.blue.shade100;
        label = '已承接';
        break;
      case TaskStatus.completed:
        chipColor = Colors.green.shade100;
        label = '已完成';
        break;
      default:
        return const SizedBox.shrink(); // Do not show chip for other statuses
    }

    return Chip(
      label: Text(label),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
    );
  }
}
