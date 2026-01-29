import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/lesson.dart';
import '../../../core/utils/logger.dart';

class LessonDao {
  final DatabaseHelper _dbHelper;

  LessonDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<int> insertLesson(LessonModel lesson) async {
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'lessons');
    return await db.insert(
      'lessons',
      lesson.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertLessons(List<LessonModel> lessons) async {
    if (lessons.isEmpty) return;
    final db = await _db;
    AppLogger.logDatabase('INSERT', 'lessons');
    final batch = db.batch();

    for (final lesson in lessons) {
      batch.insert(
        'lessons',
        lesson.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<int> insertWord(LessonWordModel word) async {
    final db = await _db;
    return await db.insert(
      'lesson_words',
      word.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertWords(List<LessonWordModel> words) async {
    final db = await _db;
    final batch = db.batch();
    
    for (final word in words) {
      batch.insert(
        'lesson_words',
        word.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<LessonModel?> getById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'lessons',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return LessonModel.fromMap(maps.first);
  }

  Future<LessonModel?> getBySequenceOrder(int order) async {
    final db = await _db;
    final maps = await db.query(
      'lessons',
      where: 'sequence_order = ?',
      whereArgs: [order],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return LessonModel.fromMap(maps.first);
  }

  Future<List<LessonModel>> getAll() async {
    final db = await _db;
    final maps = await db.query(
      'lessons',
      orderBy: 'sequence_order ASC',
    );
    return maps.map((map) => LessonModel.fromMap(map)).toList();
  }

  Future<int> getLessonCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM lessons');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<LessonWordModel>> getWordsForLesson(String lessonId) async {
    final db = await _db;
    final maps = await db.query(
      'lesson_words',
      where: 'lesson_id = ?',
      whereArgs: [lessonId],
      orderBy: 'word_order ASC',
    );
    return maps.map((map) => LessonWordModel.fromMap(map)).toList();
  }

  Future<LessonWithWords?> getLessonWithWords(String lessonId) async {
    final lesson = await getById(lessonId);
    if (lesson == null) return null;
    
    final words = await getWordsForLesson(lessonId);
    return LessonWithWords(lesson: lesson, words: words);
  }

  Future<List<LessonWordModel>> getAllWords() async {
    final db = await _db;
    final maps = await db.query('lesson_words');
    return maps.map((map) => LessonWordModel.fromMap(map)).toList();
  }

  /// Get unique words for dictionary (deduplicated by tibetan_script + mongolian_translation)
  /// This avoids duplicate entries when the same word appears in multiple lessons
  Future<List<LessonWordModel>> getUniqueWordsForDictionary() async {
    final db = await _db;
    // Get distinct words by grouping on tibetan_script and mongolian_translation
    final maps = await db.rawQuery('''
      SELECT id, lesson_id, parent_word_id, word_order, 
             tibetan_script, phonetic, mongolian_translation, version
      FROM lesson_words 
      GROUP BY tibetan_script, mongolian_translation
      ORDER BY mongolian_translation ASC
    ''');
    return maps.map((map) => LessonWordModel.fromMap(map)).toList();
  }

  Future<LessonWordModel?> getWordById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'lesson_words',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) return null;
    return LessonWordModel.fromMap(maps.first);
  }

  Future<List<LessonWordModel>> searchWords(String query) async {
    final db = await _db;
    final maps = await db.query(
      'lesson_words',
      where: 'mongolian_translation LIKE ? OR phonetic LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      limit: 50,
    );
    return maps.map((map) => LessonWordModel.fromMap(map)).toList();
  }

  Future<void> clearAllLessons() async {
    final db = await _db;
    await db.delete('lesson_words');
    await db.delete('lessons');
  }

  Future<int> getWordCount() async {
    final db = await _db;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM lesson_words');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<LessonWordModel>> getRandomWords(int count, {String? excludeLessonId}) async {
    final db = await _db;
    String query = 'SELECT * FROM lesson_words';
    final List<dynamic> args = [];
    
    if (excludeLessonId != null) {
      query += ' WHERE lesson_id != ?';
      args.add(excludeLessonId);
    }
    
    query += ' ORDER BY RANDOM() LIMIT ?';
    args.add(count);
    
    final maps = await db.rawQuery(query, args);
    return maps.map((map) => LessonWordModel.fromMap(map)).toList();
  }
}
