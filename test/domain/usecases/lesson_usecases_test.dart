import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tenzin/domain/usecases/lesson_usecases.dart';
import 'package:tenzin/data/repositories/lesson_repository.dart';
import 'package:tenzin/data/models/lesson.dart';

class MockLessonRepository extends Mock implements LessonRepository {}

void main() {
  group('GetAllLessonsUseCase', () {
    late MockLessonRepository mockRepository;
    late GetAllLessonsUseCase useCase;

    setUp(() {
      mockRepository = MockLessonRepository();
      useCase = GetAllLessonsUseCase(mockRepository);
    });

    test('should return list of lessons', () async {
      final expectedLessons = [
        LessonModel(
          id: 'lesson_1',
          title: 'Greeting Lesson',
          sequenceOrder: 1,
          treePath: 'unit_1',
          wordCount: 10,
        ),
        LessonModel(
          id: 'lesson_2',
          title: 'Numbers Lesson',
          sequenceOrder: 2,
          treePath: 'unit_1',
          wordCount: 15,
        ),
      ];

      when(() => mockRepository.getAllLessons(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => (lessons: expectedLessons, failure: null));

      final result = await useCase.call();

      expect(result.lessons.length, 2);
      expect(result.lessons[0].id, 'lesson_1');
      expect(result.lessons[1].id, 'lesson_2');
      expect(result.failure, isNull);
    });

    test('should return empty list when no lessons', () async {
      when(() => mockRepository.getAllLessons(forceRefresh: any(named: 'forceRefresh')))
          .thenAnswer((_) async => (lessons: <LessonModel>[], failure: null));

      final result = await useCase.call();

      expect(result.lessons, isEmpty);
    });
  });

  group('GetLessonByIdUseCase', () {
    late MockLessonRepository mockRepository;
    late GetLessonByIdUseCase useCase;

    setUp(() {
      mockRepository = MockLessonRepository();
      useCase = GetLessonByIdUseCase(mockRepository);
    });

    test('should return lesson by id', () async {
      final expectedLesson = LessonModel(
        id: 'lesson_1',
        title: 'Greeting Lesson',
        sequenceOrder: 1,
        treePath: 'unit_1',
        wordCount: 10,
      );

      when(() => mockRepository.getLessonById(any()))
          .thenAnswer((_) async => (lesson: expectedLesson, failure: null));

      final result = await useCase.call('lesson_1');

      expect(result.lesson?.id, 'lesson_1');
      expect(result.failure, isNull);
    });

    test('should return null for non-existent lesson', () async {
      when(() => mockRepository.getLessonById(any()))
          .thenAnswer((_) async => (lesson: null, failure: null));

      final result = await useCase.call('non_existent');

      expect(result.lesson, isNull);
    });
  });

  group('GetLessonWordsUseCase', () {
    late MockLessonRepository mockRepository;
    late GetLessonWordsUseCase useCase;

    setUp(() {
      mockRepository = MockLessonRepository();
      useCase = GetLessonWordsUseCase(mockRepository);
    });

    test('should return words for lesson', () async {
      final expectedWords = [
        LessonWordModel(
          id: 'word_1',
          lessonId: 'lesson_1',
          wordOrder: 1,
          tibetanScript: 'བཀྲ་ཤིས་བདེ་ལེགས།',
          phonetic: 'tashi delek',
          mongolianTranslation: 'Сайн байна уу',
        ),
        LessonWordModel(
          id: 'word_2',
          lessonId: 'lesson_1',
          wordOrder: 2,
          tibetanScript: 'བཀའ་དྲིན་ཆེ།',
          phonetic: 'ka drin che',
          mongolianTranslation: 'Баярлалаа',
        ),
      ];

      when(() => mockRepository.getLessonWords(any()))
          .thenAnswer((_) async => (words: expectedWords, failure: null));

      final result = await useCase.call('lesson_1');

      expect(result.words.length, 2);
      expect(result.words[0].tibetanScript, 'བཀྲ་ཤིས་བདེ་ལེགས།');
      expect(result.words[1].tibetanScript, 'བཀའ་དྲིན་ཆེ།');
    });

    test('should return empty list for lesson with no words', () async {
      when(() => mockRepository.getLessonWords(any()))
          .thenAnswer((_) async => (words: <LessonWordModel>[], failure: null));

      final result = await useCase.call('empty_lesson');

      expect(result.words, isEmpty);
    });
  });

  group('GetLessonCountUseCase', () {
    late MockLessonRepository mockRepository;
    late GetLessonCountUseCase useCase;

    setUp(() {
      mockRepository = MockLessonRepository();
      useCase = GetLessonCountUseCase(mockRepository);
    });

    test('should return lesson count', () async {
      when(() => mockRepository.getLessonCount())
          .thenAnswer((_) async => 25);

      final result = await useCase.call();

      expect(result, 25);
    });
  });

  group('GetNextLessonUseCase', () {
    late MockLessonRepository mockRepository;
    late GetNextLessonUseCase useCase;

    setUp(() {
      mockRepository = MockLessonRepository();
      useCase = GetNextLessonUseCase(mockRepository);
    });

    test('should return next lesson', () async {
      final nextLesson = LessonModel(
        id: 'lesson_2',
        title: 'Numbers Lesson',
        sequenceOrder: 2,
        treePath: 'unit_1',
        wordCount: 15,
      );

      when(() => mockRepository.getNextLesson(any()))
          .thenAnswer((_) async => nextLesson);

      final result = await useCase.call(1);

      expect(result?.id, 'lesson_2');
      expect(result?.sequenceOrder, 2);
    });

    test('should return null when no next lesson', () async {
      when(() => mockRepository.getNextLesson(any()))
          .thenAnswer((_) async => null);

      final result = await useCase.call(100);

      expect(result, isNull);
    });
  });
}
