import 'dart:convert';

enum SyncStatus { pending, synced, failed, pendingDelete }

class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final List<String> authProviders;
  final int totalXp;
  final int weeklyXp;
  final int currentStreakDays;
  final int longestStreakDays;
  final int followerCount;
  final int followingCount;
  final int lessonsCompleted;
  final DateTime? lastLessonDate;
  final DateTime? lastSyncAt;
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.authProviders = const ['email'],
    this.totalXp = 0,
    this.weeklyXp = 0,
    this.currentStreakDays = 0,
    this.longestStreakDays = 0,
    this.followerCount = 0,
    this.followingCount = 0,
    this.lessonsCompleted = 0,
    this.lastLessonDate,
    this.lastSyncAt,
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
  });

  // Convenience getters
  int get streak => currentStreakDays;
  int get level => (totalXp / 1000).floor() + 1; // Level = XP / 1000 + 1

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      username: map['username'] as String?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      authProviders: map['auth_providers'] != null
          ? List<String>.from(json.decode(map['auth_providers'] as String))
          : ['email'],
      totalXp: map['total_xp'] as int? ?? 0,
      weeklyXp: map['weekly_xp'] as int? ?? 0,
      currentStreakDays: map['current_streak_days'] as int? ?? 0,
      longestStreakDays: map['longest_streak_days'] as int? ?? 0,
      followerCount: map['follower_count'] as int? ?? 0,
      followingCount: map['following_count'] as int? ?? 0,
      lessonsCompleted: map['lessons_completed'] as int? ?? 0,
      lastLessonDate: map['last_lesson_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_lesson_date'] as int)
          : null,
      lastSyncAt: map['last_sync_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_sync_at'] as int)
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
      'email': email,
      'display_name': displayName,
      'username': username,
      'bio': bio,
      'avatar_url': avatarUrl,
      'auth_providers': json.encode(authProviders),
      'total_xp': totalXp,
      'weekly_xp': weeklyXp,
      'current_streak_days': currentStreakDays,
      'longest_streak_days': longestStreakDays,
      'follower_count': followerCount,
      'following_count': followingCount,
      'lessons_completed': lessonsCompleted,
      'last_lesson_date': lastLessonDate?.millisecondsSinceEpoch,
      'last_sync_at': lastSyncAt?.millisecondsSinceEpoch,
      'sync_status': syncStatus.name,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    List<String>? authProviders,
    int? totalXp,
    int? weeklyXp,
    int? currentStreakDays,
    int? longestStreakDays,
    int? followerCount,
    int? followingCount,
    int? lessonsCompleted,
    DateTime? lastLessonDate,
    DateTime? lastSyncAt,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      authProviders: authProviders ?? this.authProviders,
      totalXp: totalXp ?? this.totalXp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      lastLessonDate: lastLessonDate ?? this.lastLessonDate,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }
}
