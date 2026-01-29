import 'package:appwrite/appwrite.dart';
import '../models/support_message.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class SupportRemote {
  final AppwriteClient _appwriteClient;

  SupportRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  Future<List<SupportMessageModel>> getUserMessages(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.supportMessagesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('created_at'),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => SupportMessageModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('SupportRemote', 'getUserMessages', e);
      throw ServerException(e.message ?? 'Failed to fetch messages');
    }
  }

  Future<SupportMessageModel?> getMessageById(String messageId) async {
    try {
      final doc = await _databases.getDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.supportMessagesCollection,
        documentId: messageId,
      );
      return SupportMessageModel.fromMap(doc.data);
    } on AppwriteException catch (e) {
      if (e.code == 404) return null;
      AppLogger.logError('SupportRemote', 'getMessageById', e);
      throw ServerException(e.message ?? 'Failed to fetch message');
    }
  }

  Future<SupportMessageModel> sendMessage(SupportMessageModel message) async {
    try {
      final data = message.toMap()..remove('id');
      final doc = await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.supportMessagesCollection,
        documentId: message.id,
        data: data,
      );
      return SupportMessageModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      AppLogger.logError('SupportRemote', 'sendMessage', e);
      throw ServerException(e.message ?? 'Failed to send message');
    }
  }

  Future<List<SupportMessageModel>> getUnreadReplies(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.supportMessagesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('is_from_admin', true),
          Query.equal('is_read', false),
          Query.orderDesc('created_at'),
        ],
      );

      return response.documents
          .map((doc) => SupportMessageModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('SupportRemote', 'getUnreadReplies', e);
      throw ServerException(e.message ?? 'Failed to fetch unread replies');
    }
  }

  Future<void> markAsRead(String messageId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.supportMessagesCollection,
        documentId: messageId,
        data: {'is_read': true},
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('SupportRemote', 'markAsRead', e);
      throw ServerException(e.message ?? 'Failed to mark message as read');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final unread = await getUnreadReplies(userId);
      for (final message in unread) {
        await markAsRead(message.id);
      }
    } on AppwriteException catch (e) {
      AppLogger.logError('SupportRemote', 'markAllAsRead', e);
      throw ServerException(e.message ?? 'Failed to mark messages as read');
    }
  }

  Future<List<SupportMessageModel>> getMessagesUpdatedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.supportMessagesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThan('created_at', timestamp.millisecondsSinceEpoch),
          Query.limit(50),
        ],
      );

      return response.documents
          .map((doc) => SupportMessageModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('SupportRemote', 'getMessagesUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated messages');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.supportMessagesCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.equal('is_from_admin', true),
          Query.equal('is_read', false),
          Query.limit(1),
        ],
      );
      return response.total;
    } on AppwriteException catch (e) {
      AppLogger.logError('SupportRemote', 'getUnreadCount', e);
      throw ServerException(e.message ?? 'Failed to get unread count');
    }
  }
}
