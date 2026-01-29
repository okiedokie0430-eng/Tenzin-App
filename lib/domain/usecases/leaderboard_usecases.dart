import '../../data/models/leaderboard.dart';
import '../../data/repositories/leaderboard_repository.dart';
import '../../core/error/failures.dart';

class GetWeeklyLeaderboardUseCase {
  final LeaderboardRepository _repository;

  GetWeeklyLeaderboardUseCase(this._repository);

  Future<({List<LeaderboardEntryModel> entries, Failure? failure})> call({
    int limit = 50,
  }) {
    return _repository.getWeeklyLeaderboard(limit: limit);
  }
}

class GetUserLeaderboardEntryUseCase {
  final LeaderboardRepository _repository;

  GetUserLeaderboardEntryUseCase(this._repository);

  Future<({LeaderboardEntryModel? entry, Failure? failure})> call(
    String userId,
  ) {
    return _repository.getUserEntry(userId);
  }
}

class GetUserRankUseCase {
  final LeaderboardRepository _repository;

  GetUserRankUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getUserRank(userId);
  }
}

class AddXpToLeaderboardUseCase {
  final LeaderboardRepository _repository;

  AddXpToLeaderboardUseCase(this._repository);

  Future<({LeaderboardEntryModel? entry, Failure? failure})> call({
    required String userId,
    required String userName,
    String? profileImageUrl,
    required int xpToAdd,
  }) {
    return _repository.addXp(
      userId: userId,
      userName: userName,
      profileImageUrl: profileImageUrl,
      xpToAdd: xpToAdd,
    );
  }
}

class GetFollowingLeaderboardUseCase {
  final LeaderboardRepository _repository;

  GetFollowingLeaderboardUseCase(this._repository);

  Future<({List<LeaderboardEntryModel> entries, Failure? failure})> call(
    String userId,
    List<String> followingIds,
  ) {
    return _repository.getFollowingLeaderboard(userId, followingIds);
  }
}

class GetHistoricalLeaderboardUseCase {
  final LeaderboardRepository _repository;

  GetHistoricalLeaderboardUseCase(this._repository);

  Future<({List<LeaderboardEntryModel> entries, Failure? failure})> call(
    DateTime weekStart, {
    int limit = 50,
  }) {
    return _repository.getHistoricalLeaderboard(weekStart, limit: limit);
  }
}
