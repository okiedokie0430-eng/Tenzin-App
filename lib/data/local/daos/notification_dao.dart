import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/notification.dart';
import '../../../core/utils/logger.dart';

class NotificationDao {
  final DatabaseHelper _dbHelper;

  NotificationDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(NotificationModel notification) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'notifications');
    return await db.insert(
      'notifications',
      notification.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<NotificationModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return NotificationModel.fromMap(maps.first);
  }

  Future<List<NotificationModel>> getByUser(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await _db;
    final maps = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<List<NotificationModel>> getUnreadByUser(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'notifications',
      where: 'user_id = ? AND read_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM notifications 
      WHERE user_id = ? AND read_at IS NULL
    ''', [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> update(NotificationModel notification) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'notifications');
    return await db.update(
      'notifications',
      notification.toMap(),
      where: 'id = ?',
      whereArgs: [notification.id],
    );
  }

  Future<void> markAsRead(String notificationId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'notifications',
      {
        'read_at': now,
        'sync_status': 'pending',
        'last_modified_at': now,
      },
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  Future<void> markAllAsRead(String userId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'notifications',
      {
        'read_at': now,
        'sync_status': 'pending',
        'last_modified_at': now,
      },
      where: 'user_id = ? AND read_at IS NULL',
      whereArgs: [userId],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'notifications');
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByUser(String userId) async {
    final db = await _db;
    return await db.delete(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<NotificationModel>> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'notifications',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'last_modified_at ASC',
    );
    return maps.map((map) => NotificationModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await _db;
    await db.update(
      'notifications',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
