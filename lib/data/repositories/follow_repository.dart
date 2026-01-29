import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/follow.dart';
import '../models/user.dart';
import '../local/daos/follow_dao.dart';
import '../local/daos/user_dao.dart';
import '../remote/follow_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

/// Simplified Follow Repository
/// 
/// Design principles:
/// 1. Server is the source of truth
/// 2. Local database is just a cache for offline viewing
/// 3. No complex sync states - just synced/pending
/// 4. Optimistic UI updates with proper error handling
class FollowRepository {
  final FollowRemote _followRemote;
  final FollowDao _followDao;
  final UserDao _userDao;
  final NetworkInfo _networkInfo;

  FollowRepository(
    this._followRemote,
    this._followDao,
    this._userDao,
    this._networkInfo,
  );

  /// Generate consistent document ID
  String _generateDocumentId(String followerId, String followingId) {
    final combined = '${followerId}_$followingId';
    final bytes = utf8.encode(combined);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  // ==================== FOLLOW ====================

  /// Follow a user
  /// Returns null on success, Failure on error
  Future<Failure?> follow(String followerId, String followingId) async {
    if (followerId == followingId) {
      return Failure.validation('Cannot follow yourself');
    }

    final documentId = _generateDocumentId(followerId, followingId);
    final now = DateTime.now();

    // Create local record first (optimistic)
    final follow = FollowModel(
      id: documentId,
      followerId: followerId,
      followingId: followingId,
      createdAt: now,
      syncStatus: SyncStatus.pending,
      lastModifiedAt: now.millisecondsSinceEpoch,
    );

    try {
      await _followDao.insert(follow);
      AppLogger.debug('Follow: Saved locally $followerId -> $followingId');

      // Try to sync to server
      if (await _networkInfo.isConnected) {
        try {
          await _followRemote.follow(followerId, followingId);
          await _followDao.markAsSynced(documentId);
          AppLogger.debug('Follow: Synced to server');
        } catch (e) {
          // Server failed but we have local record - will retry later
          AppLogger.debug('Follow: Server sync failed, will retry: $e');
        }
      }

      return null;
    } catch (e) {
      AppLogger.logError('FollowRepository', 'follow', e);
      return Failure.unknown(e.toString());
    }
  }

  // ==================== UNFOLLOW ====================

  /// Unfollow a user
  Future<Failure?> unfollow(String followerId, String followingId) async {
    final documentId = _generateDocumentId(followerId, followingId);

    try {
      // Delete locally first (optimistic)
      await _followDao.delete(documentId);
      AppLogger.debug('Unfollow: Deleted locally $followerId -> $followingId');

      // Sync to server
      if (await _networkInfo.isConnected) {
        try {
          await _followRemote.unfollow(followerId, followingId);
          AppLogger.debug('Unfollow: Synced to server');
        } catch (e) {
          AppLogger.debug('Unfollow: Server sync failed: $e');
          // Record is already deleted locally, server will catch up
        }
      }

      return null;
    } catch (e) {
      AppLogger.logError('FollowRepository', 'unfollow', e);
      return Failure.unknown(e.toString());
    }
  }

  // ==================== CHECK FOLLOW STATUS ====================

  /// Check if user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      // Check server first if online
      if (await _networkInfo.isConnected) {
        try {
          return await _followRemote.isFollowing(followerId, followingId);
        } catch (e) {
          AppLogger.debug('isFollowing: Server check failed, using local: $e');
        }
      }

      // Fallback to local
      final documentId = _generateDocumentId(followerId, followingId);
      final follow = await _followDao.getById(documentId);
      return follow != null;
    } catch (e) {
      AppLogger.logError('FollowRepository', 'isFollowing', e);
      return false;
    }
  }

  // ==================== GET FOLLOWERS ====================

  /// Get list of users who follow the given user
  Future<({List<UserModel> followers, Failure? failure})> getFollowers(
    String userId,
  ) async {
    try {
      if (await _networkInfo.isConnected) {
        // Fetch from server
        final followers = await _followRemote.getFollowers(userId);
        AppLogger.debug('getFollowers: Server returned ${followers.length} followers');

        // Update local cache
        await _cacheFollowers(userId, followers);

        return (followers: followers, failure: null);
      }

      // Offline: return cached data
      return (followers: await _getCachedFollowers(userId), failure: null);
    } catch (e) {
      AppLogger.logError('FollowRepository', 'getFollowers', e);
      // Return cached data on error
      final cached = await _getCachedFollowers(userId);
      return (followers: cached, failure: Failure.unknown(e.toString()));
    }
  }

  // ==================== GET FOLLOWING ====================

  /// Get list of users that the given user is following
  Future<({List<UserModel> following, Failure? failure})> getFollowing(
    String userId,
  ) async {
    try {
      if (await _networkInfo.isConnected) {
        // Fetch from server
        final following = await _followRemote.getFollowing(userId);
        AppLogger.debug('getFollowing: Server returned ${following.length} following');

        // Update local cache
        await _cacheFollowing(userId, following);

        return (following: following, failure: null);
      }

      // Offline: return cached data
      return (following: await _getCachedFollowing(userId), failure: null);
    } catch (e) {
      AppLogger.logError('FollowRepository', 'getFollowing', e);
      // Return cached data on error
      final cached = await _getCachedFollowing(userId);
      return (following: cached, failure: Failure.unknown(e.toString()));
    }
  }

  // ==================== COUNTS ====================

  Future<int> getFollowerCount(String userId) async {
    try {
      if (await _networkInfo.isConnected) {
        return await _followRemote.getFollowerCount(userId);
      }
      return await _followDao.getFollowerCount(userId);
    } catch (e) {
      AppLogger.logError('FollowRepository', 'getFollowerCount', e);
      return await _followDao.getFollowerCount(userId);
    }
  }

  Future<int> getFollowingCount(String userId) async {
    try {
      if (await _networkInfo.isConnected) {
        return await _followRemote.getFollowingCount(userId);
      }
      return await _followDao.getFollowingCount(userId);
    } catch (e) {
      AppLogger.logError('FollowRepository', 'getFollowingCount', e);
      return await _followDao.getFollowingCount(userId);
    }
  }

  // ==================== SYNC PENDING ====================

  /// Sync any pending follow/unfollow actions
  /// Called by provider without parameters
  Future<void> syncPendingChanges() async {
    if (!await _networkInfo.isConnected) return;

    try {
      // Get pending follows
      final pendingFollows = await _followDao.getPendingSync();
      
      for (final follow in pendingFollows) {
        try {
          await _followRemote.follow(follow.followerId, follow.followingId);
          await _followDao.markAsSynced(follow.id);
          AppLogger.debug('Synced pending follow: ${follow.id}');
        } catch (e) {
          AppLogger.debug('Failed to sync follow ${follow.id}: $e');
        }
      }
    } catch (e) {
      AppLogger.logError('FollowRepository', 'syncPendingChanges', e);
    }
  }

  // ==================== CACHE HELPERS ====================

  Future<void> _cacheFollowers(String userId, List<UserModel> followers) async {
    try {
      // Cache user profiles
      for (final user in followers) {
        await _userDao.insert(user);
      }

      // Get existing local followers
      final existingFollows = await _followDao.getFollowers(userId);
      final existingIds = existingFollows.map((f) => f.followerId).toSet();
      final serverIds = followers.map((u) => u.id).toSet();

      // Add new followers from server
      for (final user in followers) {
        if (!existingIds.contains(user.id)) {
          final documentId = _generateDocumentId(user.id, userId);
          final follow = FollowModel(
            id: documentId,
            followerId: user.id,
            followingId: userId,
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
            lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await _followDao.insert(follow);
        }
      }

      // Remove followers that no longer exist on server (except pending)
      for (final existing in existingFollows) {
        if (!serverIds.contains(existing.followerId) && 
            existing.syncStatus == SyncStatus.synced) {
          await _followDao.delete(existing.id);
        }
      }
    } catch (e) {
      AppLogger.debug('Cache followers error: $e');
    }
  }

  Future<void> _cacheFollowing(String userId, List<UserModel> following) async {
    try {
      // Cache user profiles
      for (final user in following) {
        await _userDao.insert(user);
      }

      // Get existing local following
      final existingFollows = await _followDao.getFollowing(userId);
      final existingIds = existingFollows.map((f) => f.followingId).toSet();
      final serverIds = following.map((u) => u.id).toSet();

      // Add new following from server
      for (final user in following) {
        if (!existingIds.contains(user.id)) {
          final documentId = _generateDocumentId(userId, user.id);
          final follow = FollowModel(
            id: documentId,
            followerId: userId,
            followingId: user.id,
            createdAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
            lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await _followDao.insert(follow);
        }
      }

      // Remove following that no longer exist on server (except pending)
      for (final existing in existingFollows) {
        if (!serverIds.contains(existing.followingId) && 
            existing.syncStatus == SyncStatus.synced) {
          await _followDao.delete(existing.id);
        }
      }
    } catch (e) {
      AppLogger.debug('Cache following error: $e');
    }
  }

  Future<List<UserModel>> _getCachedFollowers(String userId) async {
    final follows = await _followDao.getFollowers(userId);
    final users = <UserModel>[];
    for (final follow in follows) {
      final user = await _userDao.getById(follow.followerId);
      if (user != null) users.add(user);
    }
    return users;
  }

  Future<List<UserModel>> _getCachedFollowing(String userId) async {
    final follows = await _followDao.getFollowing(userId);
    final users = <UserModel>[];
    for (final follow in follows) {
      final user = await _userDao.getById(follow.followingId);
      if (user != null) users.add(user);
    }
    return users;
  }

  // ==================== SEARCH ====================

  /// Search users - delegates to remote
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (await _networkInfo.isConnected) {
        // Use user remote for search instead
        final users = await _userDao.searchByName(query);
        return users;
      }
      return await _userDao.searchByName(query);
    } catch (e) {
      AppLogger.logError('FollowRepository', 'searchUsers', e);
      return [];
    }
  }

  // ==================== MUTUAL FOLLOW ====================

  /// Check if two users follow each other
  Future<bool> isMutualFollow(String userId1, String userId2) async {
    try {
      final follows1 = await isFollowing(userId1, userId2);
      final follows2 = await isFollowing(userId2, userId1);
      return follows1 && follows2;
    } catch (e) {
      AppLogger.logError('FollowRepository', 'isMutualFollow', e);
      return false;
    }
  }
}
