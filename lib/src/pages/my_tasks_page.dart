import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_list.dart';

enum MyTasksType { published, claimed }

class MyTasksPage extends StatelessWidget {
  final MyTasksType type;

  const MyTasksPage({super.key, required this.type});

  String get _pageTitle => type == MyTasksType.published ? '我發布的任務' : '我承接的任務';

  List<Task> _getTasks(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final userId = context.watch<AuthProvider>().user?.uid;

    if (userId == null) return [];

    if (type == MyTasksType.published) {
      return taskProvider.getPublishedTasksByUser(userId);
    } else {
      return taskProvider.getClaimedTasksByUser(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _getTasks(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/profile')),
      ),
      body: TaskList(tasks: tasks),
    );
  }
}
