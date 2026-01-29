import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/follow.dart';
import '../../models/user.dart';
import '../../../core/utils/logger.dart';

class FollowDao {
  final DatabaseHelper _dbHelper;

  FollowDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  /// Insert or replace a follow relationship
  Future<int> insert(FollowModel follow) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'follows');
    return await db.insert(
      'follows',
      follow.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get follow by ID (excludes pending_delete)
  Future<FollowModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'id = ? AND sync_status != ?',
      whereArgs: [id, 'pending_delete'],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return FollowModel.fromMap(maps.first);
  }

  /// Get follow by follower and following IDs (excludes pending_delete)
  Future<FollowModel?> getByFollowerAndFollowing(
    String followerId,
    String followingId,
  ) async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'follower_id = ? AND following_id = ? AND sync_status != ?',
      whereArgs: [followerId, followingId, 'pending_delete'],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return FollowModel.fromMap(maps.first);
  }

  /// Check if user A is following user B (excludes pending_delete)
  Future<bool> isFollowing(String followerId, String followingId) async {
    final follow = await getByFollowerAndFollowing(followerId, followingId);
    return follow != null;
  }

  /// Check if two users mutually follow each other
  Future<bool> isMutualFollow(String userId1, String userId2) async {
    final follow1 = await isFollowing(userId1, userId2);
    final follow2 = await isFollowing(userId2, userId1);
    return follow1 && follow2;
  }

  /// Get all followers of a user (excludes pending_delete)
  Future<List<FollowModel>> getFollowers(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'following_id = ? AND sync_status != ?',
      whereArgs: [userId, 'pending_delete'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FollowModel.fromMap(map)).toList();
  }

  /// Get all users that a user is following (excludes pending_delete)
  Future<List<FollowModel>> getFollowing(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'follower_id = ? AND sync_status != ?',
      whereArgs: [userId, 'pending_delete'],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => FollowModel.fromMap(map)).toList();
  }

  /// Get follower count (excludes pending_delete)
  Future<int> getFollowerCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM follows 
      WHERE following_id = ? AND sync_status != 'pending_delete'
    ''', [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get following count (excludes pending_delete)
  Future<int> getFollowingCount(String userId) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as count FROM follows 
      WHERE follower_id = ? AND sync_status != 'pending_delete'
    ''', [userId]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Hard delete a follow by ID
  Future<int> delete(String id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'follows');
    return await db.delete(
      'follows',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Hard delete by follower and following IDs
  Future<int> deleteByFollowerAndFollowing(
    String followerId,
    String followingId,
  ) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'follows');
    return await db.delete(
      'follows',
      where: 'follower_id = ? AND following_id = ?',
      whereArgs: [followerId, followingId],
    );
  }

  /// Soft delete: Mark as pending_delete for later sync
  Future<int> markForDeletion(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    AppLogger.logDatabase('UPDATE', 'follows (mark for deletion)');
    return await db.update(
      'follows',
      {
        'sync_status': 'pending_delete',
        'last_modified_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all follows for a user (both as follower and following)
  Future<int> deleteByUser(String userId) async {
    final db = await _db;
    final count1 = await db.delete(
      'follows',
      where: 'follower_id = ?',
      whereArgs: [userId],
    );
    final count2 = await db.delete(
      'follows',
      where: 'following_id = ?',
      whereArgs: [userId],
    );
    return count1 + count2;
  }

  /// Get all pending follows that need to be synced to server
  Future<List<FollowModel>> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'last_modified_at ASC',
    );
    return maps.map((map) => FollowModel.fromMap(map)).toList();
  }

  /// Get all pending deletes that need to be synced to server
  Future<List<FollowModel>> getPendingDeletes() async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'sync_status = ?',
      whereArgs: ['pending_delete'],
      orderBy: 'last_modified_at ASC',
    );
    return maps.map((map) => FollowModel.fromMap(map)).toList();
  }

  /// Mark a follow as synced
  Future<void> markAsSynced(String id) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    AppLogger.logDatabase('UPDATE', 'follows (mark synced)');
    await db.update(
      'follows',
      {
        'sync_status': 'synced',
        'last_modified_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get a follow record including pending_delete (for sync purposes)
  Future<FollowModel?> getByIdIncludingDeleted(String id) async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return FollowModel.fromMap(maps.first);
  }

  /// Check if a follow exists at all (including pending_delete)
  Future<bool> existsIncludingDeleted(String followerId, String followingId) async {
    final db = await _db;
    final maps = await db.query(
      'follows',
      where: 'follower_id = ? AND following_id = ?',
      whereArgs: [followerId, followingId],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// Update sync status
  Future<void> updateSyncStatus(String id, SyncStatus status) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    String statusStr;
    switch (status) {
      case SyncStatus.pending:
        statusStr = 'pending';
        break;
      case SyncStatus.synced:
        statusStr = 'synced';
        break;
      case SyncStatus.pendingDelete:
        statusStr = 'pending_delete';
        break;
      case SyncStatus.failed:
        statusStr = 'failed';
        break;
    }

    await db.update(
      'follows',
      {
        'sync_status': statusStr,
        'last_modified_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
