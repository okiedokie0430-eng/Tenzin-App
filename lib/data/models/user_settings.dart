import 'user.dart';

class UserSettingsModel {
  final String userId;
  final bool notificationNewFollower;
  final bool notificationLeaderboardRank;
  final bool notificationMessages;
  final bool notificationAchievements;
  final bool storagePermissionGranted;
  final bool soundEnabled;
  final bool musicEnabled;
  final bool dailyReminderEnabled;
  final String dailyReminderTime; // Format: "HH:mm"
  final String theme; // system, light, dark
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  const UserSettingsModel({
    required this.userId,
    this.notificationNewFollower = true,
    this.notificationLeaderboardRank = true,
    this.notificationMessages = true,
    this.notificationAchievements = true,
    this.storagePermissionGranted = false,
    this.soundEnabled = true,
    this.musicEnabled = true,
    this.dailyReminderEnabled = true,
    this.dailyReminderTime = '09:00',
    this.theme = 'system',
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
  });

  // Convenience getters for UI compatibility
  bool get notificationsEnabled => notificationNewFollower || 
      notificationLeaderboardRank || 
      notificationMessages || 
      notificationAchievements;

  factory UserSettingsModel.initial(String userId) {
    return UserSettingsModel(
      userId: userId,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory UserSettingsModel.fromMap(Map<String, dynamic> map) {
    return UserSettingsModel(
      userId: map['user_id'] as String? ?? '',
      notificationNewFollower: (map['notification_new_follower'] as int? ?? 1) == 1,
      notificationLeaderboardRank: (map['notification_leaderboard_rank'] as int? ?? 1) == 1,
      notificationMessages: (map['notification_messages'] as int? ?? 1) == 1,
      notificationAchievements: (map['notification_achievements'] as int? ?? 1) == 1,
      storagePermissionGranted: (map['storage_permission_granted'] as int? ?? 0) == 1,
      soundEnabled: (map['sound_enabled'] as int? ?? 1) == 1,
      musicEnabled: (map['music_enabled'] as int? ?? 1) == 1,
      dailyReminderEnabled: (map['daily_reminder_enabled'] as int? ?? 1) == 1,
      dailyReminderTime: map['daily_reminder_time'] as String? ?? '09:00',
      theme: map['theme'] as String? ?? 'system',
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (map['sync_status'] as String? ?? 'pending'),
        orElse: () => SyncStatus.pending,
      ),
      lastModifiedAt: map['last_modified_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      version: map['version'] as int? ?? 1,
    );
  }

  get darkModeEnabled => null;

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'notification_new_follower': notificationNewFollower ? 1 : 0,
      'notification_leaderboard_rank': notificationLeaderboardRank ? 1 : 0,
      'notification_messages': notificationMessages ? 1 : 0,
      'notification_achievements': notificationAchievements ? 1 : 0,
      'storage_permission_granted': storagePermissionGranted ? 1 : 0,
      'sound_enabled': soundEnabled ? 1 : 0,
      'music_enabled': musicEnabled ? 1 : 0,
      'daily_reminder_enabled': dailyReminderEnabled ? 1 : 0,
      'daily_reminder_time': dailyReminderTime,
      'theme': theme,
      'sync_status': syncStatus.name,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  UserSettingsModel copyWith({
    String? userId,
    bool? notificationNewFollower,
    bool? notificationLeaderboardRank,
    bool? notificationMessages,
    bool? notificationAchievements,
    bool? storagePermissionGranted,
    bool? soundEnabled,
    bool? musicEnabled,
    bool? dailyReminderEnabled,
    String? dailyReminderTime,
    String? theme,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
  }) {
    return UserSettingsModel(
      userId: userId ?? this.userId,
      notificationNewFollower: notificationNewFollower ?? this.notificationNewFollower,
      notificationLeaderboardRank: notificationLeaderboardRank ?? this.notificationLeaderboardRank,
      notificationMessages: notificationMessages ?? this.notificationMessages,
      notificationAchievements: notificationAchievements ?? this.notificationAchievements,
      storagePermissionGranted: storagePermissionGranted ?? this.storagePermissionGranted,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      musicEnabled: musicEnabled ?? this.musicEnabled,
      dailyReminderEnabled: dailyReminderEnabled ?? this.dailyReminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      theme: theme ?? this.theme,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }
}
