import 'user.dart';

class FollowModel {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  const FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
  });

  factory FollowModel.fromMap(Map<String, dynamic> map) {
    // Handle sync_status mapping including pendingDelete -> pending_delete
    final syncStatusStr = map['sync_status'] as String? ?? 'pending';
    SyncStatus syncStatus;
    switch (syncStatusStr) {
      case 'pending':
        syncStatus = SyncStatus.pending;
        break;
      case 'synced':
        syncStatus = SyncStatus.synced;
        break;
      case 'pending_delete':
      case 'pendingDelete':
        syncStatus = SyncStatus.pendingDelete;
        break;
      case 'failed':
        syncStatus = SyncStatus.failed;
        break;
      default:
        syncStatus = SyncStatus.pending;
    }

    return FollowModel(
      id: map['id'] as String? ?? '',
      followerId: map['follower_id'] as String? ?? '',
      followingId: map['following_id'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int? ?? 0),
      syncStatus: syncStatus,
      lastModifiedAt: map['last_modified_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    // Store pendingDelete as pending_delete in database
    String syncStatusStr;
    switch (syncStatus) {
      case SyncStatus.pending:
        syncStatusStr = 'pending';
        break;
      case SyncStatus.synced:
        syncStatusStr = 'synced';
        break;
      case SyncStatus.pendingDelete:
        syncStatusStr = 'pending_delete';
        break;
      case SyncStatus.failed:
        syncStatusStr = 'failed';
        break;
    }

    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.millisecondsSinceEpoch,
      'sync_status': syncStatusStr,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  FollowModel copyWith({
    String? id,
    String? followerId,
    String? followingId,
    DateTime? createdAt,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
  }) {
    return FollowModel(
      id: id ?? this.id,
      followerId: followerId ?? this.followerId,
      followingId: followingId ?? this.followingId,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }

  @override
  String toString() {
    return 'FollowModel(id: $id, follower: $followerId, following: $followingId, status: $syncStatus)';
  }
}
