import '../../data/models/achievement.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../core/error/failures.dart';

class GetAllAchievementsUseCase {
  final AchievementRepository _repository;

  GetAllAchievementsUseCase(this._repository);

  Future<({List<AchievementModel> achievements, Failure? failure})> call() {
    return _repository.getAllAchievements();
  }
}

class GetAchievementsWithStatusUseCase {
  final AchievementRepository _repository;

  GetAchievementsWithStatusUseCase(this._repository);

  Future<({List<AchievementWithStatus> achievements, Failure? failure})> call(
    String userId,
  ) {
    return _repository.getAchievementsWithStatus(userId);
  }
}

class UnlockAchievementUseCase {
  final AchievementRepository _repository;

  UnlockAchievementUseCase(this._repository);

  Future<({UserAchievementModel? userAchievement, Failure? failure})> call(
    String userId,
    String achievementId,
  ) {
    return _repository.unlockAchievement(userId, achievementId);
  }
}

class GetUnlockedAchievementCountUseCase {
  final AchievementRepository _repository;

  GetUnlockedAchievementCountUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getUnlockedCount(userId);
  }
}

class CheckAndUnlockAchievementsUseCase {
  final AchievementRepository _repository;

  CheckAndUnlockAchievementsUseCase(this._repository);

  Future<List<AchievementModel>> call({
    required String userId,
    int? currentStreak,
    int? totalXp,
    int? lessonsCompleted,
    int? followersCount,
  }) {
    return _repository.checkAndUnlockAchievements(
      userId: userId,
      currentStreak: currentStreak,
      totalXp: totalXp,
      lessonsCompleted: lessonsCompleted,
      followersCount: followersCount,
    );
  }
}
