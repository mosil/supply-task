import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/shared/confirmation_dialog.dart';

class TaskDetailsPage extends StatelessWidget {
  final String taskId;

  const TaskDetailsPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final task = context.watch<TaskProvider>().getTaskById(taskId);
    final currentUser = context.watch<AuthProvider>().user;

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到任務或載入中...')),
      );
    }

    // Mock logic to determine user role
    final bool isPublisher = currentUser?.displayName == task.publisherName;
    final bool isClaimant = currentUser?.displayName == task.claimantName;
    final bool canClaim = !isPublisher && task.status == TaskStatus.published;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: Text(task.name),
        actions: [
          if (isPublisher)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              tooltip: '取消任務',
              onPressed: () => showConfirmationDialog(
                context: context,
                title: '確認取消任務',
                content: const Text('您確定要取消這個任務嗎？此操作無法復原。'),
                confirmButtonText: '確定取消',
                onConfirm: () {
                  // TODO: Implement cancel task logic
                  context.go('/');
                },
              ),
            ),
          if (isClaimant)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: '放棄任務',
              onPressed: () => showConfirmationDialog(
                context: context,
                title: '確認放棄任務',
                content: const Text('您確定要放棄這個任務嗎？放棄後，任務將會重新開放給其他人承接。'),
                confirmButtonText: '確定放棄',
                onConfirm: () {
                  // TODO: Implement abandon task logic
                  context.go('/');
                },
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(task.content, style: textTheme.bodyLarge),
            const SizedBox(height: 24),
            _buildInfoRow(context, Icons.location_on, '地址', task.address, () async {
              final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${task.address}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            }),
            const SizedBox(height: 16),
            const Divider(height: 48),
            _buildStatusCard(context, task),
            const SizedBox(height: 24),
            if (task.claimantName != null) _buildClaimantCard(context, task),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBottomButton(context, isPublisher, canClaim, task.id),
      ),
    );
  }

  Widget? _buildBottomButton(BuildContext context, bool isPublisher, bool canClaim, String taskId) {
    if (isPublisher) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.edit),
        label: const Text('編輯任務'),
        onPressed: () => context.go('/task/$taskId/edit'),
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      );
    }
    if (canClaim) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.pan_tool_alt_outlined),
        label: const Text('承接任務'),
        onPressed: () {
          // TODO: Implement claim logic
        },
        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
      );
    }
    return null; // No button if user is not publisher and cannot claim
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(decoration: onTap != null ? TextDecoration.underline : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('任務狀態', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.flag, '目前狀態', task.status.displayName, null),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.person_outline, '發布人', task.publisherName, null),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.access_time,
              '發布時間',
              DateFormat('yyyy/MM/dd HH:mm').format(task.publishedAt),
              null,
            ),
            if (task.editedAt != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(context, Icons.edit, '編輯時間', DateFormat('yyyy/MM/dd HH:mm').format(task.editedAt!), null),
            ],
            if (task.canceledAt != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.cancel,
                '取消時間',
                DateFormat('yyyy/MM/dd HH:mm').format(task.canceledAt!),
                null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClaimantCard(BuildContext context, Task task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('承接人狀態', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.person_pin, '承接人', task.claimantName!, null),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.event_available,
              '承接時間',
              DateFormat('yyyy/MM/dd HH:mm').format(task.claimedAt!),
              null,
            ),
            if (task.completedAt != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                context,
                Icons.check_circle,
                '完成時間',
                DateFormat('yyyy/MM/dd HH:mm').format(task.completedAt!),
                null,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
