import 'user.dart';

class HeartStateModel {
  final String userId;
  final int currentHearts;
  final DateTime? lastHeartLossAt;
  final DateTime? lastRegenerationAt;
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  static const int maxHearts = 5;
  static const int regenerationMinutes = 20;

  const HeartStateModel({
    required this.userId,
    this.currentHearts = maxHearts,
    this.lastHeartLossAt,
    this.lastRegenerationAt,
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
  });

  factory HeartStateModel.initial(String userId) {
    return HeartStateModel(
      userId: userId,
      currentHearts: maxHearts,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory HeartStateModel.fromMap(Map<String, dynamic> map) {
    return HeartStateModel(
      userId: map['user_id'] as String? ?? '',
      currentHearts: map['current_hearts'] as int? ?? maxHearts,
      lastHeartLossAt: map['last_heart_loss_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_heart_loss_at'] as int)
          : null,
      lastRegenerationAt: map['last_regeneration_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_regeneration_at'] as int)
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
      'user_id': userId,
      'current_hearts': currentHearts,
      'last_heart_loss_at': lastHeartLossAt?.millisecondsSinceEpoch,
      'last_regeneration_at': lastRegenerationAt?.millisecondsSinceEpoch,
      'sync_status': syncStatus.name,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  HeartStateModel copyWith({
    String? userId,
    int? currentHearts,
    DateTime? lastHeartLossAt,
    DateTime? lastRegenerationAt,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
  }) {
    return HeartStateModel(
      userId: userId ?? this.userId,
      currentHearts: currentHearts ?? this.currentHearts,
      lastHeartLossAt: lastHeartLossAt ?? this.lastHeartLossAt,
      lastRegenerationAt: lastRegenerationAt ?? this.lastRegenerationAt,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }

  bool get isFull => currentHearts >= maxHearts;
  bool get isEmpty => currentHearts <= 0;
  bool get isRegenerating => !isFull && !isEmpty;

  int get heartsToRegenerate {
    if (isFull) return 0;
    
    // Use last heart loss as the starting point for regeneration
    final regenerationStartTime = lastHeartLossAt ?? lastRegenerationAt ?? DateTime.now();
    final now = DateTime.now();
    final elapsed = now.difference(regenerationStartTime);
    final heartsToAdd = elapsed.inMinutes ~/ regenerationMinutes;
    
    return (currentHearts + heartsToAdd).clamp(0, maxHearts) - currentHearts;
  }

  Duration get timeUntilNextHeart {
    if (isFull) return Duration.zero;
    
    // Calculate time until next heart from last heart loss or last regeneration
    final regenerationTime = lastHeartLossAt ?? lastRegenerationAt ?? DateTime.now();
    final now = DateTime.now();
    final elapsed = now.difference(regenerationTime);
    const regenerationDuration = Duration(minutes: regenerationMinutes);
    
    // Calculate cycles completed
    final cyclesCompleted = elapsed.inMilliseconds ~/ regenerationDuration.inMilliseconds;
    final nextRegenerationTime = regenerationTime.add(regenerationDuration * (cyclesCompleted + 1));
    
    return nextRegenerationTime.difference(now);
  }

  Duration get timeUntilFullHearts {
    if (isFull) return Duration.zero;
    
    final heartsNeeded = maxHearts - currentHearts;
    final timeUntilNext = timeUntilNextHeart;
    final additionalTime = Duration(minutes: (heartsNeeded - 1) * regenerationMinutes);
    
    return timeUntilNext + additionalTime;
  }

  HeartStateModel loseHeart() {
    if (isEmpty) return this;
    
    final now = DateTime.now();
    return copyWith(
      currentHearts: currentHearts - 1,
      lastHeartLossAt: now,
      lastRegenerationAt: lastRegenerationAt ?? now,
      syncStatus: SyncStatus.pending,
      lastModifiedAt: now.millisecondsSinceEpoch,
    );
  }

  HeartStateModel regenerate() {
    final toRegenerate = heartsToRegenerate;
    if (toRegenerate <= 0) return this;
    
    final now = DateTime.now();
    final newHeartCount = (currentHearts + toRegenerate).clamp(0, maxHearts);
    
    // Keep lastHeartLossAt as the reference point, only update lastRegenerationAt
    return copyWith(
      currentHearts: newHeartCount,
      lastRegenerationAt: now,
      syncStatus: SyncStatus.pending,
      lastModifiedAt: now.millisecondsSinceEpoch,
    );
  }

  HeartStateModel refillHearts() {
    final now = DateTime.now();
    return copyWith(
      currentHearts: maxHearts,
      lastRegenerationAt: now,
      syncStatus: SyncStatus.pending,
      lastModifiedAt: now.millisecondsSinceEpoch,
    );
  }
}
