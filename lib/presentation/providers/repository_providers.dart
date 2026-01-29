import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repositories.dart';
import 'core_providers.dart';
import 'dao_providers.dart';
import 'remote_providers.dart';

// Repository Providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authRemote = ref.watch(authRemoteProvider);
  final userDao = ref.watch(userDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return AuthRepository(authRemote, userDao, networkInfo);
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final lessonDao = ref.watch(lessonDaoProvider);
  // Lessons are LOCAL-ONLY - no remote fetching needed
  return LessonRepository(lessonDao);
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final progressRemote = ref.watch(progressRemoteProvider);
  final progressDao = ref.watch(progressDaoProvider);
  final lessonDao = ref.watch(lessonDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return ProgressRepository(
      progressRemote, progressDao, lessonDao, networkInfo);
});

final heartRepositoryProvider = Provider<HeartRepository>((ref) {
  final heartRemote = ref.watch(heartRemoteProvider);
  final heartDao = ref.watch(heartDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return HeartRepository(heartRemote, heartDao, networkInfo);
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final supportRemote = ref.watch(supportRemoteProvider);
  final supportDao = ref.watch(supportDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return SupportRepository(supportRemote, supportDao, networkInfo);
});

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  final followRemote = ref.watch(followRemoteProvider);
  final followDao = ref.watch(followDaoProvider);
  final userDao = ref.watch(userDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return FollowRepository(followRemote, followDao, userDao, networkInfo);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final notificationRemote = ref.watch(notificationRemoteProvider);
  final notificationDao = ref.watch(notificationDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return NotificationRepository(
      notificationRemote, notificationDao, networkInfo);
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  final achievementRemote = ref.watch(achievementRemoteProvider);
  final achievementDao = ref.watch(achievementDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return AchievementRepository(achievementRemote, achievementDao, networkInfo);
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  final leaderboardRemote = ref.watch(leaderboardRemoteProvider);
  final leaderboardDao = ref.watch(leaderboardDaoProvider);
  final userDao = ref.watch(userDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return LeaderboardRepository(leaderboardRemote, leaderboardDao, userDao, networkInfo);
});

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final storageRemote = ref.watch(storageRemoteProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return StorageRepository(storageRemote, networkInfo);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final settingsRemote = ref.watch(settingsRemoteProvider);
  final settingsDao = ref.watch(settingsDaoProvider);
  final networkInfo = ref.watch(networkInfoProvider);
  return SettingsRepository(settingsRemote, settingsDao, networkInfo);
});
