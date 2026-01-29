import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/progress.dart';
// Progress DAO - handles lesson progress storage
import '../../../core/utils/logger.dart';

class ProgressDao {
  final DatabaseHelper _dbHelper;

  ProgressDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(ProgressModel progress) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'user_progress');
    return await db.insert(
      'user_progress',
      progress.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ProgressModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'user_progress',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return ProgressModel.fromMap(maps.first);
  }

  Future<ProgressModel?> getByUserAndLesson(String odUserId, String lessonId) async {
    final db = await _db;
    final maps = await db.query(
      'user_progress',
      where: 'user_id = ? AND lesson_id = ?',
      whereArgs: [odUserId, lessonId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return ProgressModel.fromMap(maps.first);
  }

  Future<List<ProgressModel>> getByUser(String odUserId) async {
    final db = await _db;
    final maps = await db.query(
      'user_progress',
      where: 'user_id = ?',
      whereArgs: [odUserId],
    );
    return maps.map((map) => ProgressModel.fromMap(map)).toList();
  }

  Future<int> update(ProgressModel progress) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'user_progress');
    return await db.update(
      'user_progress',
      progress.toMap(),
      where: 'id = ?',
      whereArgs: [progress.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'user_progress');
    return await db.delete(
      'user_progress',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByUser(String odUserId) async {
    final db = await _db;
    return await db.delete(
      'user_progress',
      where: 'user_id = ?',
      whereArgs: [odUserId],
    );
  }

  Future<List<ProgressModel>> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'user_progress',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'last_modified_at ASC',
    );
    return maps.map((map) => ProgressModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await _db;
    await db.update(
      'user_progress',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getCompletedLessonsCount(String odUserId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM user_progress 
      WHERE user_id = ? AND status = 'completed'
    ''', [odUserId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getTotalXpEarned(String odUserId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT SUM(xp_earned) as total FROM user_progress 
      WHERE user_id = ?
    ''', [odUserId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int?> getHighestCompletedSequenceOrder(String odUserId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT MAX(l.sequence_order) as max_order 
      FROM user_progress p
      JOIN lessons l ON p.lesson_id = l.id
      WHERE p.user_id = ? AND p.status = 'completed'
    ''', [odUserId]);
    
    return Sqflite.firstIntValue(result);
  }

  Future<bool> isLessonUnlocked(String odUserId, int sequenceOrder) async {
    if (sequenceOrder == 1) return true; // First lesson always unlocked
    
    final highestCompleted = await getHighestCompletedSequenceOrder(odUserId);
    if (highestCompleted == null) return sequenceOrder == 1;
    
    return sequenceOrder <= highestCompleted + 1;
  }

  Future<ProgressModel?> getLastInProgress(String odUserId) async {
    final db = await _db;
    final maps = await db.query(
      'user_progress',
      where: 'user_id = ? AND status = ?',
      whereArgs: [odUserId, 'inProgress'],
      orderBy: 'last_modified_at DESC',
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return ProgressModel.fromMap(maps.first);
  }
}
