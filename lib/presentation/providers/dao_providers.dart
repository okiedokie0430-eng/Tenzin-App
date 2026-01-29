import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/daos/daos.dart';
import 'core_providers.dart';

// DAO Providers
final userDaoProvider = Provider<UserDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return UserDao(dbHelper);
});

final lessonDaoProvider = Provider<LessonDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return LessonDao(dbHelper);
});

final progressDaoProvider = Provider<ProgressDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ProgressDao(dbHelper);
});

final heartDaoProvider = Provider<HeartDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return HeartDao(dbHelper);
});

final supportDaoProvider = Provider<SupportDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SupportDao(dbHelper);
});

final followDaoProvider = Provider<FollowDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return FollowDao(dbHelper);
});

final notificationDaoProvider = Provider<NotificationDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return NotificationDao(dbHelper);
});

final achievementDaoProvider = Provider<AchievementDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return AchievementDao(dbHelper);
});

final leaderboardDaoProvider = Provider<LeaderboardDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return LeaderboardDao(dbHelper);
});

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SettingsDao(dbHelper);
});

final syncQueueDaoProvider = Provider<SyncQueueDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SyncQueueDao(dbHelper);
});

final tarniDaoProvider = Provider<TarniDao>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return TarniDao(dbHelper);
});
