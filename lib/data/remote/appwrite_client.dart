import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import '../../core/constants/app_constants.dart';

class AppwriteClient {
  static AppwriteClient? _instance;
  late final Client _client;
  late final Account _account;
  late final Databases _databases;
  late final Storage _storage;
  late final Realtime _realtime;

  AppwriteClient._internal() {
    _client = Client()
      ..setEndpoint(AppConstants.appwriteEndpoint)
      ..setProject(AppConstants.appwriteProjectId)
      ..setSelfSigned(status: true);

    _account = Account(_client);
    _databases = Databases(_client);
    _storage = Storage(_client);
    _realtime = Realtime(_client);
  }

  factory AppwriteClient() {
    _instance ??= AppwriteClient._internal();
    return _instance!;
  }

  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Storage get storage => _storage;
  Realtime get realtime => _realtime;

  static const String databaseId = AppConstants.appwriteDatabaseId;

  // Collection IDs - must match Appwrite console collection IDs
  static const String usersCollection = AppConstants.collectionUserProfiles;
  static const String lessonsCollection = 'lessons';
  static const String lessonWordsCollection = 'lesson_words';
  static const String progressCollection = AppConstants.collectionUserProgress;
  static const String heartStatesCollection = AppConstants.collectionHeartState;
  static const String supportMessagesCollection = AppConstants.collectionSupportMessages;
  static const String followsCollection = AppConstants.collectionFollows;
  static const String messagesCollection = AppConstants.collectionMessages;
  static const String notificationsCollection = AppConstants.collectionNotifications;
  static const String achievementsCollection = AppConstants.collectionAchievements;
  static const String userAchievementsCollection = AppConstants.collectionAchievements;
  static const String leaderboardCollection = AppConstants.collectionLeaderboard;
  static const String userSettingsCollection = AppConstants.collectionUserSettings;

  // Storage bucket IDs
  static const String profileImagesBucket = 'profile_images';
  static const String lessonImagesBucket = 'lesson_images';
  static const String audioBucket = 'audio_files';

  Future<models.User?> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  void dispose() {
    _instance = null;
  }
}
