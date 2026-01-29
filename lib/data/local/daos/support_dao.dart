import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/support_message.dart';
import '../../../core/utils/logger.dart';

class SupportDao {
  final DatabaseHelper _dbHelper;

  SupportDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(SupportMessageModel message) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'support_messages');
    return await db.insert(
      'support_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<SupportMessageModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'support_messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return SupportMessageModel.fromMap(maps.first);
  }

  Future<List<SupportMessageModel>> getByUser(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'support_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => SupportMessageModel.fromMap(map)).toList();
  }

  Future<int> update(SupportMessageModel message) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'support_messages');
    return await db.update(
      'support_messages',
      message.toMap(),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'support_messages');
    return await db.delete(
      'support_messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteByUser(String userId) async {
    final db = await _db;
    return await db.delete(
      'support_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<List<SupportMessageModel>> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'support_messages',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return maps.map((map) => SupportMessageModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id, String appwriteMessageId) async {
    final db = await _db;
    await db.update(
      'support_messages',
      {
        'sync_status': 'synced',
        'appwrite_message_id': appwriteMessageId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateWithResponse(
    String id,
    String adminResponse,
    DateTime respondedAt,
  ) async {
    final db = await _db;
    await db.update(
      'support_messages',
      {
        'admin_response': adminResponse,
        'responded_at': respondedAt.millisecondsSinceEpoch,
        'status': 'responded',
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
