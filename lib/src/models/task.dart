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
  final String type;
  final TaskStatus status;
  final String publisherName;
  final DateTime publishedAt;
  final DateTime? editedAt;
  final DateTime? canceledAt;
  final String? claimantName;
  final DateTime? claimedAt;
  final DateTime? completedAt;
  final DateTime? statusChangedAt; // 用於認領、完成、放棄、取消的狀態變更時間

  Task({
    required this.id,
    required this.name,
    required this.content,
    required this.address,
    required this.type,
    required this.status,
    required this.publisherName,
    required this.publishedAt,
    this.editedAt,
    this.canceledAt,
    this.claimantName,
    this.claimedAt,
    this.completedAt,
    this.statusChangedAt,
  });
}
