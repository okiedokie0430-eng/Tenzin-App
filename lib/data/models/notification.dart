import 'user.dart';

enum NotificationType {
  newFollower,
  leaderboardRank,
  messagePending,
  achievementUnlocked,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedUserId;
  final DateTime createdAt;
  final DateTime? readAt;
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedUserId,
    required this.createdAt,
    this.readAt,
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'newFollower'),
        orElse: () => NotificationType.newFollower,
      ),
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      relatedUserId: map['related_user_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      readAt: map['read_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['read_at'] as int)
          : null,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (map['sync_status'] as String? ?? 'pending'),
        orElse: () => SyncStatus.pending,
      ),
      lastModifiedAt: map['last_modified_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'message': message,
      'related_user_id': relatedUserId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'read_at': readAt?.millisecondsSinceEpoch,
      'sync_status': syncStatus.name,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    String? relatedUserId,
    DateTime? createdAt,
    DateTime? readAt,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }

  bool get isRead => readAt != null;
}
