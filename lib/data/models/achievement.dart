import 'user.dart';

class AchievementModel {
  final String id;
  final String name;
  final String description;
  final String? iconAsset;
  final String type; // streak, lessons, xp, perfect, social, time
  final String unlockCriteria; // JSON string
  final int version;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    this.iconAsset,
    this.type = 'lessons',
    required this.unlockCriteria,
    this.version = 1,
  });

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconAsset: map['icon_asset'] as String?,
      type: map['type'] as String? ?? 'lessons',
      unlockCriteria: map['unlock_criteria'] as String? ?? '{}',
      version: map['version'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_asset': iconAsset,
      'type': type,
      'unlock_criteria': unlockCriteria,
      'version': version,
    };
  }
}

class UserAchievementModel {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  const UserAchievementModel({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
  });

  factory UserAchievementModel.fromMap(Map<String, dynamic> map) {
    return UserAchievementModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      achievementId: map['achievement_id'] as String? ?? '',
      unlockedAt: DateTime.fromMillisecondsSinceEpoch(map['unlocked_at'] as int? ?? 0),
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
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.millisecondsSinceEpoch,
      'sync_status': syncStatus.name,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  UserAchievementModel copyWith({
    String? id,
    String? userId,
    String? achievementId,
    DateTime? unlockedAt,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
  }) {
    return UserAchievementModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }
}

class AchievementWithStatus {
  final AchievementModel achievement;
  final UserAchievementModel? userAchievement;

  const AchievementWithStatus({
    required this.achievement,
    this.userAchievement,
  });

  bool get isUnlocked => userAchievement != null;
  DateTime? get unlockedAt => userAchievement?.unlockedAt;
  
  // Convenience getters to access achievement properties
  String get id => achievement.id;
  String get title => achievement.name;
  String get description => achievement.description;
  String? get iconUrl => achievement.iconAsset;
  String get type => achievement.type;
}
