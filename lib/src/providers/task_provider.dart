import 'package:flutter/foundation.dart';
import '../data/mock_data.dart';
import '../models/task.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];

  TaskProvider() {
    // Initialize with mock data
    _tasks = mockTasks;
  }

  List<Task> get allTasks => _tasks;

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Task> get publishedTasks => _tasks
      .where((task) =>
          task.status == TaskStatus.published || task.status == TaskStatus.abandoned)
      .toList();

  List<Task> get claimedTasks =>
      _tasks.where((task) => task.status == TaskStatus.claimed).toList();

  List<Task> get completedTasks =>
      _tasks.where((task) => task.status == TaskStatus.completed).toList();

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }
}
