import 'package:sqflite/sqflite.dart';

import '../local/database_helper.dart';
import '../models/achievement.dart';
import '../../core/utils/logger.dart';

/// Service to load pre-defined achievements into the local database.
class AchievementDataLoader {
  final DatabaseHelper _dbHelper;

  AchievementDataLoader(this._dbHelper);

  /// Pre-defined achievements based on ARCHITECTURE.md
  static const List<Map<String, dynamic>> _achievements = [
    {
      'id': 'ach_first_lesson',
      'name': 'Нэгдүгээр хичээл',
      'description': 'Анхны хичээлийг дүүргэлээ',
      'icon_asset': 'assets/icons/achievements/first_lesson.png',
      'type': 'lesson',
      'unlock_criteria': '{"type": "lesson_count", "value": 1}',
    },
    {
      'id': 'ach_5_lessons',
      'name': '5 Хичээлийн мастер',
      'description': '5 хичээл дүүргэлээ',
      'icon_asset': 'assets/icons/achievements/5_lessons.png',
      'type': 'lesson',
      'unlock_criteria': '{"type": "lesson_count", "value": 5}',
    },
    {
      'id': 'ach_10_lessons',
      'name': '10 Хичээлийн мастер',
      'description': '10 хичээл дүүргэлээ',
      'icon_asset': 'assets/icons/achievements/10_lessons.png',
      'type': 'lesson',
      'unlock_criteria': '{"type": "lesson_count", "value": 10}',
    },
    {
      'id': 'ach_25_lessons',
      'name': '25 Хичээлийн мастер',
      'description': '25 хичээл дүүргэлээ',
      'icon_asset': 'assets/icons/achievements/25_lessons.png',
      'type': 'lesson',
      'unlock_criteria': '{"type": "lesson_count", "value": 25}',
    },
    {
      'id': 'ach_all_lessons',
      'name': 'Бүх хичээлийн мастер',
      'description': 'Бүх хичээлийг дүүргэлээ',
      'icon_asset': 'assets/icons/achievements/all_lessons.png',
      'type': 'lesson',
      'unlock_criteria': '{"type": "lesson_count", "value": 54}',
    },
    {
      'id': 'ach_perfect_heart',
      'name': 'Төгс зүрх',
      'description': '5 зүрхтэйгээр хичээл дүүргэлээ',
      'icon_asset': 'assets/icons/achievements/perfect_heart.png',
      'type': 'performance',
      'unlock_criteria': '{"type": "perfect_lesson", "value": 1}',
    },
    {
      'id': 'ach_3_day_streak',
      'name': '3 Өдрийн стрийк',
      'description': '3 өдөр дараалал сурлаа',
      'icon_asset': 'assets/icons/achievements/3_streak.png',
      'type': 'streak',
      'unlock_criteria': '{"type": "streak", "value": 3}',
    },
    {
      'id': 'ach_7_day_streak',
      'name': '7 Өдрийн стрийк',
      'description': '7 өдөр дараалал сурлаа',
      'icon_asset': 'assets/icons/achievements/7_streak.png',
      'type': 'streak',
      'unlock_criteria': '{"type": "streak", "value": 7}',
    },
    {
      'id': 'ach_14_day_streak',
      'name': '14 Өдрийн стрийк',
      'description': '14 өдөр дараалал сурлаа',
      'icon_asset': 'assets/icons/achievements/14_streak.png',
      'type': 'streak',
      'unlock_criteria': '{"type": "streak", "value": 14}',
    },
    {
      'id': 'ach_30_day_streak',
      'name': '30 Өдрийн стрийк',
      'description': '30 өдөр дараалал сурлаа',
      'icon_asset': 'assets/icons/achievements/30_streak.png',
      'type': 'streak',
      'unlock_criteria': '{"type": "streak", "value": 30}',
    },
    {
      'id': 'ach_100_xp',
      'name': '100 XP',
      'description': '100 туршлагын оноо цуглууллаа',
      'icon_asset': 'assets/icons/achievements/100_xp.png',
      'type': 'xp',
      'unlock_criteria': '{"type": "total_xp", "value": 100}',
    },
    {
      'id': 'ach_500_xp',
      'name': '500 XP',
      'description': '500 туршлагын оноо цуглууллаа',
      'icon_asset': 'assets/icons/achievements/500_xp.png',
      'type': 'xp',
      'unlock_criteria': '{"type": "total_xp", "value": 500}',
    },
    {
      'id': 'ach_1000_xp',
      'name': '1000 XP',
      'description': '1000 туршлагын оноо цуглууллаа',
      'icon_asset': 'assets/icons/achievements/1000_xp.png',
      'type': 'xp',
      'unlock_criteria': '{"type": "total_xp", "value": 1000}',
    },
    {
      'id': 'ach_leaderboard_1',
      'name': 'Лидербордын аврага',
      'description': 'Лидербордод #1 байр эзэллээ',
      'icon_asset': 'assets/icons/achievements/leaderboard_1.png',
      'type': 'social',
      'unlock_criteria': '{"type": "leaderboard_rank", "value": 1}',
    },
    {
      'id': 'ach_leaderboard_10',
      'name': 'Топ 10',
      'description': 'Лидербордод топ 10-д орлоо',
      'icon_asset': 'assets/icons/achievements/leaderboard_10.png',
      'type': 'social',
      'unlock_criteria': '{"type": "leaderboard_rank", "value": 10}',
    },
    {
      'id': 'ach_first_friend',
      'name': 'Анхны найз',
      'description': 'Анхны дагагчтай боллоо',
      'icon_asset': 'assets/icons/achievements/first_friend.png',
      'type': 'social',
      'unlock_criteria': '{"type": "followers", "value": 1}',
    },
    {
      'id': 'ach_social_butterfly',
      'name': 'Нийгмийн эрвээхэй',
      'description': '10 дагагчтай боллоо',
      'icon_asset': 'assets/icons/achievements/social_butterfly.png',
      'type': 'social',
      'unlock_criteria': '{"type": "followers", "value": 10}',
    },
    {
      'id': 'ach_word_master',
      'name': 'Үг судлаач',
      'description': '50 үг сурлаа',
      'icon_asset': 'assets/icons/achievements/word_master.png',
      'type': 'vocabulary',
      'unlock_criteria': '{"type": "words_learned", "value": 50}',
    },
  ];

  /// Load achievements into the database if not already present.
  Future<void> loadAchievements() async {
    try {
      final db = await _dbHelper.database;
      
      // Check if achievements already exist
      final existingCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM achievements'
      );
      final count = existingCount.first['count'] as int;
      
      if (count >= _achievements.length) {
        AppLogger.logInfo(
          'AchievementDataLoader',
          'Achievements already loaded ($count achievements)',
        );
        return;
      }

      AppLogger.logInfo(
        'AchievementDataLoader',
        'Loading ${_achievements.length} achievements...',
      );

      // Insert or update achievements
      for (final achievementData in _achievements) {
        final achievement = AchievementModel(
          id: achievementData['id'] as String,
          name: achievementData['name'] as String,
          description: achievementData['description'] as String,
          iconAsset: achievementData['icon_asset'] as String?,
          type: achievementData['type'] as String,
          unlockCriteria: achievementData['unlock_criteria'] as String,
        );

        await db.insert(
          'achievements',
          achievement.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      AppLogger.logInfo(
        'AchievementDataLoader',
        'Loaded ${_achievements.length} achievements',
      );
    } catch (e) {
      AppLogger.logError('AchievementDataLoader', 'loadAchievements', e);
      rethrow;
    }
  }
}
