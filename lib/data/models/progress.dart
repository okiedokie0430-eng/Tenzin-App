import 'user.dart';

enum ProgressStatus { notStarted, inProgress, completed, abandoned }

class ProgressModel {
  final String id;
  final String odUserId;
  final String lessonId;
  final ProgressStatus status;
  final int correctAnswers;
  final int totalQuestions;
  final int xpEarned;
  final int heartsRemaining;
  final DateTime? completedAt;
  final int attempts;
  final int timeSpentSeconds;
  final SyncStatus syncStatus;
  final int lastModifiedAt;
  final int version;

  const ProgressModel({
    required this.id,
    required this.odUserId,
    required this.lessonId,
    this.status = ProgressStatus.notStarted,
    this.correctAnswers = 0,
    this.totalQuestions = 0,
    this.xpEarned = 0,
    this.heartsRemaining = 5,
    this.completedAt,
    this.attempts = 0,
    this.timeSpentSeconds = 0,
    this.syncStatus = SyncStatus.pending,
    required this.lastModifiedAt,
    this.version = 1,
  });

  factory ProgressModel.fromMap(Map<String, dynamic> map) {
    return ProgressModel(
      id: map['id'] as String? ?? '',
      odUserId: map['user_id'] as String? ?? '',
      lessonId: map['lesson_id'] as String? ?? '',
      status: ProgressStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String? ?? 'notStarted'),
        orElse: () => ProgressStatus.notStarted,
      ),
      correctAnswers: map['correct_answers'] as int? ?? 0,
      totalQuestions: map['total_questions'] as int? ?? 0,
      xpEarned: map['xp_earned'] as int? ?? 0,
      heartsRemaining: map['hearts_remaining'] as int? ?? 5,
      completedAt: map['completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int)
          : null,
      attempts: map['attempts'] as int? ?? 0,
      timeSpentSeconds: map['time_spent_seconds'] as int? ?? 0,
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
      'user_id': odUserId,
      'lesson_id': lessonId,
      'status': status.name,
      'correct_answers': correctAnswers,
      'total_questions': totalQuestions,
      'xp_earned': xpEarned,
      'hearts_remaining': heartsRemaining,
      'completed_at': completedAt?.millisecondsSinceEpoch,
      'attempts': attempts,
      'time_spent_seconds': timeSpentSeconds,
      'sync_status': syncStatus.name,
      'last_modified_at': lastModifiedAt,
      'version': version,
    };
  }

  ProgressModel copyWith({
    String? id,
    String? odUserId,
    String? lessonId,
    ProgressStatus? status,
    int? correctAnswers,
    int? totalQuestions,
    int? xpEarned,
    int? heartsRemaining,
    DateTime? completedAt,
    int? attempts,
    int? timeSpentSeconds,
    SyncStatus? syncStatus,
    int? lastModifiedAt,
    int? version,
  }) {
    return ProgressModel(
      id: id ?? this.id,
      odUserId: odUserId ?? this.odUserId,
      lessonId: lessonId ?? this.lessonId,
      status: status ?? this.status,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      xpEarned: xpEarned ?? this.xpEarned,
      heartsRemaining: heartsRemaining ?? this.heartsRemaining,
      completedAt: completedAt ?? this.completedAt,
      attempts: attempts ?? this.attempts,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      syncStatus: syncStatus ?? this.syncStatus,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      version: version ?? this.version,
    );
  }

  bool get isCompleted => status == ProgressStatus.completed;
  bool get isInProgress => status == ProgressStatus.inProgress;
  bool get isAbandoned => status == ProgressStatus.abandoned;
  
  double get accuracy => totalQuestions > 0 
      ? correctAnswers / totalQuestions 
      : 0.0;
}
