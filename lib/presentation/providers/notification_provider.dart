import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Notification State
class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;
  final Failure? failure;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.failure,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    Failure? failure,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }

  static const initial = NotificationState();
}

// Notification Notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final Ref _ref;
  bool _isDisposed = false;

  NotificationNotifier(this._ref) : super(NotificationState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(NotificationState Function(NotificationState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadNotifications(String userId) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      
      final result = await repository.getUserNotifications(userId);
      final unreadCount = await repository.getUnreadCount(userId);
      
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        notifications: result.notifications,
        unreadCount: unreadCount,
        failure: result.failure,
      ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        failure: Failure.unknown(e.toString()),
      ));
    }
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    if (_isDisposed) return;
    
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.markAsRead(notificationId);
      
      // Update local state
      final updated = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(
            readAt: DateTime.now(),
            lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
          );
        }
        return n;
      }).toList();

      _safeUpdate((s) => s.copyWith(
        notifications: updated,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
    }
  }

  Future<void> markAllAsRead(String userId) async {
    if (_isDisposed) return;
    
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.markAllAsRead(userId);
      
      // Update local state
      final now = DateTime.now();
      final updated = state.notifications.map((n) {
        return n.copyWith(
          readAt: now,
          lastModifiedAt: now.millisecondsSinceEpoch,
        );
      }).toList();

      _safeUpdate((s) => s.copyWith(notifications: updated, unreadCount: 0));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
    }
  }

  Future<void> deleteNotification(String notificationId, String userId) async {
    if (_isDisposed) return;
    
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.deleteNotification(notificationId);
      
      // Update local state
      final notification = state.notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => state.notifications.first,
      );
      final wasUnread = notification.readAt == null;
      
      final updated = state.notifications.where((n) => n.id != notificationId).toList();
      
      _safeUpdate((s) => s.copyWith(
        notifications: updated,
        unreadCount: wasUnread && state.unreadCount > 0 
            ? state.unreadCount - 1 
            : state.unreadCount,
      ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
    }
  }

  Future<void> deleteAll(String userId) async {
    if (_isDisposed) return;
    
    try {
      final repository = _ref.read(notificationRepositoryProvider);
      await repository.deleteAllNotifications(userId);
      
      _safeUpdate((s) => s.copyWith(notifications: [], unreadCount: 0));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
    }
  }

  Future<void> refresh(String userId) async {
    if (_isDisposed) return;
    await loadNotifications(userId);
  }
}

// Notification Provider
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notifier = NotificationNotifier(ref);
  
  // Auto-load when user changes
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    notifier.loadNotifications(user.id);
  }
  
  return notifier;
});

// Convenience providers
final notificationsListProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(notificationProvider).notifications;
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(unreadNotificationCountProvider) > 0;
});
