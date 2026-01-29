import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common.dart';

/// Notifications screen
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мэдэгдлүүд'),
        actions: [
          if (notificationState.notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                final userId = ref.read(currentUserProvider)?.id;
                if (userId != null) {
                  ref.read(notificationProvider.notifier).markAllAsRead(userId);
                }
              },
              child: const Text('Бүгдийг унших'),
            ),
        ],
      ),
      body: notificationState.isLoading
          ? const Center(child: LoadingWidget())
          : notificationState.notifications.isEmpty
              ? const EmptyWidget(
                  icon: Icons.notifications_none,
                  title: 'Мэдэгдэл байхгүй',
                  subtitle: 'Танд шинэ мэдэгдэл ирээгүй байна',
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    final userId = ref.read(currentUserProvider)?.id;
                    if (userId != null) {
                      await ref.read(notificationProvider.notifier).loadNotifications(userId);
                    }
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: notificationState.notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final notification = notificationState.notifications[index];
                      return _NotificationItem(
                        notification: notification,
                        onTap: () {
                          final userId = ref.read(currentUserProvider)?.id;
                          if (userId != null) {
                            ref.read(notificationProvider.notifier)
                                .markAsRead(notification.id, userId);
                          }
                          // Navigate based on notification type
                          _handleNotificationTap(context, notification);
                        },
                        onDismiss: () {
                          final userId = ref.read(currentUserProvider)?.id;
                          if (userId != null) {
                            ref.read(notificationProvider.notifier)
                                .deleteNotification(notification.id, userId);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }

  void _handleNotificationTap(BuildContext context, dynamic notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case 'achievement':
        Navigator.pushNamed(context, '/achievements');
        break;
      case 'follow':
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: notification.data['userId'],
        );
        break;
      case 'leaderboard':
        Navigator.pushNamed(context, '/leaderboard');
        break;
      case 'message':
        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'conversationId': notification.data['conversationId'],
            'otherUserName': notification.data['senderName'],
          },
        );
        break;
      default:
        break;
    }
  }
}

class _NotificationItem extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification.readAt != null;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: ListTile(
        onTap: onTap,
        tileColor: isRead ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        leading: _buildIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: !isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case 'achievement':
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 'follow':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'leaderboard':
        icon = Icons.leaderboard;
        color = Colors.green;
        break;
      case 'message':
        icon = Icons.message;
        color = Colors.purple;
        break;
      case 'heart':
        icon = Icons.favorite;
        color = Colors.red;
        break;
      case 'streak':
        icon = Icons.local_fire_department;
        color = Colors.orange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Дөнгөж сая';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} минутын өмнө';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} цагийн өмнө';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} өдрийн өмнө';
    } else {
      return '${dateTime.year}.${dateTime.month}.${dateTime.day}';
    }
  }
}
