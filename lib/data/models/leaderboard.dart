import 'user.dart';

class LeaderboardEntryModel {
  final String id;
  final String odUserId;
  final DateTime weekStartDate;
  final int weeklyXp;
  final int rank;
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  // Join fields (not stored in DB)
  final String? displayName;
  final String? avatarUrl;
  final int level;
  final int totalXp;
  final int streak;

  const LeaderboardEntryModel({
    required this.id,
    required this.odUserId,
    required this.weekStartDate,
    this.weeklyXp = 0,
    this.rank = 0,
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
    this.displayName,
    this.avatarUrl,
    this.level = 1,
    this.totalXp = 0,
    this.streak = 0,
  });

  // Getter for userId (alias for consistency)
  String get userId => odUserId;

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntryModel(
      id: map['id'] as String? ?? '',
      odUserId: map['user_id'] as String? ?? '',
      weekStartDate: DateTime.fromMillisecondsSinceEpoch(map['week_start_date'] as int? ?? 0),
      weeklyXp: map['weekly_xp'] as int? ?? 0,
      rank: map['rank'] as int? ?? 0,
      syncStatus: SyncStatus.values.firstWhere(
        (e) => e.name == (map['sync_status'] as String? ?? 'pending'),
        orElse: () => SyncStatus.pending,
      ),
      lastModifiedAt: map['last_modified_at'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      version: map['version'] as int? ?? 1,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      level: map['level'] as int? ?? 1,
      totalXp: map['total_xp'] as int? ?? 0,
      streak: map['streak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': odUserId,
      'week_start_date': weekStartDate.millisecondsSinceEpoch,
      'weekly_xp': weeklyXp,
      'rank': rank,
      'sync_status': syncStatus.name,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  LeaderboardEntryModel copyWith({
    String? id,
    String? odUserId,
    DateTime? weekStartDate,
    int? weeklyXp,
    int? rank,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
    String? displayName,
    String? avatarUrl,
    int? level,
    int? totalXp,
    int? streak,
  }) {
    return LeaderboardEntryModel(
      id: id ?? this.id,
      odUserId: odUserId ?? this.odUserId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      rank: rank ?? this.rank,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      streak: streak ?? this.streak,
    );
  }
}
