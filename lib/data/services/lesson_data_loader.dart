import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/lesson.dart';
import '../local/daos/lesson_dao.dart';
import '../../core/constants/assets.dart';
import '../../core/utils/logger.dart';

/// Service to load lesson data from local JSON assets into SQLite database.
/// Lessons are LOCAL-ONLY content - they are never fetched from Appwrite.
class LessonDataLoader {
  final LessonDao _lessonDao;

  LessonDataLoader(this._lessonDao);

  /// Cache for original words from JSON (with parent relationships intact)
  static List<Map<String, dynamic>>? _originalWordsCache;
  
  /// Get original words from JSON for dictionary path building
  static Future<List<Map<String, dynamic>>> getOriginalWords() async {
    if (_originalWordsCache != null) {
      return _originalWordsCache!;
    }
    final jsonString = await rootBundle.loadString(AppAssets.lessonsData);
    // parse in background isolate
    final parsed = await compute(_parseOriginalWords, jsonString);
    _originalWordsCache = (parsed['words'] as List<dynamic>).cast<Map<String, dynamic>>();
    return _originalWordsCache!;
  }

  /// Load lessons and words from the JSON asset file into the local database.
  /// This should be called on app startup to seed the database if empty.
  Future<void> loadLessonsFromAssets() async {
    try {
      // Check if we already have lessons loaded
      final existingCount = await _lessonDao.getLessonCount();
      if (existingCount > 0) {
        AppLogger.logInfo('LessonDataLoader', 'Lessons already loaded ($existingCount lessons)');
        return;
      }

      AppLogger.logInfo('LessonDataLoader', 'Loading lessons from assets...');

      // Load JSON from assets
      final jsonString = await rootBundle.loadString(AppAssets.lessonsData);

      // Parse JSON and build plain maps in a background isolate to avoid blocking
      final parsed = await compute(_parseLessonsFromJson, jsonString);

      // Cache original words
      _originalWordsCache = (parsed['originalWords'] as List<dynamic>).cast<Map<String, dynamic>>();

      // Convert parsed maps into models
      final lessons = (parsed['lessons'] as List<dynamic>).map((l) {
        final m = l as Map<String, dynamic>;
        return LessonModel(
          id: m['id'] as String,
          title: m['title'] as String,
          sequenceOrder: m['sequenceOrder'] as int,
          treePath: m['treePath'] as String,
          wordCount: m['wordCount'] as int,
        );
      }).toList();

      final lessonWordsToInsert = (parsed['lessonWords'] as List<dynamic>).map((w) {
        final m = w as Map<String, dynamic>;
        return LessonWordModel(
          id: m['id'] as String,
          lessonId: m['lessonId'] as String,
          parentWordId: m['parentWordId'] as String?,
          wordOrder: m['wordOrder'] as int,
          tibetanScript: m['tibetanScript'] as String,
          phonetic: m['phonetic'] as String,
          mongolianTranslation: m['mongolianTranslation'] as String,
        );
      }).toList();

      // Insert in batches for performance (first-run seeding can be large)
      await _lessonDao.insertLessons(lessons);
      await _lessonDao.insertWords(lessonWordsToInsert);

      final loadedCount = await _lessonDao.getLessonCount();
      final wordCount = await _lessonDao.getWordCount();
      AppLogger.logInfo('LessonDataLoader', 'Loaded $loadedCount lessons with $wordCount words');
    } catch (e, stack) {
      AppLogger.logError('LessonDataLoader', 'loadLessonsFromAssets', e, stackTrace: stack);
      rethrow;
    }
  }

  /// Force reload lessons from assets (clears existing data first)
  Future<void> reloadLessonsFromAssets() async {
    await _lessonDao.clearAllLessons();
    _originalWordsCache = null;
    await loadLessonsFromAssets();
  }
}

/// Top-level parser to extract only original words (used with `compute`)
Map<String, dynamic> _parseOriginalWords(String jsonString) {
  final data = json.decode(jsonString) as Map<String, dynamic>;
  final words = (data['words'] as List<dynamic>).cast<Map<String, dynamic>>();
  return {'words': words};
}

/// Parse lessons and lesson-words into plain maps. Runs in a background isolate via `compute`.
Map<String, dynamic> _parseLessonsFromJson(String jsonString) {
  final data = json.decode(jsonString) as Map<String, dynamic>;

  final wordsJson = (data['words'] as List<dynamic>).cast<Map<String, dynamic>>();
  final wordMap = {for (var w in wordsJson) w['id'] as String: w};

  final lessonsJson = (data['lessons'] as List<dynamic>).cast<Map<String, dynamic>>();
  final lessonsOut = <Map<String, dynamic>>[];
  final lessonWordsOut = <Map<String, dynamic>>[];

  for (final lessonJson in lessonsJson) {
    final lessonId = lessonJson['id'] as String;
    final wordIds = (lessonJson['word_ids'] as List<dynamic>).cast<String>();
    final sequenceOrder = lessonJson['sequence_order'] as int;
    final treePathList = (lessonJson['tree_path'] as List<dynamic>).cast<String>();
    final treePath = treePathList.join(',');

    lessonsOut.add({
      'id': lessonId,
      'title': 'Хичээл $sequenceOrder',
      'sequenceOrder': sequenceOrder,
      'treePath': treePath,
      'wordCount': wordIds.length,
    });

    for (var i = 0; i < wordIds.length; i++) {
      final wordId = wordIds[i];
      final originalWord = wordMap[wordId];
      if (originalWord == null) continue;

      lessonWordsOut.add({
        'id': '${lessonId}_$wordId',
        'lessonId': lessonId,
        'parentWordId': originalWord['parent_word_id'] as String?,
        'wordOrder': i,
        'tibetanScript': originalWord['tibetan_script'] as String,
        'phonetic': originalWord['phonetic'] as String,
        'mongolianTranslation': originalWord['mongolian_translation'] as String,
      });
    }
  }

  return {
    'originalWords': wordsJson,
    'lessons': lessonsOut,
    'lessonWords': lessonWordsOut,
  };
}
