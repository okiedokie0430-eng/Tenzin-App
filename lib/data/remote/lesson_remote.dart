import 'package:appwrite/appwrite.dart';
import '../models/lesson.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class LessonRemote {
  final AppwriteClient _appwriteClient;

  LessonRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  Future<List<LessonModel>> getAllLessons() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.lessonsCollection,
        queries: [
          Query.orderAsc('order_index'),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => LessonModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('LessonRemote', 'getAllLessons', e);
      throw ServerException(e.message ?? 'Failed to fetch lessons');
    }
  }

  Future<LessonModel?> getLessonById(String lessonId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.lessonsCollection,
        documentId: lessonId,
      );
      return LessonModel.fromMap(doc.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      AppLogger.logError('LessonRemote', 'getLessonById', e);
      throw ServerException(e.message ?? 'Failed to fetch lesson');
    }
  }

  Future<List<LessonWordModel>> getLessonWords(String lessonId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.lessonWordsCollection,
        queries: [
          Query.equal('lesson_id', lessonId),
          Query.orderAsc('order_index'),
        ],
      );

      return response.documents
          .map((doc) => LessonWordModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('LessonRemote', 'getLessonWords', e);
      throw ServerException(e.message ?? 'Failed to fetch lesson words');
    }
  }

  Future<LessonWithWords?> getLessonWithWords(String lessonId) async {
    try {
      final lesson = await getLessonById(lessonId);
      if (lesson == null) return null;

      final words = await getLessonWords(lessonId);
      return LessonWithWords(lesson: lesson, words: words);
    } on AppwriteException catch (e) {
      AppLogger.logError('LessonRemote', 'getLessonWithWords', e);
      throw ServerException(e.message ?? 'Failed to fetch lesson with words');
    }
  }

  Future<List<LessonModel>> getLessonsUpdatedAfter(DateTime timestamp) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.lessonsCollection,
        queries: [
          Query.greaterThan('updated_at', timestamp.millisecondsSinceEpoch),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => LessonModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('LessonRemote', 'getLessonsUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated lessons');
    }
  }

  Future<List<LessonWordModel>> getWordsUpdatedAfter(DateTime timestamp) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.lessonWordsCollection,
        queries: [
          Query.greaterThan('updated_at', timestamp.millisecondsSinceEpoch),
          Query.limit(500),
        ],
      );

      return response.documents
          .map((doc) => LessonWordModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('LessonRemote', 'getWordsUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated words');
    }
  }

  Future<int> getLessonCount() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.lessonsCollection,
        queries: [Query.limit(1)],
      );
      return response.total;
    } on AppwriteException catch (e) {
      AppLogger.logError('LessonRemote', 'getLessonCount', e);
      throw ServerException(e.message ?? 'Failed to get lesson count');
    }
  }
}
