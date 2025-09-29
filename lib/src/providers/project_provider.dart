import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class ProjectProvider with ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  String? _currentProjectId;
  String? _currentProjectName;
  bool _isLoading = true;

  String? get currentProjectId => _currentProjectId;
  String? get currentProjectName => _currentProjectName;
  bool get isLoading => _isLoading;

  ProjectProvider() {
    _fetchProjects();
  }

  Future<void> _fetchProjects() async {
    try {
      final ref = _database.ref('projects');
      final snapshot = await ref.get();

      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        if (data.isNotEmpty) {
          _currentProjectId = data.keys.first;
          _currentProjectName = data.values.first;
        } else {
          debugPrint('[ProjectProvider] Warning: The "/projects" node exists in Realtime Database, but it is empty. No project can be loaded.');
        }
      } else {
        debugPrint('[ProjectProvider] Error: The "/projects" node was not found in Realtime Database. Please ensure it has been created in the Firebase console as per the README.');
      }
    } catch (e) {
      debugPrint('[ProjectProvider] Exception fetching projects: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
