import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/project_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final authProvider = context.watch<AuthProvider>();
    final projectProvider = context.watch<ProjectProvider>();

    final projectName = projectProvider.currentProjectName ?? '載入中...';
    final isProjectLoading = projectProvider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(projectName),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              if (authProvider.isLoggedIn) {
                context.go('/profile');
              } else {
                context.go('/login');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: '任務'),
            Tab(text: '執行中'),
            Tab(text: '完成'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          TaskList(tasks: taskProvider.publishedTasks),
          TaskList(tasks: taskProvider.claimedTasks),
          TaskList(tasks: taskProvider.completedTasks),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isProjectLoading // Disable button while loading
            ? null
            : () {
                if (authProvider.isLoggedIn) {
                  context.go('/task/new');
                } else {
                  context.go('/login');
                }
              },
        child: isProjectLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add),
      ),
    );
  }
}
