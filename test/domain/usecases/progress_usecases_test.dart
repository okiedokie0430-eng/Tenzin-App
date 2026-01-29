import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tenzin/domain/usecases/progress_usecases.dart';
import 'package:tenzin/data/repositories/progress_repository.dart';
import 'package:tenzin/data/models/progress.dart';

class MockProgressRepository extends Mock implements ProgressRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ProgressModel(
      id: 'fallback',
      odUserId: 'fallback_user',
      lessonId: 'fallback_lesson',
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  });

  group('GetUserProgressUseCase', () {
    late MockProgressRepository mockRepository;
    late GetUserProgressUseCase useCase;

    setUp(() {
      mockRepository = MockProgressRepository();
      useCase = GetUserProgressUseCase(mockRepository);
    });

    test('should return user progress list', () async {
      final expectedProgress = [
        ProgressModel(
          id: 'progress_1',
          odUserId: 'user_123',
          lessonId: 'lesson_1',
          status: ProgressStatus.completed,
          correctAnswers: 8,
          totalQuestions: 10,
          xpEarned: 15,
          lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
        ),
        ProgressModel(
          id: 'progress_2',
          odUserId: 'user_123',
          lessonId: 'lesson_2',
          status: ProgressStatus.inProgress,
          correctAnswers: 3,
          totalQuestions: 10,
          lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      when(() => mockRepository.getUserProgress(any()))
          .thenAnswer((_) async => (progress: expectedProgress, failure: null));

      final result = await useCase.call('user_123');

      expect(result.progress.length, 2);
      expect(result.progress[0].odUserId, 'user_123');
      expect(result.failure, isNull);
    });

    test('should return empty list for new user', () async {
      when(() => mockRepository.getUserProgress(any()))
          .thenAnswer((_) async => (progress: <ProgressModel>[], failure: null));

      final result = await useCase.call('new_user');

      expect(result.progress, isEmpty);
    });
  });

  group('GetLessonProgressUseCase', () {
    late MockProgressRepository mockRepository;
    late GetLessonProgressUseCase useCase;

    setUp(() {
      mockRepository = MockProgressRepository();
      useCase = GetLessonProgressUseCase(mockRepository);
    });

    test('should return progress for specific lesson', () async {
      final expectedProgress = ProgressModel(
        id: 'progress_1',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        status: ProgressStatus.completed,
        correctAnswers: 8,
        totalQuestions: 10,
        xpEarned: 15,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.getLessonProgress(any(), any()))
          .thenAnswer((_) async => (progress: expectedProgress, failure: null));

      final result = await useCase.call('user_123', 'lesson_1');

      expect(result.progress?.lessonId, 'lesson_1');
      expect(result.progress?.status, ProgressStatus.completed);
    });

    test('should return null for non-started lesson', () async {
      when(() => mockRepository.getLessonProgress(any(), any()))
          .thenAnswer((_) async => (progress: null, failure: null));

      final result = await useCase.call('user_123', 'new_lesson');

      expect(result.progress, isNull);
    });
  });

  group('SaveProgressUseCase', () {
    late MockProgressRepository mockRepository;
    late SaveProgressUseCase useCase;

    setUp(() {
      mockRepository = MockProgressRepository();
      useCase = SaveProgressUseCase(mockRepository);
    });

    test('should save progress', () async {
      final progress = ProgressModel(
        id: 'progress_1',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        status: ProgressStatus.inProgress,
        correctAnswers: 5,
        totalQuestions: 10,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.saveProgress(any()))
          .thenAnswer((_) async => (progress: progress, failure: null));

      final result = await useCase.call(progress);

      expect(result.progress, isNotNull);
      expect(result.failure, isNull);
    });
  });

  group('CompleteLessonUseCase', () {
    late MockProgressRepository mockRepository;
    late CompleteLessonUseCase useCase;

    setUp(() {
      mockRepository = MockProgressRepository();
      useCase = CompleteLessonUseCase(mockRepository);
    });

    test('should complete lesson and return updated progress', () async {
      final expectedProgress = ProgressModel(
        id: 'progress_1',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        status: ProgressStatus.completed,
        correctAnswers: 8,
        totalQuestions: 10,
        xpEarned: 15,
        completedAt: DateTime.now(),
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.completeLesson(
            userId: any(named: 'userId'),
            lessonId: any(named: 'lessonId'),
            correctAnswers: any(named: 'correctAnswers'),
            totalQuestions: any(named: 'totalQuestions'),
            xpEarned: any(named: 'xpEarned'),
            heartsRemaining: any(named: 'heartsRemaining'),
            timeSpentSeconds: any(named: 'timeSpentSeconds'),
          )).thenAnswer((_) async => (progress: expectedProgress, failure: null));

      final result = await useCase.call(
        userId: 'user_123',
        lessonId: 'lesson_1',
        correctAnswers: 8,
        totalQuestions: 10,
        xpEarned: 15,
        heartsRemaining: 4,
        timeSpentSeconds: 120,
      );

      expect(result.progress?.status, ProgressStatus.completed);
      expect(result.progress?.xpEarned, 15);
    });
  });

  group('StartLessonUseCase', () {
    late MockProgressRepository mockRepository;
    late StartLessonUseCase useCase;

    setUp(() {
      mockRepository = MockProgressRepository();
      useCase = StartLessonUseCase(mockRepository);
    });

    test('should start lesson and create progress entry', () async {
      final expectedProgress = ProgressModel(
        id: 'progress_new',
        odUserId: 'user_123',
        lessonId: 'lesson_1',
        status: ProgressStatus.inProgress,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.startLesson(any(), any()))
          .thenAnswer((_) async => (progress: expectedProgress, failure: null));

      final result = await useCase.call('user_123', 'lesson_1');

      expect(result.progress?.status, ProgressStatus.inProgress);
      expect(result.progress?.lessonId, 'lesson_1');
    });
  });
}
