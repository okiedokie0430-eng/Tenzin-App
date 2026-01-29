import '../../data/models/notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/error/failures.dart';

class GetNotificationsUseCase {
  final NotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  Future<({List<NotificationModel> notifications, Failure? failure})> call(
    String userId, {
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getUserNotifications(
      userId,
      limit: limit,
      offset: offset,
    );
  }
}

class MarkNotificationAsReadUseCase {
  final NotificationRepository _repository;

  MarkNotificationAsReadUseCase(this._repository);

  Future<Failure?> call(String notificationId) {
    return _repository.markAsRead(notificationId);
  }
}

class MarkAllNotificationsAsReadUseCase {
  final NotificationRepository _repository;

  MarkAllNotificationsAsReadUseCase(this._repository);

  Future<Failure?> call(String userId) {
    return _repository.markAllAsRead(userId);
  }
}

class DeleteNotificationUseCase {
  final NotificationRepository _repository;

  DeleteNotificationUseCase(this._repository);

  Future<Failure?> call(String notificationId) {
    return _repository.deleteNotification(notificationId);
  }
}

class DeleteAllNotificationsUseCase {
  final NotificationRepository _repository;

  DeleteAllNotificationsUseCase(this._repository);

  Future<Failure?> call(String userId) {
    return _repository.deleteAllNotifications(userId);
  }
}

class GetNotificationUnreadCountUseCase {
  final NotificationRepository _repository;

  GetNotificationUnreadCountUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getUnreadCount(userId);
  }
}

class CreateLocalNotificationUseCase {
  final NotificationRepository _repository;

  CreateLocalNotificationUseCase(this._repository);

  Future<({NotificationModel? notification, Failure? failure})> call({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
  }) {
    return _repository.createLocalNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
    );
  }
}
