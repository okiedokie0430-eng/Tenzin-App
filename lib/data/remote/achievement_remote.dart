import 'package:appwrite/appwrite.dart';
import '../models/achievement.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class AchievementRemote {
  final AppwriteClient _appwriteClient;

  AchievementRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  Future<List<AchievementModel>> getAllAchievements() async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.achievementsCollection,
        queries: [
          Query.orderAsc('order_index'),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => AchievementModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('AchievementRemote', 'getAllAchievements', e);
      throw ServerException(e.message ?? 'Failed to fetch achievements');
    }
  }

  Future<AchievementModel?> getAchievementById(String achievementId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.achievementsCollection,
        documentId: achievementId,
      );
      return AchievementModel.fromMap(doc.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      AppLogger.logError('AchievementRemote', 'getAchievementById', e);
      throw ServerException(e.message ?? 'Failed to fetch achievement');
    }
  }

  Future<List<UserAchievementModel>> getUserAchievements(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userAchievementsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => UserAchievementModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('AchievementRemote', 'getUserAchievements', e);
      throw ServerException(e.message ?? 'Failed to fetch user achievements');
    }
  }

  Future<UserAchievementModel> unlockAchievement(
    String userId,
    String achievementId,
  ) async {
    try {
      final now = DateTime.now();
      final userAchievement = UserAchievementModel(
        id: '${userId}_$achievementId',
        userId: userId,
        achievementId: achievementId,
        unlockedAt: now,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      final doc = await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userAchievementsCollection,
        documentId: userAchievement.id,
        data: userAchievement.toMap()..remove('id'),
      );
      return UserAchievementModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // Already unlocked
        final existing = await _databases.getDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.userAchievementsCollection,
          documentId: '${userId}_$achievementId',
        );
        return UserAchievementModel.fromMap(existing.data);
      }
      AppLogger.logError('AchievementRemote', 'unlockAchievement', e);
      throw ServerException(e.message ?? 'Failed to unlock achievement');
    }
  }

  Future<UserAchievementModel?> updateProgress(
    String userId,
    String achievementId,
    int progress,
  ) async {
    try {
      final docId = '${userId}_$achievementId';
      
      // Only create UserAchievementModel when progress reaches 100%
      if (progress >= 100) {
        try {
          // Check if already exists
          final existing = await _databases.getDocument(
            databaseId: AppwriteClient.databaseId,
            collectionId: AppwriteClient.userAchievementsCollection,
            documentId: docId,
          );
          return UserAchievementModel.fromMap(existing.data);
        } on AppwriteException catch (e) {
          if (e.code == 404) {
            // Create new achievement unlock
            final now = DateTime.now();
            final userAchievement = UserAchievementModel(
              id: docId,
              userId: userId,
              achievementId: achievementId,
              unlockedAt: now,
              lastModifiedAt: now.millisecondsSinceEpoch,
            );

            final doc = await _databases.createDocument(
              databaseId: AppwriteClient.databaseId,
              collectionId: AppwriteClient.userAchievementsCollection,
              documentId: docId,
              data: userAchievement.toMap(),
            );
            return UserAchievementModel.fromMap(doc.data);
          }
          rethrow;
        }
      }
      
      // Progress not at 100%, no UserAchievementModel to return
      return null;
    } on AppwriteException catch (e) {
      AppLogger.logError('AchievementRemote', 'updateProgress', e);
      throw ServerException(e.message ?? 'Failed to update progress');
    }
  }

  Future<List<AchievementWithStatus>> getAchievementsWithStatus(
    String userId,
  ) async {
    try {
      final achievements = await getAllAchievements();
      final userAchievements = await getUserAchievements(userId);
      
      final userAchievementMap = {
        for (final ua in userAchievements) ua.achievementId: ua
      };

      return achievements.map((achievement) {
        final userAchievement = userAchievementMap[achievement.id];
        return AchievementWithStatus(
          achievement: achievement,
          userAchievement: userAchievement,
        );
      }).toList();
    } on ServerException {
      rethrow;
    }
  }

  Future<int> getUnlockedCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userAchievementsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('is_unlocked', true),
          Query.limit(1),
        ],
      );
      return response.total;
    } on AppwriteException catch (e) {
      AppLogger.logError('AchievementRemote', 'getUnlockedCount', e);
      throw ServerException(e.message ?? 'Failed to get unlocked count');
    }
  }

  Future<List<AchievementModel>> getAchievementsUpdatedAfter(
    DateTime timestamp,
  ) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.achievementsCollection,
        queries: [
          Query.greaterThan('updated_at', timestamp.millisecondsSinceEpoch),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => AchievementModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('AchievementRemote', 'getAchievementsUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated achievements');
    }
  }

  Future<List<UserAchievementModel>> getUserAchievementsUpdatedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.userAchievementsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThan('unlocked_at', timestamp.millisecondsSinceEpoch),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => UserAchievementModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('AchievementRemote', 'getUserAchievementsUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated user achievements');
    }
  }
}
