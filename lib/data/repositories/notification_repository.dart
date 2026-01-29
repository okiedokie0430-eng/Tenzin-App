import '../models/notification.dart';
import '../models/user.dart';
import '../local/daos/notification_dao.dart';
import '../remote/notification_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class NotificationRepository {
  final NotificationRemote _notificationRemote;
  final NotificationDao _notificationDao;
  final NetworkInfo _networkInfo;

  NotificationRepository(
    this._notificationRemote,
    this._notificationDao,
    this._networkInfo,
  );

  Future<({List<NotificationModel> notifications, Failure? failure})> 
      getUserNotifications(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      if (await _networkInfo.isConnected) {
        final remoteNotifications = await _notificationRemote.getUserNotifications(
          userId,
          limit: limit,
          offset: offset,
        );
        
        for (final notification in remoteNotifications) {
          await _notificationDao.insert(notification);
        }
      }

      final localNotifications = await _notificationDao.getByUser(
        userId,
        limit: limit,
        offset: offset,
      );

      return (notifications: localNotifications, failure: null);
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'getUserNotifications', e);
      final localNotifications = await _notificationDao.getByUser(
        userId,
        limit: limit,
        offset: offset,
      );
      return (
        notifications: localNotifications,
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  Future<Failure?> markAsRead(String notificationId) async {
    try {
      await _notificationDao.markAsRead(notificationId);

      if (await _networkInfo.isConnected) {
        await _notificationRemote.markAsRead(notificationId);
      }

      return null;
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'markAsRead', e);
      return Failure.unknown(e.toString());
    }
  }

  Future<Failure?> markAllAsRead(String userId) async {
    try {
      await _notificationDao.markAllAsRead(userId);

      if (await _networkInfo.isConnected) {
        await _notificationRemote.markAllAsRead(userId);
      }

      return null;
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'markAllAsRead', e);
      return Failure.unknown(e.toString());
    }
  }

  Future<Failure?> deleteNotification(String notificationId) async {
    try {
      await _notificationDao.delete(notificationId);

      if (await _networkInfo.isConnected) {
        await _notificationRemote.deleteNotification(notificationId);
      }

      return null;
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'deleteNotification', e);
      return Failure.unknown(e.toString());
    }
  }

  Future<Failure?> deleteAllNotifications(String userId) async {
    try {
      await _notificationDao.deleteByUser(userId);

      if (await _networkInfo.isConnected) {
        await _notificationRemote.deleteAllNotifications(userId);
      }

      return null;
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'deleteAllNotifications', e);
      return Failure.unknown(e.toString());
    }
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      return await _notificationDao.getUnreadCount(userId);
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'getUnreadCount', e);
      return 0;
    }
  }

  Future<void> syncNotifications(String userId, DateTime lastSyncTime) async {
    try {
      if (!await _networkInfo.isConnected) return;

      final updatedNotifications = await _notificationRemote
          .getNotificationsUpdatedAfter(userId, lastSyncTime);

      for (final notification in updatedNotifications) {
        await _notificationDao.insert(notification);
      }
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'syncNotifications', e);
    }
  }

  Future<({NotificationModel? notification, Failure? failure})> 
      createLocalNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
  }) async {
    try {
      final now = DateTime.now();
      final notification = NotificationModel(
        id: now.millisecondsSinceEpoch.toString(),
        userId: userId,
        type: type,
        title: title,
        message: body,
        createdAt: now,
        syncStatus: SyncStatus.pending,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      await _notificationDao.insert(notification);
      return (notification: notification, failure: null);
    } catch (e) {
      AppLogger.logError('NotificationRepository', 'createLocalNotification', e);
      return (notification: null, failure: Failure.unknown(e.toString()));
    }
  }
}
