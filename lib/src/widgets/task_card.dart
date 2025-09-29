import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias, // Adds a nice ripple effect on tap
      child: InkWell(
        onTap: () {
          context.go('/task/${task.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.name, style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('發布人: ${task.publisherName}', style: textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(
                '發布時間: ${DateFormat('yyyy/MM/dd HH:mm').format(task.publishedAt)}',
                style: textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              _buildStatus(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatus(BuildContext context) {
    final List<Widget> statusWidgets = [];

    if (task.status == TaskStatus.claimed) {
      statusWidgets.add(_StatusTag(text: '認領', color: Colors.blue));
    } else if (task.status == TaskStatus.completed) {
      statusWidgets.add(_StatusTag(text: '已完成', color: Colors.green));
    }

    if (task.statusChangedAt != null &&
        (task.status == TaskStatus.claimed || task.status == TaskStatus.completed)) {
      if (statusWidgets.isNotEmpty) {
        statusWidgets.add(const SizedBox(width: 8));
      }
      statusWidgets.add(Text(
        '狀態變更: ${DateFormat('yyyy/MM/dd HH:mm').format(task.statusChangedAt!)}',
        style: Theme.of(context).textTheme.bodySmall,
      ));
    }

    if (statusWidgets.isEmpty) {
      return const SizedBox.shrink(); // 如果沒有狀態標籤和時間，則不顯示任何東西
    }

    return Row(children: statusWidgets);
  }
}

class _StatusTag extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
