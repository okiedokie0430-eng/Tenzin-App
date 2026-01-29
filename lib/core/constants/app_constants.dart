class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Tenzin';
  static const String appVersion = '1.0.0';

  // Appwrite Configuration
  static const String appwriteEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String appwriteProjectId = '69536e3f003c0ac930bd';
  static const String appwriteDatabaseId = 'collection';

  // Appwrite Collection IDs
  static const String collectionUserProfiles = 'user_profiles';
  static const String collectionUserSettings = 'user_settings';
  static const String collectionUserProgress = 'user_progress';
  static const String collectionHeartState = 'heart_state';
  static const String collectionFollows = 'follows';
  static const String collectionMessages = 'messages';
  static const String collectionAchievements = 'achievements';
  static const String collectionLeaderboard = 'leaderboard';
  static const String collectionNotifications = 'notifications';
  static const String collectionSupportMessages = 'support_messages';

  // Heart System
  static const int maxHearts = 5;
  static const int heartRegenerationMinutes = 20;
  static const int fullHeartRegenerationMinutes = 100; // 5 hearts * 20 minutes

  // Sync Configuration
  static const int syncBatchSize = 50;
  static const int syncTimeoutSeconds = 30;
  static const int minSyncIntervalMinutes = 5;
  static const int maxRetryAttempts = 10;

  // Performance Targets
  static const int targetFrameRateMs = 16; // 60 FPS
  static const int maxMemoryUsageMb = 400;
  static const int coldStartTargetMs = 2000;

  // Database
  static const String databaseName = 'Tenzin Collection';
  static const int databaseVersion = 8;  // Tarni schema changed to support multiple entries

  // Session
  static const int sessionInactiveDays = 7;

  // XP System
  static const int xpPerCorrectAnswer = 1;
  static const int xpBonusShortLesson = 10; // <= 5 words
  static const int xpBonusMediumLesson = 15; // 6-10 words
  static const int xpBonusLongLesson = 20; // > 10 words

  // Leaderboard
  static const int leaderboardTopCount = 100;

  // Messages
  static const int maxMessageLength = 1000;

  // Secure Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keySessionId = 'session_id';
  static const String keyLastSyncAt = 'last_sync_at';
  // Heart State Keys (per-user)
  static const String keyHeartCurrentPrefix = 'heart_current_'; // + userId
  static const String keyHeartLastChangePrefix = 'heart_last_change_'; // + userId (ISO string)
}
