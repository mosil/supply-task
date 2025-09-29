import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_type.dart';

class TaskTypeProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'taskTypes';

  List<TaskType> _taskTypes = [];
  bool _isLoading = true;
  bool _isInitialized = false;

  List<TaskType> get taskTypes => _taskTypes;
  bool get isLoading => _isLoading;

  TaskTypeProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore.collection(_collectionName).get();

      if (snapshot.docs.isEmpty) {
        // Collection is empty, add default types
        await _addDefaultTypes();
      } 

      // Fetch all types again after potential initialization
      await _fetchTaskTypes();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TaskTypeProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchTaskTypes() async {
    final snapshot = await _firestore.collection(_collectionName).get();
    _taskTypes = snapshot.docs
        .map((doc) => TaskType.fromFirestore(doc, null))
        .toList();
    // Sort by name for consistent display
    _taskTypes.sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> _addDefaultTypes() async {
    final batch = _firestore.batch();
    const defaultTypes = ['勞力任務', '補給品需求', '發放資源'];

    for (var typeName in defaultTypes) {
      final docRef = _firestore.collection(_collectionName).doc();
      batch.set(docRef, {'name': typeName});
    }
    await batch.commit();
  }

  Future<String> getOrCreateTaskTypeId(String typeName) async {
    final trimmedName = typeName.trim();
    if (trimmedName.isEmpty) {
      throw Exception('Task type name cannot be empty.');
    }

    // Check if it already exists (case-sensitive)
    final existingType = _taskTypes.where((type) => type.name == trimmedName);

    if (existingType.isNotEmpty) {
      return existingType.first.id;
    } else {
      // Add new type to Firestore
      final docRef = await _firestore.collection(_collectionName).add({'name': trimmedName});
      // Add to local cache and notify listeners
      final newType = TaskType(id: docRef.id, name: trimmedName);
      _taskTypes.add(newType);
      _taskTypes.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
      return docRef.id;
    }
  }

  String getTaskTypeNameById(String id) {
    try {
      return _taskTypes.firstWhere((type) => type.id == id).name;
    } catch (e) {
      return '[未知類型]';
    }
  }
}
