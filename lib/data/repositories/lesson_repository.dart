import '../models/lesson.dart';
import '../local/daos/lesson_dao.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

/// Repository for lesson data.
/// IMPORTANT: Lessons are LOCAL-ONLY content loaded from assets.
/// They are never fetched from Appwrite. Only user progress is synced remotely.
class LessonRepository {
  final LessonDao _lessonDao;

  LessonRepository(this._lessonDao);

  /// Get all lessons from local database.
  /// Lessons should be pre-loaded from assets via LessonDataLoader.
  Future<({List<LessonModel> lessons, Failure? failure})> getAllLessons({
    bool forceRefresh = false,
  }) async {
    try {
      final localLessons = await _lessonDao.getAll();
      
      if (localLessons.isEmpty) {
        AppLogger.logWarning('LessonRepository', 
          'No lessons found. Ensure LessonDataLoader.loadLessonsFromAssets() was called.');
      }
      
      return (lessons: localLessons, failure: null);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getAllLessons', e);
      return (
        lessons: <LessonModel>[],
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  /// Get a single lesson by ID from local database.
  Future<({LessonModel? lesson, Failure? failure})> getLessonById(
    String lessonId,
  ) async {
    try {
      final lesson = await _lessonDao.getById(lessonId);
      return (lesson: lesson, failure: null);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getLessonById', e);
      return (lesson: null, failure: Failure.unknown(e.toString()));
    }
  }

  /// Get a lesson with all its words from local database.
  Future<({LessonWithWords? lessonWithWords, Failure? failure})> 
      getLessonWithWords(String lessonId) async {
    try {
      final lessonWithWords = await _lessonDao.getLessonWithWords(lessonId);
      return (lessonWithWords: lessonWithWords, failure: null);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getLessonWithWords', e);
      return (
        lessonWithWords: null,
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  /// Get all words for a specific lesson from local database.
  Future<({List<LessonWordModel> words, Failure? failure})> getLessonWords(
    String lessonId,
  ) async {
    try {
      final words = await _lessonDao.getWordsForLesson(lessonId);
      return (words: words, failure: null);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getLessonWords', e);
      return (words: <LessonWordModel>[], failure: Failure.unknown(e.toString()));
    }
  }

  /// Get total number of lessons from local database.
  Future<int> getLessonCount() async {
    try {
      return await _lessonDao.getLessonCount();
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getLessonCount', e);
      return 0;
    }
  }

  /// Get the next lesson by sequence order.
  Future<LessonModel?> getNextLesson(int currentOrderIndex) async {
    try {
      return await _lessonDao.getBySequenceOrder(currentOrderIndex + 1);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getNextLesson', e);
      return null;
    }
  }

  /// Get the previous lesson by sequence order.
  Future<LessonModel?> getPreviousLesson(int currentOrderIndex) async {
    try {
      return await _lessonDao.getBySequenceOrder(currentOrderIndex - 1);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getPreviousLesson', e);
      return null;
    }
  }

  /// Get all words in the database (for dictionary feature).
  Future<List<LessonWordModel>> getAllWords() async {
    try {
      return await _lessonDao.getAllWords();
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getAllWords', e);
      return [];
    }
  }

  /// Get unique words for dictionary (deduplicated).
  Future<List<LessonWordModel>> getUniqueWordsForDictionary() async {
    try {
      return await _lessonDao.getUniqueWordsForDictionary();
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getUniqueWordsForDictionary', e);
      return [];
    }
  }

  /// Search words by query (Mongolian translation or phonetic).
  Future<List<LessonWordModel>> searchWords(String query) async {
    try {
      return await _lessonDao.searchWords(query);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'searchWords', e);
      return [];
    }
  }

  /// Get random words for quiz questions (excluding words from a specific lesson).
  Future<List<LessonWordModel>> getRandomWords(int count, {String? excludeLessonId}) async {
    try {
      return await _lessonDao.getRandomWords(count, excludeLessonId: excludeLessonId);
    } catch (e) {
      AppLogger.logError('LessonRepository', 'getRandomWords', e);
      return [];
    }
  }
}
