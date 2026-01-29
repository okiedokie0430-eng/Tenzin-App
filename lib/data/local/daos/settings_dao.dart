import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/user_settings.dart';
import '../../../core/utils/logger.dart';

class SettingsDao {
  final DatabaseHelper _dbHelper;

  SettingsDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(UserSettingsModel settings) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'user_settings');
    return await db.insert(
      'user_settings',
      settings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserSettingsModel?> getByUserId(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return UserSettingsModel.fromMap(maps.first);
  }

  Future<UserSettingsModel> getOrCreate(String userId) async {
    var settings = await getByUserId(userId);
    if (settings == null) {
      settings = UserSettingsModel.initial(userId);
      await insert(settings);
    }
    return settings;
  }

  Future<int> update(UserSettingsModel settings) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'user_settings');
    return await db.update(
      'user_settings',
      settings.toMap(),
      where: 'user_id = ?',
      whereArgs: [settings.userId],
    );
  }

  Future<int> delete(String userId) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'user_settings');
    return await db.delete(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateNotificationSetting(
    String userId,
    String settingKey,
    bool value,
  ) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'user_settings',
      {
        settingKey: value ? 1 : 0,
        'sync_status': 'pending',
        'last_modified_at': now,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> setStoragePermissionGranted(String userId, bool granted) async {
    final db = await _db;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    await db.update(
      'user_settings',
      {
        'storage_permission_granted': granted ? 1 : 0,
        'sync_status': 'pending',
        'last_modified_at': now,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<UserSettingsModel?> getPendingSync() async {
    final db = await _db;
    final maps = await db.query(
      'user_settings',
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return UserSettingsModel.fromMap(maps.first);
  }

  Future<void> markAsSynced(String userId) async {
    final db = await _db;
    await db.update(
      'user_settings',
      {'sync_status': 'synced'},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
