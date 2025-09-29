import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:supply_task/src/models/task.dart';
import 'package:supply_task/src/models/user_profile.dart';

class TaskProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _projectId;

  List<Task> _tasks = [];
  StreamSubscription<QuerySnapshot>? _tasksSubscription;

  List<Task> get allTasks => _tasks;

  void updateProject(String? newProjectId) {
    if (newProjectId != null && newProjectId != _projectId) {
      _projectId = newProjectId;
      _listenToTasks();
    }
  }

  void _listenToTasks() {
    // Cancel any existing subscription before creating a new one
    _tasksSubscription?.cancel();

    if (_projectId == null) return;

    final collectionRef = _firestore
        .collection(_projectId!)
        .withConverter<Task>(fromFirestore: Task.fromFirestore, toFirestore: (Task task, _) => task.toFirestore());

    _tasksSubscription = collectionRef.snapshots().listen(
      (snapshot) {
        _tasks = snapshot.docs.map((doc) => doc.data()).toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error listening to tasks: $error');
      },
    );
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Task> get publishedTasks =>
      _tasks.where((task) => task.status == TaskStatus.published || task.status == TaskStatus.abandoned).toList();

  List<Task> get claimedTasks => _tasks.where((task) => task.status == TaskStatus.claimed).toList();

  List<Task> get completedTasks =>
      _tasks.where((task) => task.status == TaskStatus.completed).toList();

  List<Task> getPublishedTasksByUser(String userId) =>
      _tasks.where((task) => task.publisherId == userId).toList();

  List<Task> getClaimedTasksByUser(String userId) =>
      _tasks.where((task) => task.claimantId == userId).toList();

  Future<DocumentReference> addTask(Task task) {
    if (_projectId == null) throw Exception('Project ID not set');
    return _firestore.collection(_projectId!).add(task.toFirestore());
  }

  Future<void> updateTask(Task task) {
    if (_projectId == null) throw Exception('Project ID not set');
    return _firestore.collection(_projectId!).doc(task.id).update(task.toFirestore());
  }

  Future<void> deleteTask(String taskId) {
    if (_projectId == null) throw Exception('Project ID not set');
    return _firestore.collection(_projectId!).doc(taskId).delete();
  }

  Future<void> claimTask(String taskId, UserProfile user) {
    if (_projectId == null) throw Exception('Project ID not set');
    final now = Timestamp.now();
    return _firestore.collection(_projectId!).doc(taskId).update({
      'status': TaskStatus.claimed.name,
      'claimantId': user.uid,
      'claimedAt': now,
      'statusChangedAt': now,
    });
  }

  Future<void> abandonTask(String taskId) {
    if (_projectId == null) throw Exception('Project ID not set');
    return _firestore.collection(_projectId!).doc(taskId).update({
      'status': TaskStatus.published.name,
      'statusChangedAt': Timestamp.now(),
      'claimantId': FieldValue.delete(),
      'claimedAt': FieldValue.delete(),
    });
  }

  Future<void> cancelTask(String taskId) {
    if (_projectId == null) throw Exception('Project ID not set');
    final now = Timestamp.now();
    return _firestore.collection(_projectId!).doc(taskId).update({
      'status': TaskStatus.canceled.name,
      'canceledAt': now,
      'statusChangedAt': now,
    });
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }
}
