import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../core/utils/logger.dart';

/// FCM push notification service
/// Handles Firebase Cloud Messaging for chat and reminder notifications
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging? _messaging;
  bool _isInitialized = false;
  String? _fcmToken;
  
  /// Get FCM token
  String? get fcmToken => _fcmToken;
  
  /// Callback for when a notification is received while app is in foreground
  void Function(RemoteMessage)? onMessageReceived;
  
  /// Callback for when user taps on a notification
  void Function(RemoteMessage)? onNotificationTapped;

  /// Check if Firebase is initialized
  bool get _isFirebaseInitialized {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Initialize FCM service
  /// Call this after Firebase.initializeApp() and after first login
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Check if Firebase is available
    if (!_isFirebaseInitialized) {
      AppLogger.warning('Firebase not initialized, skipping FCM setup');
      return;
    }
    
    try {
      _messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      AppLogger.info('FCM notification permission: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _fcmToken = await _messaging!.getToken();
        AppLogger.info('FCM Token: $_fcmToken');
        
        // Listen for token refresh
        _messaging!.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          AppLogger.info('FCM Token refreshed: $newToken');
          // TODO: Update token on server
        });
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          AppLogger.info('Foreground message received: ${message.notification?.title}');
          onMessageReceived?.call(message);
          _handleForegroundMessage(message);
        });
        
        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          AppLogger.info('Notification tapped: ${message.notification?.title}');
          onNotificationTapped?.call(message);
          _handleNotificationTap(message);
        });
        
        // Check if app was opened from a terminated state
        final initialMessage = await _messaging!.getInitialMessage();
        if (initialMessage != null) {
          AppLogger.info('App opened from notification: ${initialMessage.notification?.title}');
          onNotificationTapped?.call(initialMessage);
          _handleNotificationTap(initialMessage);
        }
        
        _isInitialized = true;
        AppLogger.info('FCM service initialized successfully');
      } else {
        AppLogger.warning('FCM permission not granted');
      }
    } catch (e) {
      AppLogger.error('FCM initialization error', error: e);
    }
  }

  /// Handle foreground message - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    
    // The notification is automatically shown by the system
    // Additional handling can be done here
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    // Navigation data is available in message.data
    // Extract type and targetId if needed: message.data['type'], message.data['targetId']
    // Navigation will be handled by the onNotificationTapped callback
    // The parent widget should set onNotificationTapped to handle navigation
  }

  /// Subscribe to a topic for group notifications
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.subscribeToTopic(topic);
      AppLogger.info('Subscribed to topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to subscribe to topic: $topic', error: e);
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;
    try {
      await _messaging!.unsubscribeFromTopic(topic);
      AppLogger.info('Unsubscribed from topic: $topic');
    } catch (e) {
      AppLogger.error('Failed to unsubscribe from topic: $topic', error: e);
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (_messaging == null) return false;
    try {
      final settings = await _messaging!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (_messaging == null) return false;
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
             settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      return false;
    }
  }
}

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    AppLogger.info('Background message received: ${message.notification?.title}');
  } catch (e) {
    // Silently fail if Firebase not available
  }
}
