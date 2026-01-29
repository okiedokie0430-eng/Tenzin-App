import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/user.dart';
import '../../../core/utils/logger.dart';

class UserDao {
  final DatabaseHelper _dbHelper;

  UserDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(UserModel user) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'user_profile');
    return await db.insert(
      'user_profile',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<UserModel?> getByEmail(String email) async {
    final db = await _db;
    final maps = await db.query(
      'user_profile',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<List<UserModel>> getAll() async {
    final db = await _db;
    final maps = await db.query('user_profile');
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<int> update(UserModel user) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'user_profile');
    return await db.update(
      'user_profile',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> delete(String id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'user_profile');
    return await db.delete(
      'user_profile',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<UserModel>> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'user_profile',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'last_modified_at ASC',
    );
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  Future<void> markAsSynced(String id) async {
    final db = await _db;
    await db.update(
      'user_profile',
      {'sync_status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateXp(String userId, int xpToAdd, int weeklyXpToAdd) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE user_profile 
      SET total_xp = total_xp + ?,
          weekly_xp = weekly_xp + ?,
          sync_status = 'pending',
          last_modified_at = ?
      WHERE id = ?
    ''', [xpToAdd, weeklyXpToAdd, now, userId]);
  }

  Future<void> incrementLessonsCompleted(String userId) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE user_profile 
      SET lessons_completed = lessons_completed + 1,
          last_lesson_date = ?,
          sync_status = 'pending',
          last_modified_at = ?
      WHERE id = ?
    ''', [now, now, userId]);
  }

  Future<void> updateStreak(String userId, int currentStreak, int longestStreak) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'user_profile',
      {
        'current_streak_days': currentStreak,
        'longest_streak_days': longestStreak,
        'sync_status': 'pending',
        'last_modified_at': now,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateFollowerCount(String userId, int delta) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE user_profile 
      SET follower_count = follower_count + ?,
          sync_status = 'pending',
          last_modified_at = ?
      WHERE id = ?
    ''', [delta, now, userId]);
  }

  Future<void> updateFollowingCount(String userId, int delta) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE user_profile 
      SET following_count = following_count + ?,
          sync_status = 'pending',
          last_modified_at = ?
      WHERE id = ?
    ''', [delta, now, userId]);
  }

  Future<void> resetWeeklyXp() async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.rawUpdate('''
      UPDATE user_profile 
      SET weekly_xp = 0,
          sync_status = 'pending',
          last_modified_at = ?
    ''', [now]);
  }

  Future<List<UserModel>> searchByName(String query) async {
    final db = await _db;
    final maps = await db.query(
      'user_profile',
      where: 'display_name LIKE ?',
      whereArgs: ['%$query%'],
      limit: 50,
    );
    return maps.map((map) => UserModel.fromMap(map)).toList();
  }

  /// Ensures a user profile exists in the database.
  /// If the user doesn't exist, creates a placeholder profile.
  /// This is used to satisfy foreign key constraints when caching remote data.
  Future<void> ensureUserExists(String userId, {String? displayName, String? email}) async {
    final existingUser = await getById(userId);
    if (existingUser != null) return;

    // Create placeholder user profile
    final now = DateTime.now().millisecondsSinceEpoch;
    final placeholder = UserModel(
      id: userId,
      email: email ?? '$userId@placeholder.local',
      displayName: displayName ?? 'User',
      syncStatus: SyncStatus.synced,
      lastModifiedAt: now,
    );
    
    await insert(placeholder);
  }

  /// Ensures multiple user profiles exist in the database.
  Future<void> ensureUsersExist(List<String> userIds) async {
    for (final userId in userIds) {
      await ensureUserExists(userId);
    }
  }
}
