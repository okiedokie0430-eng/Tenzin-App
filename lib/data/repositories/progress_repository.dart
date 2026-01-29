import '../models/progress.dart';
import '../models/user.dart';
import '../local/daos/progress_dao.dart';
import '../local/daos/lesson_dao.dart';
import '../remote/progress_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class ProgressRepository {
  final ProgressRemote _progressRemote;
  final ProgressDao _progressDao;
  final LessonDao _lessonDao;
  final NetworkInfo _networkInfo;

  ProgressRepository(
    this._progressRemote,
    this._progressDao,
    this._lessonDao,
    this._networkInfo,
  );

  Future<({List<ProgressModel> progress, Failure? failure})> getUserProgress(
    String userId,
  ) async {
    try {
      // PRIORITY: Local database is the primary source
      // Appwrite is only for backup/restore on new device or reinstall
      final localProgress = await _progressDao.getByUser(userId);

      // If local has data, use it directly (no remote fetch to avoid overwrite)
      if (localProgress.isNotEmpty) {
        // Background sync TO remote (upload local changes) - don't wait
        _syncLocalToRemote(userId, localProgress);
        return (progress: localProgress, failure: null);
      }

      // Only fetch from remote if local is empty (new device/reinstall scenario)
      if (await _networkInfo.isConnected) {
        AppLogger.logInfo('ProgressRepository',
            'Restoring progress from Appwrite (local empty)');
        final remoteProgress = await _progressRemote.getUserProgress(userId);

        // Save remote progress to local DB for future use
        for (final progress in remoteProgress) {
          await _progressDao.insert(
            progress.copyWith(syncStatus: SyncStatus.synced),
          );
        }

        return (progress: remoteProgress, failure: null);
      }

      return (progress: localProgress, failure: null);
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'getUserProgress', e);
      final localProgress = await _progressDao.getByUser(userId);
      return (
        progress: localProgress,
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  // Background sync local progress to remote (backup)
  Future<void> _syncLocalToRemote(
      String userId, List<ProgressModel> localProgress) async {
    if (!await _networkInfo.isConnected) return;

    try {
      for (final progress in localProgress) {
        if (progress.syncStatus == SyncStatus.pending) {
          await _progressRemote.upsertProgress(progress);
          await _progressDao
              .insert(progress.copyWith(syncStatus: SyncStatus.synced));
        }
      }
    } catch (e) {
      // Don't throw - this is a background operation
      AppLogger.logError('ProgressRepository', '_syncLocalToRemote', e);
    }
  }

  Future<({ProgressModel? progress, Failure? failure})> getLessonProgress(
    String userId,
    String lessonId,
  ) async {
    try {
      var progress = await _progressDao.getByUserAndLesson(userId, lessonId);

      if (progress == null && await _networkInfo.isConnected) {
        progress = await _progressRemote.getProgress(userId, lessonId);
        if (progress != null) {
          await _progressDao.insert(
            progress.copyWith(syncStatus: SyncStatus.synced),
          );
        }
      }

      return (progress: progress, failure: null);
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'getLessonProgress', e);
      return (progress: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({ProgressModel? progress, Failure? failure})> saveProgress(
    ProgressModel progress,
  ) async {
    try {
      // Save locally first
      final localProgress = progress.copyWith(syncStatus: SyncStatus.pending);
      await _progressDao.insert(localProgress);

      if (await _networkInfo.isConnected) {
        final remoteProgress = await _progressRemote.upsertProgress(progress);
        final syncedProgress = remoteProgress.copyWith(
          syncStatus: SyncStatus.synced,
        );
        await _progressDao.insert(syncedProgress);
        return (progress: syncedProgress, failure: null);
      }

      return (progress: localProgress, failure: null);
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'saveProgress', e);
      return (progress: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({ProgressModel? progress, Failure? failure})> completeLesson({
    required String userId,
    required String lessonId,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
    required int heartsRemaining,
    required int timeSpentSeconds,
  }) async {
    try {
      final existingResult = await getLessonProgress(userId, lessonId);
      final existing = existingResult.progress;

      final now = DateTime.now();
      final progress = ProgressModel(
        id: existing?.id ?? '${userId}_$lessonId',
        odUserId: userId,
        lessonId: lessonId,
        status: ProgressStatus.completed,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        xpEarned: (existing?.xpEarned ?? 0) + xpEarned,
        heartsRemaining: heartsRemaining,
        completedAt: now,
        attempts: (existing?.attempts ?? 0) + 1,
        timeSpentSeconds: (existing?.timeSpentSeconds ?? 0) + timeSpentSeconds,
        syncStatus: SyncStatus.pending,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      final result = await saveProgress(progress);

      // Mark all previous lessons as completed if they aren't already
      if (result.progress != null) {
        await _markPreviousLessonsCompleted(userId, lessonId);
      }

      return result;
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'completeLesson', e);
      return (progress: null, failure: Failure.unknown(e.toString()));
    }
  }

  /// Marks all lessons with lower sequenceOrder as completed
  Future<void> _markPreviousLessonsCompleted(
      String userId, String completedLessonId) async {
    try {
      // Get the completed lesson's sequence order
      final completedLesson = await _lessonDao.getById(completedLessonId);
      if (completedLesson == null) return;

      // Get all lessons with lower sequence order
      final allLessons = await _lessonDao.getAll();
      final previousLessons = allLessons
          .where(
              (lesson) => lesson.sequenceOrder < completedLesson.sequenceOrder)
          .toList();

      // Mark each previous lesson as completed if not already
      for (final lesson in previousLessons) {
        final existingProgress = await getLessonProgress(userId, lesson.id);
        if (existingProgress.progress?.status != ProgressStatus.completed) {
          final now = DateTime.now();
          final progress = ProgressModel(
            id: '${userId}_${lesson.id}',
            odUserId: userId,
            lessonId: lesson.id,
            status: ProgressStatus.completed,
            correctAnswers: 0,
            totalQuestions: 0,
            xpEarned: 0,
            heartsRemaining: 5,
            completedAt: now,
            attempts: 1,
            timeSpentSeconds: 0,
            syncStatus: SyncStatus.pending,
            lastModifiedAt: now.millisecondsSinceEpoch,
          );
          await saveProgress(progress);
        }
      }
    } catch (e) {
      AppLogger.logError(
          'ProgressRepository', '_markPreviousLessonsCompleted', e);
      // Don't throw - this is a secondary operation
    }
  }

  Future<({ProgressModel? progress, Failure? failure})> startLesson(
    String userId,
    String lessonId,
  ) async {
    try {
      final existingResult = await getLessonProgress(userId, lessonId);
      final existing = existingResult.progress;

      if (existing != null) {
        // Already started or completed
        return (progress: existing, failure: null);
      }

      final now = DateTime.now();
      final progress = ProgressModel(
        id: '${userId}_$lessonId',
        odUserId: userId,
        lessonId: lessonId,
        status: ProgressStatus.inProgress,
        lastModifiedAt: now.millisecondsSinceEpoch,
        syncStatus: SyncStatus.pending,
      );

      return await saveProgress(progress);
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'startLesson', e);
      return (progress: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<int> getCompletedLessonCount(String userId) async {
    try {
      final progress = await _progressDao.getByUser(userId);
      return progress.where((p) => p.status == ProgressStatus.completed).length;
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'getCompletedLessonCount', e);
      return 0;
    }
  }

  Future<int> getTotalXP(String userId) async {
    try {
      final progress = await _progressDao.getByUser(userId);
      int total = 0;
      for (final p in progress) {
        total += p.xpEarned;
      }
      return total;
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'getTotalXP', e);
      return 0;
    }
  }

  Future<void> syncPendingProgress() async {
    try {
      if (!await _networkInfo.isConnected) return;

      final pendingProgress = await _progressDao.getPendingSync();

      for (final progress in pendingProgress) {
        try {
          await _progressRemote.upsertProgress(progress);
          await _progressDao.update(
            progress.copyWith(syncStatus: SyncStatus.synced),
          );
        } catch (e) {
          AppLogger.logError('ProgressRepository', 'syncPendingProgress', e);
        }
      }
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'syncPendingProgress', e);
    }
  }

  Future<void> syncProgress(String userId, DateTime lastSyncTime) async {
    try {
      if (!await _networkInfo.isConnected) return;

      final updatedProgress = await _progressRemote.getProgressUpdatedAfter(
        userId,
        lastSyncTime,
      );

      for (final progress in updatedProgress) {
        final local = await _progressDao.getById(progress.id);
        if (local == null || progress.lastModifiedAt > local.lastModifiedAt) {
          await _progressDao.insert(
            progress.copyWith(syncStatus: SyncStatus.synced),
          );
        }
      }
    } catch (e) {
      AppLogger.logError('ProgressRepository', 'syncProgress', e);
    }
  }
}
