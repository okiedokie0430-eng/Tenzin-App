import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:crypto/crypto.dart';
import '../models/follow.dart';
import '../models/user.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class FollowRemote {
  final AppwriteClient _appwriteClient;

  FollowRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  /// Generate a unique documentId from follower and following IDs
  /// Using MD5 hash to ensure max 32 chars (within Appwrite's 36 char limit)
  String _generateDocumentId(String followerId, String followingId) {
    final combined = '${followerId}_$followingId';
    final bytes = utf8.encode(combined);
    final digest = md5.convert(bytes);
    return digest.toString(); // 32 char hex string
  }

  Future<void> follow(String followerId, String followingId) async {
    try {
      final now = DateTime.now();
      final documentId = _generateDocumentId(followerId, followingId);
      final follow = FollowModel(
        id: documentId,
        followerId: followerId,
        followingId: followingId,
        createdAt: now,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        documentId: documentId,
        data: follow.toMap()..remove('id'),
      );
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // Already following
        return;
      }
      AppLogger.logError('FollowRemote', 'follow', e);
      throw ServerException(e.message ?? 'Failed to follow user');
    }
  }

  Future<void> unfollow(String followerId, String followingId) async {
    try {
      final documentId = _generateDocumentId(followerId, followingId);
      await _databases.deleteDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        documentId: documentId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) {
        // Not following anyway
        return;
      }
      AppLogger.logError('FollowRemote', 'unfollow', e);
      throw ServerException(e.message ?? 'Failed to unfollow user');
    }
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final documentId = _generateDocumentId(followerId, followingId);
      await _databases.getDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        documentId: documentId,
      );
      return true;
    } on AppwriteException catch (e) {
      if (e.code == 404) return false;
      AppLogger.logError('FollowRemote', 'isFollowing', e);
      throw ServerException(e.message ?? 'Failed to check follow status');
    }
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        queries: [
          Query.equal('following_id', userId),
          Query.limit(100),
        ],
      );

      AppLogger.debug('getFollowers: Server returned ${response.documents.length} follow documents for user $userId');

      final followerIds = response.documents
          .map((doc) => doc.data['follower_id'] as String)
          .toList();

      AppLogger.debug('getFollowers: Follower IDs: $followerIds');

      if (followerIds.isEmpty) return [];

      final users = <UserModel>[];
      for (final id in followerIds) {
        try {
          final userDoc = await _databases.getDocument(
            databaseId: AppwriteClient.databaseId,
            collectionId: AppwriteClient.usersCollection,
            documentId: id,
          );
          users.add(UserModel.fromMap({...userDoc.data, 'id': userDoc.$id}));
        } catch (e) {
          // Skip if user not found
          AppLogger.debug('getFollowers: Could not fetch user $id: $e');
        }
      }
      AppLogger.debug('getFollowers: Returning ${users.length} users');
      return users;
    } on AppwriteException catch (e) {
      AppLogger.logError('FollowRemote', 'getFollowers', e);
      throw ServerException(e.message ?? 'Failed to fetch followers');
    }
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        queries: [
          Query.equal('follower_id', userId),
          Query.limit(100),
        ],
      );

      final followingIds = response.documents
          .map((doc) => doc.data['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      final users = <UserModel>[];
      for (final id in followingIds) {
        try {
          final userDoc = await _databases.getDocument(
            databaseId: AppwriteClient.databaseId,
            collectionId: AppwriteClient.usersCollection,
            documentId: id,
          );
          users.add(UserModel.fromMap({...userDoc.data, 'id': userDoc.$id}));
        } catch (_) {
          // Skip if user not found
        }
      }
      return users;
    } on AppwriteException catch (e) {
      AppLogger.logError('FollowRemote', 'getFollowing', e);
      throw ServerException(e.message ?? 'Failed to fetch following');
    }
  }

  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        queries: [
          Query.equal('following_id', userId),
          Query.limit(1),
        ],
      );
      return response.total;
    } on AppwriteException catch (e) {
      AppLogger.logError('FollowRemote', 'getFollowerCount', e);
      throw ServerException(e.message ?? 'Failed to get follower count');
    }
  }

  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        queries: [
          Query.equal('follower_id', userId),
          Query.limit(1),
        ],
      );
      return response.total;
    } on AppwriteException catch (e) {
      AppLogger.logError('FollowRemote', 'getFollowingCount', e);
      throw ServerException(e.message ?? 'Failed to get following count');
    }
  }

  Future<List<String>> getMutualFollowers(
    String userId1,
    String userId2,
  ) async {
    try {
      final followers1Response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        queries: [
          Query.equal('following_id', userId1),
          Query.limit(100),
        ],
      );

      final followers2Response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.followsCollection,
        queries: [
          Query.equal('following_id', userId2),
          Query.limit(100),
        ],
      );

      final followers1 = followers1Response.documents
          .map((doc) => doc.data['follower_id'] as String)
          .toSet();

      final followers2 = followers2Response.documents
          .map((doc) => doc.data['follower_id'] as String)
          .toSet();

      return followers1.intersection(followers2).toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('FollowRemote', 'getMutualFollowers', e);
      throw ServerException(e.message ?? 'Failed to get mutual followers');
    }
  }
}
