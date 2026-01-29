import 'dart:convert';
import '../models/achievement.dart';
import '../models/user.dart';
import '../local/daos/achievement_dao.dart';
import '../remote/achievement_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class AchievementRepository {
  final AchievementRemote _achievementRemote;
  final AchievementDao _achievementDao;
  final NetworkInfo _networkInfo;

  AchievementRepository(
    this._achievementRemote,
    this._achievementDao,
    this._networkInfo,
  );

  Future<({List<AchievementModel> achievements, Failure? failure})> 
      getAllAchievements() async {
    try {
      var achievements = await _achievementDao.getAllAchievements();
      
      if (achievements.isEmpty && await _networkInfo.isConnected) {
        achievements = await _achievementRemote.getAllAchievements();
      }

      return (achievements: achievements, failure: null);
    } catch (e) {
      AppLogger.logError('AchievementRepository', 'getAllAchievements', e);
      final achievements = await _achievementDao.getAllAchievements();
      return (
        achievements: achievements,
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  Future<({List<AchievementWithStatus> achievements, Failure? failure})> 
      getAchievementsWithStatus(String userId) async {
    try {
      var achievements = await _achievementDao.getAchievementsWithStatus(userId);
      
      if (achievements.isEmpty && await _networkInfo.isConnected) {
        achievements = await _achievementRemote.getAchievementsWithStatus(userId);
        
        for (final aws in achievements) {
          if (aws.userAchievement != null) {
            await _achievementDao.insertUserAchievement(aws.userAchievement!);
          }
        }
      }

      return (achievements: achievements, failure: null);
    } catch (e) {
      AppLogger.logError('AchievementRepository', 'getAchievementsWithStatus', e);
      final achievements = await _achievementDao.getAchievementsWithStatus(userId);
      return (
        achievements: achievements,
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  Future<({UserAchievementModel? userAchievement, Failure? failure})> 
      unlockAchievement(String userId, String achievementId) async {
    try {
      // Check if already unlocked
      final existing = await _achievementDao.getUserAchievement(userId, achievementId);
      if (existing != null) {
        return (userAchievement: existing, failure: null);
      }

      final now = DateTime.now();
      final userAchievement = UserAchievementModel(
        id: '${userId}_$achievementId',
        userId: userId,
        achievementId: achievementId,
        unlockedAt: now,
        syncStatus: SyncStatus.pending,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      await _achievementDao.insertUserAchievement(userAchievement);

      if (await _networkInfo.isConnected) {
        try {
          final remoteUserAchievement = await _achievementRemote.unlockAchievement(
            userId,
            achievementId,
          );
          return (userAchievement: remoteUserAchievement, failure: null);
        } catch (e) {
          AppLogger.logWarning('AchievementRepository', 
            'Remote unlock failed, saved locally: $e');
        }
      }

      return (userAchievement: userAchievement, failure: null);
    } catch (e) {
      AppLogger.logError('AchievementRepository', 'unlockAchievement', e);
      return (userAchievement: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<int> getUnlockedCount(String userId) async {
    try {
      return await _achievementDao.getUnlockedCount(userId);
    } catch (e) {
      AppLogger.logError('AchievementRepository', 'getUnlockedCount', e);
      return 0;
    }
  }

  Future<List<AchievementModel>> checkAndUnlockAchievements({
    required String userId,
    int? currentStreak,
    int? totalXp,
    int? lessonsCompleted,
    int? followersCount,
    String? completedTreePath,
    int? leaderboardRank,
    int? wordsLearned,
    bool? perfectLesson,
  }) async {
    final unlockedAchievements = <AchievementModel>[];

    try {
      final achievementsResult = await getAchievementsWithStatus(userId);
      final achievements = achievementsResult.achievements;

      for (final aws in achievements) {
        if (aws.isUnlocked) continue;

        final achievement = aws.achievement;
        final shouldUnlock = _checkUnlockCondition(
          achievement: achievement,
          currentStreak: currentStreak,
          totalXp: totalXp,
          lessonsCompleted: lessonsCompleted,
          followersCount: followersCount,
          completedTreePath: completedTreePath,
          leaderboardRank: leaderboardRank,
          wordsLearned: wordsLearned,
          perfectLesson: perfectLesson,
        );

        if (shouldUnlock) {
          final result = await unlockAchievement(userId, achievement.id);
          if (result.failure == null && result.userAchievement != null) {
            unlockedAchievements.add(achievement);
            AppLogger.info('Achievement unlocked: ${achievement.name}');
          }
        }
      }
    } catch (e) {
      AppLogger.logError('AchievementRepository', 'checkAndUnlockAchievements', e);
    }

    return unlockedAchievements;
  }

  bool _checkUnlockCondition({
    required AchievementModel achievement,
    int? currentStreak,
    int? totalXp,
    int? lessonsCompleted,
    int? followersCount,
    String? completedTreePath,
    int? leaderboardRank,
    int? wordsLearned,
    bool? perfectLesson,
  }) {
    try {
      final criteria = json.decode(achievement.unlockCriteria) as Map<String, dynamic>;
      final type = criteria['type'] as String?;
      final value = criteria['value'] as int? ?? 0;

      switch (type) {
        case 'lesson_count':
          return (lessonsCompleted ?? 0) >= value;

        case 'streak':
        case 'streak_days':
          return (currentStreak ?? 0) >= value;

        case 'total_xp':
          return (totalXp ?? 0) >= value;

        case 'followers':
        case 'follower_count':
          return (followersCount ?? 0) >= value;

        case 'leaderboard_rank':
          // For leaderboard rank, lower is better (rank 1 is top)
          if (leaderboardRank == null || leaderboardRank <= 0) return false;
          return leaderboardRank <= value;

        case 'perfect_lesson':
          return perfectLesson == true;

        case 'words_learned':
          return (wordsLearned ?? 0) >= value;

        case 'category':
          final requiredPath = criteria['tree_path'] as String?;
          if (requiredPath != null && completedTreePath != null) {
            return completedTreePath.startsWith(requiredPath);
          }
          return false;

        default:
          AppLogger.logWarning('AchievementRepository', 
            'Unknown achievement type: $type');
          return false;
      }
    } catch (e) {
      AppLogger.logError('AchievementRepository', '_checkUnlockCondition', e);
      return false;
    }
  }

  Future<void> syncAchievements(String userId) async {
    try {
      if (!await _networkInfo.isConnected) return;

      final remoteAchievements = await _achievementRemote.getUserAchievements(userId);
      
      for (final userAchievement in remoteAchievements) {
        await _achievementDao.insertUserAchievement(
          userAchievement.copyWith(syncStatus: SyncStatus.synced),
        );
      }
    } catch (e) {
      AppLogger.logError('AchievementRepository', 'syncAchievements', e);
    }
  }
}
