import 'package:appwrite/appwrite.dart';
import '../models/progress.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class ProgressRemote {
  final AppwriteClient _appwriteClient;

  ProgressRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  Future<List<ProgressModel>> getUserProgress(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => ProgressModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'getUserProgress', e);
      throw ServerException(e.message ?? 'Failed to fetch progress');
    }
  }

  Future<ProgressModel?> getProgress(String oderId, String lessonId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        queries: [
          Query.equal('user_id', oderId),
          Query.equal('lesson_id', lessonId),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return null;
      return ProgressModel.fromMap(response.documents.first.data);
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'getProgress', e);
      throw ServerException(e.message ?? 'Failed to fetch progress');
    }
  }

  Future<ProgressModel> createProgress(ProgressModel progress) async {
    try {
      final data = progress.toMap()..remove('id');
      final doc = await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        documentId: progress.id,
        data: data,
      );
      return ProgressModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'createProgress', e);
      throw ServerException(e.message ?? 'Failed to create progress');
    }
  }

  Future<ProgressModel> updateProgress(ProgressModel progress) async {
    try {
      final data = progress.toMap()..remove('id');
      final doc = await _databases.updateDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        documentId: progress.id,
        data: data,
      );
      return ProgressModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'updateProgress', e);
      throw ServerException(e.message ?? 'Failed to update progress');
    }
  }

  Future<ProgressModel> upsertProgress(ProgressModel progress) async {
    try {
      final existing = await getProgress(progress.odUserId, progress.lessonId);
      if (existing != null) {
        return await updateProgress(progress);
      } else {
        return await createProgress(progress);
      }
    } on ServerException {
      rethrow;
    }
  }

  Future<void> deleteProgress(String progressId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        documentId: progressId,
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'deleteProgress', e);
      throw ServerException(e.message ?? 'Failed to delete progress');
    }
  }

  Future<List<ProgressModel>> getProgressUpdatedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThan('last_modified_at', timestamp.millisecondsSinceEpoch),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => ProgressModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'getProgressUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated progress');
    }
  }

  Future<int> getCompletedLessonCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('status', 'completed'),
          Query.limit(1),
        ],
      );
      return response.total;
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'getCompletedLessonCount', e);
      throw ServerException(e.message ?? 'Failed to get completed count');
    }
  }

  Future<int> getTotalXP(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.progressCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(100),
        ],
      );

      int totalXp = 0;
      for (final doc in response.documents) {
        totalXp += (doc.data['xp_earned'] as int? ?? 0);
      }
      return totalXp;
    } on AppwriteException catch (e) {
      AppLogger.logError('ProgressRemote', 'getTotalXP', e);
      throw ServerException(e.message ?? 'Failed to get total XP');
    }
  }
}
