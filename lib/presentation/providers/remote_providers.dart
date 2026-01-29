import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/remote/remote.dart';
import 'core_providers.dart';

// Remote Providers
final authRemoteProvider = Provider<AuthRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return AuthRemote(appwriteClient);
});

final lessonRemoteProvider = Provider<LessonRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return LessonRemote(appwriteClient);
});

final progressRemoteProvider = Provider<ProgressRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return ProgressRemote(appwriteClient);
});

final heartRemoteProvider = Provider<HeartRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return HeartRemote(appwriteClient);
});

final supportRemoteProvider = Provider<SupportRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return SupportRemote(appwriteClient);
});

final followRemoteProvider = Provider<FollowRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return FollowRemote(appwriteClient);
});

final notificationRemoteProvider = Provider<NotificationRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return NotificationRemote(appwriteClient);
});

final achievementRemoteProvider = Provider<AchievementRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return AchievementRemote(appwriteClient);
});

final leaderboardRemoteProvider = Provider<LeaderboardRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return LeaderboardRemote(appwriteClient);
});

final storageRemoteProvider = Provider<StorageRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return StorageRemote(appwriteClient);
});

final settingsRemoteProvider = Provider<SettingsRemote>((ref) {
  final appwriteClient = ref.watch(appwriteClientProvider);
  return SettingsRemote(appwriteClient);
});
