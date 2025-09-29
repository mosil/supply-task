import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus {
  draft,      // 草稿
  published,  // 發布
  claimed,    // 認領
  completed,  // 已完成
  abandoned,  // 放棄
  canceled,   // 取消
}

extension TaskStatusExtension on TaskStatus {
  String get displayName {
    switch (this) {
      case TaskStatus.draft:
        return '草稿';
      case TaskStatus.published:
        return '發布';
      case TaskStatus.claimed:
        return '認領';
      case TaskStatus.completed:
        return '已完成';
      case TaskStatus.abandoned:
        return '放棄';
      case TaskStatus.canceled:
        return '取消';
      default:
        return '';
    }
  }
}

class Task {
  final String id;
  final String name;
  final String content;
  final String address;
  final String typeId;
  final TaskStatus status;
  final String publisherId;
  final String contactInfo;
  final String contactPhone;
  final DateTime publishedAt;
  final DateTime? editedAt;
  final DateTime? canceledAt;
  final String? claimantId;
  final DateTime? claimedAt;
  final DateTime? completedAt;
  final DateTime? statusChangedAt;

  Task({
    required this.id,
    required this.name,
    required this.content,
    required this.address,
    required this.typeId,
    required this.status,
    required this.publisherId,
    required this.contactInfo,
    required this.contactPhone,
    required this.publishedAt,
    this.editedAt,
    this.canceledAt,
    this.claimantId,
    this.claimedAt,
    this.completedAt,
    this.statusChangedAt,
  });

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) {
    final data = snapshot.data()!;
    return Task(
      id: snapshot.id,
      name: data['name'] ?? '',
      content: data['content'] ?? '',
      address: data['address'] ?? '',
      typeId: data['typeId'] ?? '',
      status: TaskStatus.values.firstWhere((e) => e.toString() == 'TaskStatus.${data['status']}', orElse: () => TaskStatus.draft),
      publisherId: data['publisherId'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
      contactPhone: data['contactPhone'] ?? '',
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      canceledAt: (data['canceledAt'] as Timestamp?)?.toDate(),
      claimantId: data['claimantId'],
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      statusChangedAt: (data['statusChangedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'content': content,
      'address': address,
      'typeId': typeId,
      'status': status.name,
      'publisherId': publisherId,
      'contactInfo': contactInfo,
      'contactPhone': contactPhone,
      'publishedAt': Timestamp.fromDate(publishedAt),
      if (editedAt != null) 'editedAt': Timestamp.fromDate(editedAt!),
      if (canceledAt != null) 'canceledAt': Timestamp.fromDate(canceledAt!),
      if (claimantId != null) 'claimantId': claimantId,
      if (claimedAt != null) 'claimedAt': Timestamp.fromDate(claimedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (statusChangedAt != null) 'statusChangedAt': Timestamp.fromDate(statusChangedAt!),
    };
  }
}
