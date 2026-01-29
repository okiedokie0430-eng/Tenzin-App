import 'package:appwrite/appwrite.dart';
import '../models/user_settings.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class SettingsRemote {
  final AppwriteClient _appwriteClient;

  SettingsRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  Future<UserSettingsModel?> getUserSettings(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userSettingsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return null;
      return UserSettingsModel.fromMap(response.documents.first.data);
    } on AppwriteException catch (e) {
      AppLogger.logError('SettingsRemote', 'getUserSettings', e);
      throw ServerException(e.message ?? 'Failed to fetch user settings');
    }
  }

  Future<UserSettingsModel> createUserSettings(
    UserSettingsModel settings,
  ) async {
    try {
      final data = settings.toMap();
      final doc = await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userSettingsCollection,
        documentId: settings.userId,
        data: data,
      );
      return UserSettingsModel.fromMap({...doc.data, 'user_id': settings.userId});
    } on AppwriteException catch (e) {
      AppLogger.logError('SettingsRemote', 'createUserSettings', e);
      throw ServerException(e.message ?? 'Failed to create user settings');
    }
  }

  Future<UserSettingsModel> updateUserSettings(
    UserSettingsModel settings,
  ) async {
    try {
      final data = settings.toMap();
      final doc = await _databases.updateDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userSettingsCollection,
        documentId: settings.userId,
        data: data,
      );
      return UserSettingsModel.fromMap({...doc.data, 'user_id': settings.userId});
    } on AppwriteException catch (e) {
      AppLogger.logError('SettingsRemote', 'updateUserSettings', e);
      throw ServerException(e.message ?? 'Failed to update user settings');
    }
  }

  Future<UserSettingsModel> upsertUserSettings(
    UserSettingsModel settings,
  ) async {
    try {
      final existing = await getUserSettings(settings.userId);
      if (existing != null) {
        return await updateUserSettings(settings);
      } else {
        return await createUserSettings(settings);
      }
    } on ServerException {
      rethrow;
    }
  }

  Future<void> deleteUserSettings(String userId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userSettingsCollection,
        documentId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return;
      AppLogger.logError('SettingsRemote', 'deleteUserSettings', e);
      throw ServerException(e.message ?? 'Failed to delete user settings');
    }
  }

  Future<UserSettingsModel?> getSettingsUpdatedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userSettingsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThan('last_modified_at', timestamp.millisecondsSinceEpoch),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return null;
      return UserSettingsModel.fromMap(response.documents.first.data);
    } on AppwriteException catch (e) {
      AppLogger.logError('SettingsRemote', 'getSettingsUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated settings');
    }
  }
}
