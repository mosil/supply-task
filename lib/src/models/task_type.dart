import 'package:cloud_firestore/cloud_firestore.dart';

class TaskType {
  final String id;
  final String name;

  TaskType({required this.id, required this.name});

  factory TaskType.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data()!;
    return TaskType(
      id: snapshot.id,
      name: data['name'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
    };
  }
}
