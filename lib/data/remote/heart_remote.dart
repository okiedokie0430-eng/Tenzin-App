import 'package:appwrite/appwrite.dart';
import '../models/heart_state.dart';
import '../models/user.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class HeartRemote {
  final AppwriteClient _appwriteClient;

  HeartRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  Future<HeartStateModel?> getHeartState(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.heartStatesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return null;
      return HeartStateModel.fromMap(response.documents.first.data);
    } on AppwriteException catch (e) {
      AppLogger.logError('HeartRemote', 'getHeartState', e);
      throw ServerException(e.message ?? 'Failed to fetch heart state');
    }
  }

  Future<HeartStateModel> createHeartState(HeartStateModel heartState) async {
    try {
      final data = heartState.toMap();
      final doc = await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.heartStatesCollection,
        documentId: heartState.userId,
        data: data,
      );
      return HeartStateModel.fromMap({...doc.data, 'user_id': heartState.userId});
    } on AppwriteException catch (e) {
      AppLogger.logError('HeartRemote', 'createHeartState', e);
      throw ServerException(e.message ?? 'Failed to create heart state');
    }
  }

  Future<HeartStateModel> updateHeartState(HeartStateModel heartState) async {
    try {
      final data = heartState.toMap();
      final doc = await _databases.updateDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.heartStatesCollection,
        documentId: heartState.userId,
        data: data,
      );
      return HeartStateModel.fromMap({...doc.data, 'user_id': heartState.userId});
    } on AppwriteException catch (e) {
      AppLogger.logError('HeartRemote', 'updateHeartState', e);
      throw ServerException(e.message ?? 'Failed to update heart state');
    }
  }

  Future<HeartStateModel> upsertHeartState(HeartStateModel heartState) async {
    try {
      final existing = await getHeartState(heartState.userId);
      if (existing != null) {
        return await updateHeartState(heartState);
      } else {
        return await createHeartState(heartState);
      }
    } on ServerException {
      rethrow;
    }
  }

  Future<HeartStateModel> decrementHeart(String userId) async {
    try {
      final heartState = await getHeartState(userId);
      if (heartState == null) {
        throw const ServerException('Heart state not found');
      }

      final updated = heartState.loseHeart().copyWith(
        syncStatus: SyncStatus.synced,
      );
      return await updateHeartState(updated);
    } on AppwriteException catch (e) {
      AppLogger.logError('HeartRemote', 'decrementHeart', e);
      throw ServerException(e.message ?? 'Failed to decrement heart');
    }
  }

  Future<HeartStateModel> refillHearts(String userId) async {
    try {
      final heartState = await getHeartState(userId);
      if (heartState == null) {
        throw const ServerException('Heart state not found');
      }

      final updated = heartState.refillHearts().copyWith(
        syncStatus: SyncStatus.synced,
      );
      return await updateHeartState(updated);
    } on AppwriteException catch (e) {
      AppLogger.logError('HeartRemote', 'refillHearts', e);
      throw ServerException(e.message ?? 'Failed to refill hearts');
    }
  }

  Future<HeartStateModel?> getHeartStateUpdatedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.heartStatesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThan('last_modified_at', timestamp.millisecondsSinceEpoch),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return null;
      return HeartStateModel.fromMap(response.documents.first.data);
    } on AppwriteException catch (e) {
      AppLogger.logError('HeartRemote', 'getHeartStateUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated heart state');
    }
  }
}
