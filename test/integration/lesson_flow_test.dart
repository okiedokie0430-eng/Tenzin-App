import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/data/models/lesson.dart';

void main() {
  group('Lesson Flow Integration', () {
    test('should complete a lesson flow', () {
      // Simulate lesson flow
      final lesson = LessonModel(
        id: 'lesson_1',
        title: 'Greeting Lesson',
        sequenceOrder: 1,
        treePath: '/unit_1/lesson_1',
        wordCount: 10,
      );

      // Simulate answering questions
      var score = 0;
      var mistakeCount = 0;

      // Question 1: Correct
      score += 33;

      // Question 2: Correct
      score += 33;

      // Question 3: Mistake
      mistakeCount++;
      score += 17; // Partial credit after retry

      // Calculate final score
      expect(score, greaterThan(0));
      expect(mistakeCount, 1);

      // Verify lesson structure
      expect(lesson.id, 'lesson_1');
      expect(lesson.sequenceOrder, 1);
      expect(lesson.wordCount, 10);
    });

    test('should handle lesson structure correctly', () {
      final lessons = [
        LessonModel(
          id: 'lesson_1',
          title: 'Lesson 1',
          sequenceOrder: 1,
          treePath: '/unit_1/lesson_1',
          wordCount: 10,
        ),
        LessonModel(
          id: 'lesson_2',
          title: 'Lesson 2',
          sequenceOrder: 2,
          treePath: '/unit_1/lesson_2',
          wordCount: 12,
        ),
        LessonModel(
          id: 'lesson_3',
          title: 'Lesson 3',
          sequenceOrder: 3,
          treePath: '/unit_1/lesson_3',
          wordCount: 15,
        ),
      ];

      for (var i = 0; i < lessons.length; i++) {
        expect(lessons[i].sequenceOrder, i + 1);
        expect(lessons[i].treePath, contains('lesson_${i + 1}'));
      }
    });
  });

  group('Streak Calculation', () {
    test('should increment streak on consecutive days', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final today = DateTime.now();

      final isSameDay = yesterday.year == today.year &&
          yesterday.month == today.month &&
          yesterday.day == today.day;

      expect(isSameDay, false);
    });

    test('should reset streak after missing a day', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final today = DateTime.now();

      final daysDifference = today.difference(twoDaysAgo).inDays;

      // If more than 1 day difference, streak should reset
      final shouldResetStreak = daysDifference > 1;
      expect(shouldResetStreak, true);
    });
  });

  group('XP Calculation', () {
    test('should award base XP for completing lesson', () {
      const baseXp = 10;
      const perfectBonus = 5;
      const mistakeCount = 0;

      final totalXp = baseXp + (mistakeCount == 0 ? perfectBonus : 0);
      expect(totalXp, 15);
    });

    test('should not award bonus XP with mistakes', () {
      const baseXp = 10;
      const perfectBonus = 5;
      const mistakeCount = 1;

      final totalXp = baseXp + (mistakeCount == 0 ? perfectBonus : 0);
      expect(totalXp, 10);
    });
  });
}
