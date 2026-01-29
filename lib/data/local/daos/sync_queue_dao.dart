import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/sync_queue.dart';
import '../../../core/utils/logger.dart';

class SyncQueueDao {
  final DatabaseHelper _dbHelper;

  SyncQueueDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(SyncQueueModel item) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'sync_queue');
    return await db.insert(
      'sync_queue',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SyncQueueModel?> getById(int id) async {
    final db = await _db;
    final maps = await db.query(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return SyncQueueModel.fromMap(maps.first);
  }

  Future<List<SyncQueueModel>> getPendingItems({int limit = 50}) async {
    final db = await _db;
    final maps = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
      limit: limit,
    );
    
    return maps.map((m) => SyncQueueModel.fromMap(m)).toList();
  }

  Future<List<SyncQueueModel>> getFailedItems({int maxRetries = 3}) async {
    final db = await _db;
    final maps = await db.query(
      'sync_queue',
      where: 'status = ? AND retry_count < ?',
      whereArgs: ['failed', maxRetries],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((m) => SyncQueueModel.fromMap(m)).toList();
  }

  Future<List<SyncQueueModel>> getItemsForRetry({
    int maxRetries = 3,
    Duration minDelay = const Duration(minutes: 5),
  }) async {
    final db = await _db;
    final cutoffTime = DateTime.now().subtract(minDelay).millisecondsSinceEpoch;
    
    final maps = await db.query(
      'sync_queue',
      where: 'status = ? AND retry_count < ? AND (last_attempt IS NULL OR last_attempt < ?)',
      whereArgs: ['failed', maxRetries, cutoffTime],
      orderBy: 'created_at ASC',
    );
    
    return maps.map((m) => SyncQueueModel.fromMap(m)).toList();
  }

  Future<int> update(SyncQueueModel item) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'sync_queue');
    return await db.update(
      'sync_queue',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> markAsProcessing(int id) async {
    final db = await _db;
    await db.update(
      'sync_queue',
      {
        'status': 'processing',
        'last_attempt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsCompleted(int id) async {
    final db = await _db;
    await db.update(
      'sync_queue',
      {'status': 'completed'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> markAsFailed(int id, String? errorMessage) async {
    final db = await _db;
    await db.rawUpdate('''
      UPDATE sync_queue
      SET status = 'failed',
          retry_count = retry_count + 1,
          error_message = ?,
          last_attempt = ?
      WHERE id = ?
    ''', [errorMessage, DateTime.now().millisecondsSinceEpoch, id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'sync_queue');
    return await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCompleted() async {
    final db = await _db;
    AppLogger.logDatabase('DELETE_COMPLETED', 'sync_queue');
    return await db.delete(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['completed'],
    );
  }

  Future<int> deleteOldCompleted({int daysOld = 7}) async {
    final db = await _db;
    final cutoffTime = DateTime.now()
        .subtract(Duration(days: daysOld))
        .millisecondsSinceEpoch;
    
    return await db.delete(
      'sync_queue',
      where: 'status = ? AND created_at < ?',
      whereArgs: ['completed', cutoffTime],
    );
  }

  Future<int> getPendingCount() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue
      WHERE status IN ('pending', 'failed')
    ''');
    
    return result.first['count'] as int? ?? 0;
  }

  Future<int> getCountByTable(String tableName) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM sync_queue
      WHERE table_name = ? AND status IN ('pending', 'failed')
    ''', [tableName]);
    
    return result.first['count'] as int? ?? 0;
  }

  Future<void> clearAll() async {
    final db = await _db;
    await db.delete('sync_queue');
  }

  Future<void> addToQueue({
    required String tableName,
    required String recordId,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tableName: tableName,
      recordId: recordId,
      operation: operation,
      payload: jsonEncode(payload),
      retryCount: 0,
      createdAt: DateTime.now(),
    );
    await insert(item);
  }
}
