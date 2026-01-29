import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/heart_state.dart';
import '../../../core/utils/logger.dart';

class HeartDao {
  final DatabaseHelper _dbHelper;

  HeartDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(HeartStateModel heartState) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'heart_state');
    return await db.insert(
      'heart_state',
      heartState.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<HeartStateModel?> getByUserId(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'heart_state',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return HeartStateModel.fromMap(maps.first);
  }

  Future<HeartStateModel> getOrCreate(String userId) async {
    var heartState = await getByUserId(userId);
    if (heartState == null) {
      heartState = HeartStateModel.initial(userId);
      await insert(heartState);
    }
    return heartState;
  }

  Future<int> update(HeartStateModel heartState) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'heart_state');
    return await db.update(
      'heart_state',
      heartState.toMap(),
      where: 'user_id = ?',
      whereArgs: [heartState.userId],
    );
  }

  Future<int> delete(String userId) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'heart_state');
    return await db.delete(
      'heart_state',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<HeartStateModel?> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'heart_state',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return HeartStateModel.fromMap(maps.first);
  }

  Future<void> markAsSynced(String userId) async {
    final db = await _db;
    await db.update(
      'heart_state',
      {'sync_status': 'synced'},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> decrementHearts(String userId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE heart_state 
      SET current_hearts = MAX(0, current_hearts - 1),
          last_heart_loss_at = ?,
          last_regeneration_at = COALESCE(last_regeneration_at, ?),
          sync_status = 'pending',
          last_modified_at = ?
      WHERE user_id = ?
    ''', [now, now, now, userId]);
  }

  Future<void> regenerateHearts(String userId, int heartsToAdd) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE heart_state 
      SET current_hearts = MIN(5, current_hearts + ?),
          last_regeneration_at = ?,
          sync_status = 'pending',
          last_modified_at = ?
      WHERE user_id = ?
    ''', [heartsToAdd, now, now, userId]);
  }

  Future<void> refillHearts(String userId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'heart_state',
      {
        'current_hearts': HeartStateModel.maxHearts,
        'last_regeneration_at': now,
        'sync_status': 'pending',
        'last_modified_at': now,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
