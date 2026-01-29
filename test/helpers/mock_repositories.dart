import 'package:mocktail/mocktail.dart';
import 'package:tenzin/data/repositories/auth_repository.dart';
import 'package:tenzin/data/repositories/lesson_repository.dart';
import 'package:tenzin/data/repositories/heart_repository.dart';
import 'package:tenzin/data/repositories/progress_repository.dart';
import 'package:tenzin/data/repositories/achievement_repository.dart';
import 'package:tenzin/data/repositories/settings_repository.dart';
import 'package:tenzin/data/local/database_helper.dart';
import 'package:tenzin/data/remote/appwrite_client.dart';
import 'package:tenzin/core/platform/network_info.dart';

/// Mock Repository классууд
class MockAuthRepository extends Mock implements AuthRepository {}

class MockLessonRepository extends Mock implements LessonRepository {}

class MockHeartRepository extends Mock implements HeartRepository {}

class MockProgressRepository extends Mock implements ProgressRepository {}

class MockAchievementRepository extends Mock implements AchievementRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

/// Mock Service классууд
class MockDatabaseHelper extends Mock implements DatabaseHelper {}

class MockAppwriteClient extends Mock implements AppwriteClient {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

/// Mock Factory
class MockFactory {
  static MockAuthRepository createAuthRepository() => MockAuthRepository();

  static MockLessonRepository createLessonRepository() =>
      MockLessonRepository();

  static MockHeartRepository createHeartRepository() => MockHeartRepository();

  static MockProgressRepository createProgressRepository() =>
      MockProgressRepository();

  static MockAchievementRepository createAchievementRepository() =>
      MockAchievementRepository();

  static MockSettingsRepository createSettingsRepository() =>
      MockSettingsRepository();

  static MockDatabaseHelper createDatabaseHelper() => MockDatabaseHelper();

  static MockAppwriteClient createAppwriteClient() => MockAppwriteClient();

  static MockNetworkInfo createNetworkInfo() => MockNetworkInfo();
}
