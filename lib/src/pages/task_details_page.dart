import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supply_task/src/providers/task_type_provider.dart';
import 'package:supply_task/src/models/user_profile.dart';
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
    final taskTypeProvider = context.watch<TaskTypeProvider>();

    if (task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('找不到任務或載入中...')),
      );
    }

    final String taskTypeName = taskTypeProvider.isLoading
        ? '讀取中...'
        : taskTypeProvider.getTaskTypeNameById(task.typeId);

    // Determine user role by comparing immutable IDs
    final bool isPublisher = currentUser?.uid == task.publisherId;
    final bool isClaimant = currentUser?.uid == task.claimantId;
    final bool canClaim = !isPublisher && task.status == TaskStatus.published;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
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
                  context.read<TaskProvider>().cancelTask(taskId);
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
                  context.read<TaskProvider>().abandonTask(taskId);
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
            _buildUserDisplayNameRow(context, Icons.person, '聯絡人', task.publisherId),
            if (task.contactInfo.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(context, Icons.info_outline, '聯絡資訊', task.contactInfo, null),
            ],
            if (task.contactPhone.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(context, Icons.phone, '聯絡電話', task.contactPhone, () async {
                final uri = Uri.parse('tel:${task.contactPhone}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              }),
            ],
            const Divider(height: 48),
            _buildStatusCard(context, task, taskTypeName),
            const SizedBox(height: 24),
            if (task.claimantId != null) _buildClaimantCard(context, task),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBottomButton(context, isPublisher, canClaim, task.id),
      ),
    );
  }

  Widget _buildUserDisplayNameRow(BuildContext context, IconData icon, String label, String userId) {
    final authProvider = context.read<AuthProvider>();

    return FutureBuilder<UserProfile?>(
      future: authProvider.getUserById(userId),
      builder: (context, snapshot) {
        String displayName = '讀取中...';
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            displayName = snapshot.data!.displayName;
          } else {
            displayName = '[使用者不存在]';
          }
        }
        return _buildInfoRow(context, icon, label, displayName, null);
      },
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
          showConfirmationDialog(
            context: context,
            title: '確認承接任務',
            content: const Text('您確定要承接這個任務嗎？'),
            confirmButtonText: '確定承接',
            onConfirm: () {
              final currentUser = context.read<AuthProvider>().user;
              if (currentUser != null) {
                context.read<TaskProvider>().claimTask(taskId, currentUser);
              }
            },
          );
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

  Widget _buildStatusCard(BuildContext context, Task task, String taskTypeName) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('任務狀態', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.category, '任務性質', taskTypeName, null),
            const SizedBox(height: 16),
            _buildInfoRow(context, Icons.flag, '目前狀態', task.status.displayName, null),
            const SizedBox(height: 16),
            _buildUserDisplayNameRow(context, Icons.person_outline, '發布人', task.publisherId),
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
            _buildUserDisplayNameRow(context, Icons.person_pin, '承接人', task.claimantId!),
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
