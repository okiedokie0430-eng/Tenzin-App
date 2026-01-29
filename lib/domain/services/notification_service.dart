import 'package:flutter/services.dart';
import '../../core/utils/logger.dart';

/// Local notification service for learning reminders and chat messages
/// Uses platform channels for native notification support
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _channel = MethodChannel('com.tenzin.app/notifications');
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Request notification permissions on Android 13+
      await _requestPermissions();
      _isInitialized = true;
      AppLogger.info('NotificationService initialized successfully');
    } catch (e) {
      AppLogger.error('NotificationService initialize error', error: e);
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } catch (e) {
      // Fallback - assume permission granted on older Android versions
      AppLogger.warning('Permission request failed, assuming granted', error: e);
      return true;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('areNotificationsEnabled');
      return result ?? true;
    } catch (e) {
      return true; // Default to true if check fails
    }
  }

  /// Schedule daily learning reminder
  /// [hour] and [minute] specify the time of day for the reminder
  Future<void> scheduleDailyReminder({
    int hour = 19, // Default 7 PM
    int minute = 0,
    String? title,
    String? body,
  }) async {
    try {
      await _channel.invokeMethod('scheduleDailyReminder', {
        'hour': hour,
        'minute': minute,
        'title': title ?? 'Тензин сануулга 📚',
        'body': body ?? 'Өнөөдрийн хичээлээ хийхээ мартсан уу? Эхлэхэд хэзээ ч орой биш!',
      });
      AppLogger.info('Daily reminder scheduled for $hour:$minute');
    } catch (e) {
      AppLogger.error('scheduleDailyReminder error', error: e);
    }
  }

  /// Schedule randomized reminders between [minMinutes] and [maxMinutes].
  /// The system will schedule the next notification after each fires.
  /// Pass `minMinutes` >= 30 and `maxMinutes` <= 180 to meet requirements.
  Future<void> scheduleRandomizedReminders({
    int minMinutes = 30,
    int maxMinutes = 180,
    String? title,
    String? body,
  }) async {
    try {
      if (minMinutes < 1) minMinutes = 1;
      if (maxMinutes < minMinutes) maxMinutes = minMinutes;
      await _channel.invokeMethod('scheduleRandomizedReminders', {
        'minMinutes': minMinutes,
        'maxMinutes': maxMinutes,
        'title': title ?? 'Тензин сануулга 📚',
        'body': body ?? getRandomMotivationalMessage(),
      });
      AppLogger.info('Scheduled randomized reminders $minMinutes..$maxMinutes minutes');
    } catch (e) {
      AppLogger.error('scheduleRandomizedReminders error', error: e);
    }
  }

  /// Cancel randomized reminders
  Future<void> cancelRandomizedReminders() async {
    try {
      await _channel.invokeMethod('cancelRandomizedReminders');
      AppLogger.info('Cancelled randomized reminders');
    } catch (e) {
      AppLogger.error('cancelRandomizedReminders error', error: e);
    }
  }

  /// Get next randomized reminder timestamp (milliseconds since epoch) if scheduled
  Future<int?> getNextRandomizedReminder() async {
    try {
      final result = await _channel.invokeMethod<int?>('getNextRandomizedReminder');
      return result;
    } catch (e) {
      AppLogger.error('getNextRandomizedReminder error', error: e);
      return null;
    }
  }

  /// Cancel daily learning reminder
  Future<void> cancelDailyReminder() async {
    try {
      await _channel.invokeMethod('cancelDailyReminder');
      AppLogger.info('Daily reminder cancelled');
    } catch (e) {
      AppLogger.error('cancelDailyReminder error', error: e);
    }
  }

  /// Send an immediate test notification
  Future<void> sendTestNotification() async {
    try {
      await _channel.invokeMethod('showTestNotification', {
        'title': 'Тензин сануулга 📚',
        'body': 'Тест мэдэгдэл амжилттай! Таны сануулга идэвхтэй байна.',
      });
      AppLogger.info('Test notification sent');
    } catch (e) {
      AppLogger.error('sendTestNotification error', error: e);
      // Show fallback snackbar notification
      rethrow;
    }
  }

  /// Show chat message notification
  /// [senderId] - ID of the sender (for navigation)
  /// [senderName] - Display name of the sender
  /// [senderAvatarUrl] - Avatar URL (optional)
  /// [messagePreview] - Message text preview
  Future<void> showChatNotification({
    required String senderId,
    required String senderName,
    String? senderAvatarUrl,
    required String messagePreview,
  }) async {
    try {
      await _channel.invokeMethod('showChatNotification', {
        'senderId': senderId,
        'senderName': senderName,
        'senderAvatarUrl': senderAvatarUrl,
        'messagePreview': messagePreview,
        'title': senderName,
        'body': messagePreview,
      });
      AppLogger.info('Chat notification sent for $senderName');
    } catch (e) {
      AppLogger.error('showChatNotification error', error: e);
    }
  }

  /// Schedule streak reminder notification
  /// Reminds user to maintain their learning streak
  Future<void> scheduleStreakReminder({
    int currentStreak = 0,
  }) async {
    try {
      String body;
      if (currentStreak > 0) {
        body = 'Таны $currentStreak хоногийн цуврал аялал алдагдахгүйн тулд өнөөдөр хичээл хий!';
      } else {
        body = 'Шинэ цуврал аялал эхлүүлэхэд бэлэн үү? Хамтдаа эхэлцгээе!';
      }
      
      await _channel.invokeMethod('scheduleStreakReminder', {
        'title': 'Цуврал аялалаа хадгал! 🔥',
        'body': body,
        'streakDays': currentStreak,
      });
    } catch (e) {
      AppLogger.error('scheduleStreakReminder error', error: e);
    }
  }

  /// Update reminder settings
  Future<void> updateReminderSettings({
    required bool enabled,
    int hour = 19,
    int minute = 0,
  }) async {
    if (enabled) {
      await scheduleDailyReminder(hour: hour, minute: minute);
    } else {
      await cancelDailyReminder();
    }
  }

  /// Get list of motivational messages for notifications
  static List<String> get motivationalMessages => [
    'Өнөөдрийн хичээлээ хийхээ мартсан уу? Эхлэхэд хэзээ ч орой биш!',
    'Тибет хэл өдөр бүр хөгжиж байна. Таныг хүлээж байна!',
    '5 минутын хичээл ч гэсэн ахиц дэвшил юм. Эхлэцгээе!',
    'Таны цуврал аялал тасрах гэж байна! Хамгаалахын тулд хичээл хий.',
    'Шинэ үг, шинэ ертөнц. Өнөөдөр юу сурах вэ?',
    'Хамгийн сайн цаг бол одоо. Хичээлээ эхлүүлцгээе!',
    'Өчигдрөөс илүү ухаалаг болохын тулд өнөөдөр суръя!',
  ];

  /// Get a random motivational message
  static String getRandomMotivationalMessage() {
    final messages = motivationalMessages;
    final index = DateTime.now().millisecondsSinceEpoch % messages.length;
    return messages[index];
  }
}

/// Notification settings model
class NotificationSettings {
  final bool enabled;
  final int reminderHour;
  final int reminderMinute;
  final bool streakReminder;

  const NotificationSettings({
    this.enabled = true,
    this.reminderHour = 19,
    this.reminderMinute = 0,
    this.streakReminder = true,
  });

  NotificationSettings copyWith({
    bool? enabled,
    int? reminderHour,
    int? reminderMinute,
    bool? streakReminder,
  }) {
    return NotificationSettings(
      enabled: enabled ?? this.enabled,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      streakReminder: streakReminder ?? this.streakReminder,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enabled': enabled,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'streak_reminder': streakReminder,
    };
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enabled: map['enabled'] as bool? ?? true,
      reminderHour: map['reminder_hour'] as int? ?? 19,
      reminderMinute: map['reminder_minute'] as int? ?? 0,
      streakReminder: map['streak_reminder'] as bool? ?? true,
    );
  }
}
