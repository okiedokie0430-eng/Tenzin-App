import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/achievement.dart';
import '../../../core/utils/logger.dart';

class AchievementDao {
  final DatabaseHelper _dbHelper;

  AchievementDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<List<AchievementModel>> getAllAchievements() async {
    final db = await _db;
    final maps = await db.query('achievements');
    return maps.map((map) => AchievementModel.fromMap(map)).toList();
  }

  Future<AchievementModel?> getAchievementById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'achievements',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return AchievementModel.fromMap(maps.first);
  }

  Future<int> insertUserAchievement(UserAchievementModel userAchievement) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'user_achievements');
    return await db.insert(
      'user_achievements',
      userAchievement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<UserAchievementModel>> getUserAchievements(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'user_achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'unlocked_at DESC',
    );
    return maps.map((map) => UserAchievementModel.fromMap(map)).toList();
  }

  Future<UserAchievementModel?> getUserAchievement(
    String userId,
    String achievementId,
  ) async {
    final db = await _db;
    final maps = await db.query(
      'user_achievements',
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [userId, achievementId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return UserAchievementModel.fromMap(maps.first);
  }

  Future<bool> hasAchievement(String userId, String achievementId) async {
    final achievement = await getUserAchievement(userId, achievementId);
    return achievement != null;
  }

  Future<List<AchievementWithStatus>> getAchievementsWithStatus(
    String userId,
  ) async {
    final achievements = await getAllAchievements();
    final userAchievements = await getUserAchievements(userId);
    
    final userAchievementMap = {
      for (final ua in userAchievements) ua.achievementId: ua
    };

    return achievements.map((achievement) {
      return AchievementWithStatus(
        achievement: achievement,
        userAchievement: userAchievementMap[achievement.id],
      );
    }).toList();
  }

  Future<int> getUnlockedCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM user_achievements WHERE user_id = ?
    ''', [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deleteUserAchievements(String userId) async {
    final db = await _db;
    return await db.delete(
      'user_achievements',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<UserAchievementModel>> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'user_achievements',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'last_modified_at ASC',
    );
    return maps.map((map) => UserAchievementModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await _db;
    await db.update(
      'user_achievements',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
