import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/tarni_entry.dart';
import '../../../core/utils/logger.dart';

class TarniDao {
  final DatabaseHelper _dbHelper;

  TarniDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(String userId, TarniEntry entry) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'tarni_counters');
    return await db.insert(
      'tarni_counters',
      {
        'user_id': userId,
        'magzushir': entry.magzushirCount,
        'janraisig': entry.janraisigCount,
        'created_at': entry.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<TarniEntry>> getByUserId(String userId) async {
    final db = await _db;
    final maps = await db.query(
      'tarni_counters',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map((m) {
      final idVal = m['id'];
      return TarniEntry(
        id: idVal != null ? '$idVal' : (m['user_id'] as String? ?? ''),
        userId: m['user_id'] as String?,
        magzushirCount: (m['magzushir'] as int?) ?? int.tryParse('${m['magzushir']}') ?? 0,
        janraisigCount: (m['janraisig'] as int?) ?? int.tryParse('${m['janraisig']}') ?? 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
      );
    }).toList();
  }

  Future<TarniEntry?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'tarni_counters',
      where: 'id = ?',
      whereArgs: [int.tryParse(id) ?? id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final m = maps.first;
    final idVal = m['id'];
    return TarniEntry(
      id: idVal != null ? '$idVal' : (m['user_id'] as String? ?? ''),
      userId: m['user_id'] as String?,
      magzushirCount: (m['magzushir'] as int?) ?? int.tryParse('${m['magzushir']}') ?? 0,
      janraisigCount: (m['janraisig'] as int?) ?? int.tryParse('${m['janraisig']}') ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    );
  }

  Future<TarniEntry> getOrCreate(String userId) async {
    final list = await getByUserId(userId);
    if (list.isNotEmpty) return list.first;
    final now = DateTime.now();
    final entry = TarniEntry(id: '', userId: userId, magzushirCount: 0, janraisigCount: 0, createdAt: now);
    final row = await insert(userId, entry);
    final created = await getById('$row');
    return created ?? TarniEntry(id: '$row', userId: userId, magzushirCount: 0, janraisigCount: 0, createdAt: now);
  }

  Future<int> updateById(String id, int magzushir, int janraisig) async {
    final db = await _db;
    AppLogger.logDatabase('UPDATE', 'tarni_counters');
    final now = DateTime.now().millisecondsSinceEpoch;
    return await db.update(
      'tarni_counters',
      {
        'magzushir': magzushir,
        'janraisig': janraisig,
        'created_at': now,
      },
      where: 'id = ?',
      whereArgs: [int.tryParse(id) ?? id],
    );
  }

  Future<int> deleteById(String id) async {
    final db = await _db;
    AppLogger.logDatabase('DELETE', 'tarni_counters');
    return await db.delete(
      'tarni_counters',
      where: 'id = ?',
      whereArgs: [int.tryParse(id) ?? id],
    );
  }
}
