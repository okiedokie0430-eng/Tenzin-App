import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/data/models/progress.dart';
import 'package:tenzin/data/models/user.dart';

void main() {
  group('ProgressModel', () {
    test('should create ProgressModel with required fields', () {
      final progress = ProgressModel(
        id: 'progress_123',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(progress.id, 'progress_123');
      expect(progress.odUserId, 'user_123');
      expect(progress.lessonId, 'lesson_1');
      expect(progress.status, ProgressStatus.notStarted);
    });

    test('should convert to Map and back', () {
      final progress = ProgressModel(
        id: 'progress_123',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        status: ProgressStatus.completed,
        correctAnswers: 8,
        totalQuestions: 10,
        xpEarned: 15,
        heartsRemaining: 4,
        attempts: 1,
        timeSpentSeconds: 120,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final map = progress.toMap();
      final fromMap = ProgressModel.fromMap(map);

      expect(fromMap.id, progress.id);
      expect(fromMap.odUserId, progress.odUserId);
      expect(fromMap.lessonId, progress.lessonId);
      expect(fromMap.status, progress.status);
      expect(fromMap.correctAnswers, progress.correctAnswers);
      expect(fromMap.totalQuestions, progress.totalQuestions);
      expect(fromMap.xpEarned, progress.xpEarned);
    });

    test('copyWith should update specified fields only', () {
      final progress = ProgressModel(
        id: 'progress_123',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        status: ProgressStatus.inProgress,
        correctAnswers: 5,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final updatedProgress = progress.copyWith(
        status: ProgressStatus.completed,
        correctAnswers: 8,
        xpEarned: 15,
      );

      expect(updatedProgress.id, progress.id);
      expect(updatedProgress.odUserId, progress.odUserId);
      expect(updatedProgress.status, ProgressStatus.completed);
      expect(updatedProgress.correctAnswers, 8);
      expect(updatedProgress.xpEarned, 15);
    });

    test('should have default values', () {
      final progress = ProgressModel(
        id: 'progress_123',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(progress.status, ProgressStatus.notStarted);
      expect(progress.correctAnswers, 0);
      expect(progress.totalQuestions, 0);
      expect(progress.xpEarned, 0);
      expect(progress.heartsRemaining, 5);
      expect(progress.attempts, 0);
      expect(progress.timeSpentSeconds, 0);
      expect(progress.syncStatus, SyncStatus.pending);
    });
  });

  group('ProgressStatus', () {
    test('should have all required statuses', () {
      expect(ProgressStatus.values.length, 4);
      expect(ProgressStatus.notStarted.name, 'notStarted');
      expect(ProgressStatus.inProgress.name, 'inProgress');
      expect(ProgressStatus.completed.name, 'completed');
      expect(ProgressStatus.abandoned.name, 'abandoned');
    });
  });
}
