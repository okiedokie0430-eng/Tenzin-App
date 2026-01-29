import 'package:appwrite/appwrite.dart';
import '../models/notification.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class NotificationRemote {
  final AppwriteClient _appwriteClient;

  NotificationRemote(this._appwriteClient);

  Databases get _databases => _appwriteClient.databases;

  Future<List<NotificationModel>> getUserNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.orderDesc('created_at'),
          Query.limit(limit),
          Query.offset(offset),
        ],
      );

      return response.documents
          .map((doc) => NotificationModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'getUserNotifications', e);
      throw ServerException(e.message ?? 'Failed to fetch notifications');
    }
  }

  Future<NotificationModel> createNotification(
    NotificationModel notification,
  ) async {
    try {
      final data = notification.toMap()..remove('id');
      final doc = await _databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        documentId: notification.id,
        data: data,
      );
      return NotificationModel.fromMap({...doc.data, 'id': doc.$id});
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'createNotification', e);
      throw ServerException(e.message ?? 'Failed to create notification');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _databases.updateDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        documentId: notificationId,
        data: {'read_at': DateTime.now().millisecondsSinceEpoch},
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'markAsRead', e);
      throw ServerException(e.message ?? 'Failed to mark as read');
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.isNull('read_at'),
        ],
      );

      for (final doc in response.documents) {
        await _databases.updateDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.notificationsCollection,
          documentId: doc.$id,
          data: {'read_at': DateTime.now().millisecondsSinceEpoch},
        );
      }
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'markAllAsRead', e);
      throw ServerException(e.message ?? 'Failed to mark all as read');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _databases.deleteDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        documentId: notificationId,
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'deleteNotification', e);
      throw ServerException(e.message ?? 'Failed to delete notification');
    }
  }

  Future<void> deleteAllNotifications(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        queries: [
          Query.equal('user_id', userId),
        ],
      );

      for (final doc in response.documents) {
        await _databases.deleteDocument(
          databaseId: AppwriteClient.databaseId,
          collectionId: AppwriteClient.notificationsCollection,
          documentId: doc.$id,
        );
      }
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'deleteAllNotifications', e);
      throw ServerException(e.message ?? 'Failed to delete notifications');
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.isNull('read_at'),
          Query.limit(1),
        ],
      );
      return response.total;
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'getUnreadCount', e);
      throw ServerException(e.message ?? 'Failed to get unread count');
    }
  }

  Future<List<NotificationModel>> getNotificationsUpdatedAfter(
    String userId,
    DateTime timestamp,
  ) async {
    try {
      final response = await _databases.listDocuments(
        databaseId: AppwriteClient.databaseId,
        collectionId: AppwriteClient.notificationsCollection,
        queries: [
          Query.equal('user_id', userId),
          Query.greaterThan('created_at', timestamp.millisecondsSinceEpoch),
          Query.limit(100),
        ],
      );

      return response.documents
          .map((doc) => NotificationModel.fromMap(doc.data))
          .toList();
    } on AppwriteException catch (e) {
      AppLogger.logError('NotificationRemote', 'getNotificationsUpdatedAfter', e);
      throw ServerException(e.message ?? 'Failed to fetch updated notifications');
    }
  }

  RealtimeSubscription subscribeToNotifications(
    String userId,
    void Function(NotificationModel) onNotification,
  ) {
    final subscription = _appwriteClient.realtime.subscribe([
      'databases.${AppwriteClient.databaseId}.collections.${AppwriteClient.notificationsCollection}.documents'
    ]);
    
    subscription.stream.listen((event) {
      if (event.events.contains('databases.*.collections.*.documents.*.create')) {
        final notification = NotificationModel.fromMap(event.payload);
        if (notification.userId == userId) {
          onNotification(notification);
        }
      }
    });
    
    return subscription;
  }
}
