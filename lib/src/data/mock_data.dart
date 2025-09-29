import '../models/task.dart';
import '../models/user_profile.dart';

final List<Task> mockTasks = [
  Task(
    id: 'task-001',
    name: '物資集中站需要分類志工',
    content: '大量救援物資湧入，急需人手協助分類、打包，以便快速送達災民手中。',
    address: '花蓮縣壽豐鄉中山路一段1號',
    typeId: 'type-labor',
    status: TaskStatus.published,
    publisherId: 'user-uid-001',
    contactInfo: 'LINE ID: davidwang',
    contactPhone: '0912-345-678',
    publishedAt: DateTime(2025, 9, 30, 10, 0),
  ),
  Task(
    id: 'task-002',
    name: '急需瓶裝水 100 箱',
    content: '臨時避難所目前缺乏乾淨飲用水，希望善心人士能捐贈。',
    address: '花蓮縣豐濱鄉豐濱村1鄰3號',
    typeId: 'type-supplies',
    status: TaskStatus.claimed,
    publisherId: 'user-uid-003',
    contactInfo: '',
    contactPhone: '0922-333-444',
    publishedAt: DateTime(2025, 9, 30, 11, 30),
    claimantId: 'user-uid-002',
    claimedAt: DateTime(2025, 9, 30, 14, 0),
    statusChangedAt: DateTime(2025, 9, 30, 14, 0),
  ),
  Task(
    id: 'task-003',
    name: '發放熱食便當',
    content: '預計於中午12點在村活動中心發放熱食便當給受災居民。',
    address: '花蓮縣光復鄉大安村2鄰5號',
    typeId: 'type-distribution',
    status: TaskStatus.completed,
    publisherId: 'user-uid-004',
    contactInfo: '請洽村長',
    contactPhone: '03-888-8888',
    publishedAt: DateTime(2025, 9, 29, 18, 0),
    claimantId: 'user-uid-001',
    claimedAt: DateTime(2025, 9, 30, 9, 0),
    completedAt: DateTime(2025, 9, 30, 13, 0),
    statusChangedAt: DateTime(2025, 9, 30, 13, 0),
  ),
];

final UserProfile mockUser1 = UserProfile(
  uid: 'user-uid-001',
  email: 'ming@example.com',
  displayName: '王大明',
  contactInfo: 'LINE ID: davidwang',
  phoneNumber: '0912-345-678',
);

final UserProfile mockUser2 = UserProfile(
  uid: 'user-uid-002',
  email: 'lee@example.com',
  displayName: '李四',
  contactInfo: '',
  phoneNumber: '0987-654-321',
);
