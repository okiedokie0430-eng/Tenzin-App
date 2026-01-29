import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/data/models/lesson.dart';

void main() {
  group('LessonModel', () {
    test('should create LessonModel with required fields', () {
      final lesson = LessonModel(
        id: 'lesson_1',
        title: 'Greeting Lesson',
        sequenceOrder: 1,
        treePath: 'unit_1',
        wordCount: 10,
      );

      expect(lesson.id, 'lesson_1');
      expect(lesson.title, 'Greeting Lesson');
      expect(lesson.sequenceOrder, 1);
      expect(lesson.treePath, 'unit_1');
      expect(lesson.wordCount, 10);
    });

    test('should convert to Map and back', () {
      final lesson = LessonModel(
        id: 'lesson_1',
        title: 'Greeting Lesson',
        description: 'Learn basic greetings',
        type: 'vocabulary',
        sequenceOrder: 1,
        treePath: 'unit_1',
        wordCount: 10,
        version: 1,
      );

      final map = lesson.toMap();
      final fromMap = LessonModel.fromMap(map);

      expect(fromMap.id, lesson.id);
      expect(fromMap.title, lesson.title);
      expect(fromMap.description, lesson.description);
      expect(fromMap.type, lesson.type);
      expect(fromMap.sequenceOrder, lesson.sequenceOrder);
      expect(fromMap.treePath, lesson.treePath);
      expect(fromMap.wordCount, lesson.wordCount);
    });

    test('copyWith should update specified fields only', () {
      final lesson = LessonModel(
        id: 'lesson_1',
        title: 'Greeting Lesson',
        sequenceOrder: 1,
        treePath: 'unit_1',
        wordCount: 10,
      );

      final updatedLesson = lesson.copyWith(
        wordCount: 20,
        sequenceOrder: 2,
      );

      expect(updatedLesson.id, lesson.id);
      expect(updatedLesson.title, lesson.title);
      expect(updatedLesson.wordCount, 20);
      expect(updatedLesson.sequenceOrder, 2);
    });

    test('should have default type of vocabulary', () {
      final lesson = LessonModel(
        id: 'lesson_1',
        title: 'Greeting Lesson',
        sequenceOrder: 1,
        treePath: 'unit_1',
        wordCount: 10,
      );

      expect(lesson.type, 'vocabulary');
    });
  });

  group('LessonWordModel', () {
    test('should create LessonWordModel with required fields', () {
      final word = LessonWordModel(
        id: 'word_1',
        lessonId: 'lesson_1',
        wordOrder: 1,
        tibetanScript: 'བཀྲ་ཤིས་བདེ་ལེགས།',
        phonetic: 'tashi delek',
        mongolianTranslation: 'Сайн байна уу',
      );

      expect(word.id, 'word_1');
      expect(word.lessonId, 'lesson_1');
      expect(word.wordOrder, 1);
      expect(word.tibetanScript, 'བཀྲ་ཤིས་བདེ་ལེགས།');
    });

    test('should convert to Map and back', () {
      final word = LessonWordModel(
        id: 'word_1',
        lessonId: 'lesson_1',
        wordOrder: 1,
        tibetanScript: 'བཀྲ་ཤིས་བདེ་ལེགས།',
        phonetic: 'tashi delek',
        mongolianTranslation: 'Сайн байна уу',
      );

      final map = word.toMap();
      final fromMap = LessonWordModel.fromMap(map);

      expect(fromMap.id, word.id);
      expect(fromMap.lessonId, word.lessonId);
      expect(fromMap.tibetanScript, word.tibetanScript);
      expect(fromMap.phonetic, word.phonetic);
      expect(fromMap.mongolianTranslation, word.mongolianTranslation);
    });
  });
}
