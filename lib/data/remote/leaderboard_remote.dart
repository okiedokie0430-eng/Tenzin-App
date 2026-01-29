import 'package:appwrite/appwrite.dart';
import '../models/leaderboard.dart';
import '../models/user.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class LeaderboardRemote {
  final AppwriteClient _appwriteClient;

  LeaderboardRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  /// Fetch user data for leaderboard entries
  Future<Map<String, UserModel>> _fetchUsersForEntries(List<String> userIds) async {
    final users = <String, UserModel>{};
    for (final userId in userIds) {
      try {
        final userDoc = await _databases.getDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.usersCollection,
          documentId: userId,
        );
        users[userId] = UserModel.fromMap({...userDoc.data, 'id': userDoc.$id});
      } catch (e) {
        // User not found, skip
        AppLogger.debug('User not found for leaderboard: $userId');
      }
    }
    return users;
  }

  /// Enrich leaderboard entries with user data
  List<LeaderboardEntryModel> _enrichEntriesWithUserData(
    List<LeaderboardEntryModel> entries,
    Map<String, UserModel> users,
  ) {
    return entries.map((entry) {
      final user = users[entry.odUserId];
      if (user != null) {
        return entry.copyWith(
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          level: user.level,
          totalXp: user.totalXp,
          streak: user.streak,
        );
      }
      return entry;
    }).toList();
  }

  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard({
    int limit = 50,
  }) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.leaderboardCollection,
        queries: [
          Query.equal('week_start_date', weekStartDate.millisecondsSinceEpoch),
          Query.orderDesc('weekly_xp'),
          Query.limit(limit),
        ],
      );

      final entries = response.documents
          .map((doc) => LeaderboardEntryModel.fromMap(doc.data))
          .toList();

      // Fetch user data for all entries
      final userIds = entries.map((e) => e.odUserId).toList();
      final users = await _fetchUsersForEntries(userIds);

      // Enrich entries with user data and assign ranks
      final enrichedEntries = _enrichEntriesWithUserData(entries, users);
      return enrichedEntries.asMap().entries.map((e) {
        return e.value.copyWith(rank: e.key + 1);
      }).toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('LeaderboardRemote', 'getWeeklyLeaderboard', e);
      throw ServerException(e.message ?? 'Failed to fetch leaderboard');
    }
  }

  Future<LeaderboardEntryModel?> getUserEntry(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.leaderboardCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('week_start_date', weekStartDate.millisecondsSinceEpoch),
          Query.limit(1),
        ],
      );

      if (response.documents.isEmpty) return null;
      return LeaderboardEntryModel.fromMap(response.documents.first.data);
    } on AppwriteException catch (e) {
      AppLogger.logError('LeaderboardRemote', 'getUserEntry', e);
      throw ServerException(e.message ?? 'Failed to fetch user entry');
    }
  }

  Future<int> getUserRank(String userId) async {
    try {
      final entry = await getUserEntry(userId);
      if (entry == null) return 0;

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.leaderboardCollection,
        queries: [
          Query.equal('week_start_date', weekStartDate.millisecondsSinceEpoch),
          Query.greaterThan('weekly_xp', entry.weeklyXp),
          Query.limit(1),
        ],
      );

      return response.total + 1;
    } on AppwriteException catch (e) {
      AppLogger.logError('LeaderboardRemote', 'getUserRank', e);
      throw ServerException(e.message ?? 'Failed to get user rank');
    }
  }

  Future<LeaderboardEntryModel> updateUserXp(
    String userId,
    String userName,
    String? profileImageUrl,
    int xpToAdd,
  ) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final documentId = '${userId}_${weekStartDate.millisecondsSinceEpoch}';

      try {
        // Try to update existing entry
        final existingDoc = await _databases.getDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.leaderboardCollection,
          documentId: documentId,
        );

        final existing = LeaderboardEntryModel.fromMap(existingDoc.data);
        final updated = existing.copyWith(
          weeklyXp: existing.weeklyXp + xpToAdd,
          displayName: userName,
          lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
        );

        final doc = await _databases.updateDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.leaderboardCollection,
          documentId: documentId,
          data: updated.toMap()..remove('id'),
        );
        return LeaderboardEntryModel.fromMap({...doc.data, 'id': doc.$id});
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          // Create new entry
          final now = DateTime.now();
          final entry = LeaderboardEntryModel(
            id: documentId,
            odUserId: userId,
            weekStartDate: weekStartDate,
            weeklyXp: xpToAdd,
            lastModifiedAt: now.millisecondsSinceEpoch,
            displayName: userName,
          );

          final doc = await _databases.createDocument(
            databaseId: AppwriteClient.databaseId,
            collectionId: AppwriteClient.leaderboardCollection,
            documentId: documentId,
            data: entry.toMap()..remove('id'),
          );
          return LeaderboardEntryModel.fromMap({...doc.data, 'id': doc.$id});
        }
        rethrow;
      }
    } on AppwriteException catch (e) {
      AppLogger.logError('LeaderboardRemote', 'updateUserXp', e);
      throw ServerException(e.message ?? 'Failed to update XP');
    }
  }

  /// Set the total weekly XP value (for sync - sets absolute value, doesn't add)
  Future<LeaderboardEntryModel> setUserXp(
    String userId,
    String userName,
    int totalWeeklyXp,
  ) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final documentId = '${userId}_${weekStartDate.millisecondsSinceEpoch}';

      final entry = LeaderboardEntryModel(
        id: documentId,
        odUserId: userId,
        weekStartDate: weekStartDate,
        weeklyXp: totalWeeklyXp,
        lastModifiedAt: now.millisecondsSinceEpoch,
        displayName: userName,
      );

      try {
        // Try to update existing entry
        final doc = await _databases.updateDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.leaderboardCollection,
          documentId: documentId,
          data: entry.toMap()..remove('id'),
        );
        return LeaderboardEntryModel.fromMap({...doc.data, 'id': doc.$id});
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          // Create new entry
          final doc = await _databases.createDocument(
            databaseId: AppwriteClient.databaseId,
            collectionId: AppwriteClient.leaderboardCollection,
            documentId: documentId,
            data: entry.toMap()..remove('id'),
          );
          return LeaderboardEntryModel.fromMap({...doc.data, 'id': doc.$id});
        }
        rethrow;
      }
    } on AppwriteException catch (e) {
      AppLogger.logError('LeaderboardRemote', 'setUserXp', e);
      throw ServerException(e.message ?? 'Failed to set XP');
    }
  }

  Future<List<LeaderboardEntryModel>> getFollowingLeaderboard(
    String userId,
    List<String> followingIds,
  ) async {
    try {
      if (followingIds.isEmpty) {
        // Still return current user's entry
        final userEntry = await getUserEntry(userId);
        if (userEntry != null) {
          final users = await _fetchUsersForEntries([userId]);
          return _enrichEntriesWithUserData([userEntry.copyWith(rank: 1)], users);
        }
        return [];
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      // Include current user in the list
      final allIds = [...followingIds, userId];

      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.leaderboardCollection,
        queries: [
          Query.equal('week_start_date', weekStartDate.millisecondsSinceEpoch),
          Query.equal('user_id', allIds),
          Query.orderDesc('weekly_xp'),
          Query.limit(50),
        ],
      );

      final entries = response.documents
          .map((doc) => LeaderboardEntryModel.fromMap(doc.data))
          .toList();

      // Fetch user data for all entries
      final userIds = entries.map((e) => e.odUserId).toList();
      final users = await _fetchUsersForEntries(userIds);

      // Enrich entries with user data and assign ranks
      final enrichedEntries = _enrichEntriesWithUserData(entries, users);
      return enrichedEntries.asMap().entries.map((e) {
        return e.value.copyWith(rank: e.key + 1);
      }).toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('LeaderboardRemote', 'getFollowingLeaderboard', e);
      throw ServerException(e.message ?? 'Failed to fetch following leaderboard');
    }
  }

  Future<List<LeaderboardEntryModel>> getHistoricalLeaderboard(
    DateTime weekStart, {
    int limit = 50,
  }) async {
    try {
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.leaderboardCollection,
        queries: [
          Query.equal('week_start_date', weekStartDate.millisecondsSinceEpoch),
          Query.orderDesc('weekly_xp'),
          Query.limit(limit),
        ],
      );

      final entries = response.documents
          .map((doc) => LeaderboardEntryModel.fromMap(doc.data))
          .toList();

      // Fetch user data for all entries
      final userIds = entries.map((e) => e.odUserId).toList();
      final users = await _fetchUsersForEntries(userIds);

      // Enrich entries with user data and assign ranks
      final enrichedEntries = _enrichEntriesWithUserData(entries, users);
      return enrichedEntries.asMap().entries.map((e) {
        return e.value.copyWith(rank: e.key + 1);
      }).toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('LeaderboardRemote', 'getHistoricalLeaderboard', e);
      throw ServerException(e.message ?? 'Failed to fetch historical leaderboard');
    }
  }
}
