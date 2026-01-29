import '../../data/models/progress.dart';
import '../../data/repositories/progress_repository.dart';
import '../../core/error/failures.dart';

class GetUserProgressUseCase {
  final ProgressRepository _repository;

  GetUserProgressUseCase(this._repository);

  Future<({List<ProgressModel> progress, Failure? failure})> call(
    String userId,
  ) {
    return _repository.getUserProgress(userId);
  }
}

class GetLessonProgressUseCase {
  final ProgressRepository _repository;

  GetLessonProgressUseCase(this._repository);

  Future<({ProgressModel? progress, Failure? failure})> call(
    String userId,
    String lessonId,
  ) {
    return _repository.getLessonProgress(userId, lessonId);
  }
}

class SaveProgressUseCase {
  final ProgressRepository _repository;

  SaveProgressUseCase(this._repository);

  Future<({ProgressModel? progress, Failure? failure})> call(
    ProgressModel progress,
  ) {
    return _repository.saveProgress(progress);
  }
}

class CompleteLessonUseCase {
  final ProgressRepository _repository;

  CompleteLessonUseCase(this._repository);

  Future<({ProgressModel? progress, Failure? failure})> call({
    required String userId,
    required String lessonId,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
    required int heartsRemaining,
    int timeSpentSeconds = 0,
  }) {
    return _repository.completeLesson(
      userId: userId,
      lessonId: lessonId,
      correctAnswers: correctAnswers,
      totalQuestions: totalQuestions,
      xpEarned: xpEarned,
      heartsRemaining: heartsRemaining,
      timeSpentSeconds: timeSpentSeconds,
    );
  }
}

class StartLessonUseCase {
  final ProgressRepository _repository;

  StartLessonUseCase(this._repository);

  Future<({ProgressModel? progress, Failure? failure})> call(
    String userId,
    String lessonId,
  ) {
    return _repository.startLesson(userId, lessonId);
  }
}

class GetCompletedLessonCountUseCase {
  final ProgressRepository _repository;

  GetCompletedLessonCountUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getCompletedLessonCount(userId);
  }
}

class GetTotalXPUseCase {
  final ProgressRepository _repository;

  GetTotalXPUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getTotalXP(userId);
  }
}

class SyncProgressUseCase {
  final ProgressRepository _repository;

  SyncProgressUseCase(this._repository);

  Future<void> call(String userId, DateTime lastSyncTime) {
    return _repository.syncProgress(userId, lastSyncTime);
  }
}

class SyncPendingProgressUseCase {
  final ProgressRepository _repository;

  SyncPendingProgressUseCase(this._repository);

  Future<void> call() {
    return _repository.syncPendingProgress();
  }
}
