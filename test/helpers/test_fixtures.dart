import 'package:tenzin/data/models/user.dart';
import 'package:tenzin/data/models/lesson.dart';
import 'package:tenzin/data/models/heart_state.dart';
import 'package:tenzin/data/models/achievement.dart';

/// Тест өгөгдлийн fixture-үүд / Test data fixtures
class TestFixtures {
  /// Хэрэглэгч / Users
  static UserModel get testUser => UserModel(
        id: 'test_user_1',
        email: 'test@example.com',
        displayName: 'Test User',
        username: 'testuser',
        totalXp: 4500, // level = 4500/1000 + 1 = 5
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

  static UserModel get newUser => UserModel(
        id: 'new_user',
        email: 'new@example.com',
        displayName: 'New User',
        totalXp: 0, // level = 1
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

  /// Хичээл / Lessons
  static LessonModel get testLesson => LessonModel(
        id: 'lesson_1',
        title: 'Test Lesson 1',
        sequenceOrder: 1,
        treePath: '/unit_1/lesson_1',
        wordCount: 10,
      );

  static List<LessonModel> get lessonsForUnit1 => [
        testLesson,
        LessonModel(
          id: 'lesson_2',
          title: 'Test Lesson 2',
          sequenceOrder: 2,
          treePath: '/unit_1/lesson_2',
          wordCount: 12,
        ),
        LessonModel(
          id: 'lesson_3',
          title: 'Test Lesson 3',
          sequenceOrder: 3,
          treePath: '/unit_1/lesson_3',
          wordCount: 15,
        ),
      ];

  /// Зүрх / Hearts
  static HeartStateModel get fullHearts =>
      HeartStateModel.initial('test_user_1');

  static HeartStateModel get lowHearts => HeartStateModel(
        userId: 'test_user_1',
        currentHearts: 2,
        lastHeartLossAt: DateTime.now().subtract(const Duration(minutes: 10)),
        lastRegenerationAt:
            DateTime.now().subtract(const Duration(minutes: 10)),
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

  static HeartStateModel get emptyHearts => HeartStateModel(
        userId: 'test_user_1',
        currentHearts: 0,
        lastHeartLossAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastRegenerationAt: DateTime.now().subtract(const Duration(minutes: 5)),
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

  /// Амжилт / Achievements
  static AchievementModel get testAchievement => AchievementModel(
        id: 'ach_1',
        name: 'Эхлэгч',
        description: 'Анхны хичээлээ дуусгасан',
        iconAsset: 'assets/icons/star.png',
        unlockCriteria: '{"type": "lessons_completed", "count": 1}',
      );

  static List<AchievementModel> get allAchievements => [
        testAchievement,
        AchievementModel(
          id: 'ach_2',
          name: '7 өдрийн streak',
          description: '7 өдөр дараалан суралцсан',
          iconAsset: 'assets/icons/fire.png',
          unlockCriteria: '{"type": "streak", "days": 7}',
        ),
        AchievementModel(
          id: 'ach_3',
          name: 'XP мастер',
          description: '1000 XP цуглуулсан',
          iconAsset: 'assets/icons/trophy.png',
          unlockCriteria: '{"type": "total_xp", "amount": 1000}',
        ),
      ];
}
