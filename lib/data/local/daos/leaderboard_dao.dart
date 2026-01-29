import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/leaderboard.dart';
import '../../../core/utils/date_utils.dart' as utils;
import '../../../core/utils/logger.dart';

class LeaderboardDao {
  final DatabaseHelper _dbHelper;

  LeaderboardDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(LeaderboardEntryModel entry) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'leaderboard');
    return await db.insert(
      'leaderboard',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<LeaderboardEntryModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'leaderboard',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return LeaderboardEntryModel.fromMap(maps.first);
  }

  Future<LeaderboardEntryModel?> getByUserAndWeek(
    String userId,
    DateTime weekStart,
  ) async {
    final db = await _db;
    final weekStartTimestamp = weekStart.millisecondsSinceEpoch;
    
    final maps = await db.query(
      'leaderboard',
      where: 'user_id = ? AND week_start_date = ?',
      whereArgs: [userId, weekStartTimestamp],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return LeaderboardEntryModel.fromMap(maps.first);
  }

  Future<LeaderboardEntryModel?> getCurrentWeekEntry(String userId) async {
    final weekStart = utils.AppDateUtils.getWeekStart(DateTime.now());
    return await getByUserAndWeek(userId, weekStart);
  }

  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard({
    DateTime? weekStart,
    int limit = 100,
  }) async {
    final db = await _db;
    final weekStartDate = weekStart ?? utils.AppDateUtils.getWeekStart(DateTime.now());
    final weekStartTimestamp = weekStartDate.millisecondsSinceEpoch;
    
    final maps = await db.rawQuery('''
      SELECT l.*, u.display_name
      FROM leaderboard l
      JOIN user_profile u ON l.user_id = u.id
      WHERE l.week_start_date = ?
      ORDER BY l.weekly_xp DESC, l.last_modified_at ASC
      LIMIT ?
    ''', [weekStartTimestamp, limit]);

    return maps.map((map) => LeaderboardEntryModel.fromMap(map)).toList();
  }

  Future<int?> getUserRank(String userId, {DateTime? weekStart}) async {
    final db = await _db;
    final weekStartDate = weekStart ?? utils.AppDateUtils.getWeekStart(DateTime.now());
    final weekStartTimestamp = weekStartDate.millisecondsSinceEpoch;
    
    final result = await db.rawQuery('''
      SELECT COUNT(*) + 1 as rank
      FROM leaderboard
      WHERE week_start_date = ? 
        AND (weekly_xp > (SELECT weekly_xp FROM leaderboard WHERE user_id = ? AND week_start_date = ?)
             OR (weekly_xp = (SELECT weekly_xp FROM leaderboard WHERE user_id = ? AND week_start_date = ?)
                 AND last_modified_at < (SELECT last_modified_at FROM leaderboard WHERE user_id = ? AND week_start_date = ?)))
    ''', [weekStartTimestamp, userId, weekStartTimestamp, userId, weekStartTimestamp, userId, weekStartTimestamp]);
    
    return Sqflite.firstIntValue(result);
  }

  Future<int> update(LeaderboardEntryModel entry) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'leaderboard');
    return await db.update(
      'leaderboard',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> updateWeeklyXp(String userId, int xpToAdd) async {
    final db = await _db;
    final weekStart = utils.AppDateUtils.getWeekStart(DateTime.now());
    final weekStartTimestamp = weekStart.millisecondsSinceEpoch;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE leaderboard 
      SET weekly_xp = weekly_xp + ?,
          sync_status = 'pending',
          last_modified_at = ?
      WHERE user_id = ? AND week_start_date = ?
    ''', [xpToAdd, now, userId, weekStartTimestamp]);
  }

  Future<int> delete(String id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'leaderboard');
    return await db.delete(
      'leaderboard',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByUser(String userId) async {
    final db = await _db;
    return await db.delete(
      'leaderboard',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteOldEntries(int weeksToKeep) async {
    final db = await _db;
    final cutoffDate = DateTime.now().subtract(Duration(days: weeksToKeep * 7));
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;
    
    await db.delete(
      'leaderboard',
      where: 'week_start_date < ?',
      whereArgs: [cutoffTimestamp],
    );
  }

  Future<List<LeaderboardEntryModel>> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'leaderboard',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'last_modified_at ASC',
    );
    return maps.map((map) => LeaderboardEntryModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await _db;
    await db.update(
      'leaderboard',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
