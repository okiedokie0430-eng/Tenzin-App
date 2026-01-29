import '../../data/models/user.dart';
import '../../data/repositories/follow_repository.dart';
import '../../core/error/failures.dart';

class FollowUserUseCase {
  final FollowRepository _repository;

  FollowUserUseCase(this._repository);

  Future<Failure?> call(String followerId, String followingId) {
    return _repository.follow(followerId, followingId);
  }
}

class UnfollowUserUseCase {
  final FollowRepository _repository;

  UnfollowUserUseCase(this._repository);

  Future<Failure?> call(String followerId, String followingId) {
    return _repository.unfollow(followerId, followingId);
  }
}

class IsFollowingUseCase {
  final FollowRepository _repository;

  IsFollowingUseCase(this._repository);

  Future<bool> call(String followerId, String followingId) {
    return _repository.isFollowing(followerId, followingId);
  }
}

class GetFollowersUseCase {
  final FollowRepository _repository;

  GetFollowersUseCase(this._repository);

  Future<({List<UserModel> followers, Failure? failure})> call(String userId) {
    return _repository.getFollowers(userId);
  }
}

class GetFollowingUseCase {
  final FollowRepository _repository;

  GetFollowingUseCase(this._repository);

  Future<({List<UserModel> following, Failure? failure})> call(String userId) {
    return _repository.getFollowing(userId);
  }
}

class GetFollowerCountUseCase {
  final FollowRepository _repository;

  GetFollowerCountUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getFollowerCount(userId);
  }
}

class GetFollowingCountUseCase {
  final FollowRepository _repository;

  GetFollowingCountUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getFollowingCount(userId);
  }
}

class IsMutualFollowUseCase {
  final FollowRepository _repository;

  IsMutualFollowUseCase(this._repository);

  Future<bool> call(String userId1, String userId2) {
    return _repository.isMutualFollow(userId1, userId2);
  }
}
