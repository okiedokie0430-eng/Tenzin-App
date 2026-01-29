import '../../data/models/heart_state.dart';
import '../../data/repositories/heart_repository.dart';
import '../../core/error/failures.dart';

class GetHeartStateUseCase {
  final HeartRepository _repository;

  GetHeartStateUseCase(this._repository);

  Future<({HeartStateModel? heartState, Failure? failure})> call(
    String userId,
  ) {
    return _repository.getHeartState(userId);
  }
}

class UseHeartUseCase {
  final HeartRepository _repository;

  UseHeartUseCase(this._repository);

  Future<({HeartStateModel? heartState, Failure? failure})> call(
    String userId,
  ) {
    return _repository.useHeart(userId);
  }
}

class RefillHeartsUseCase {
  final HeartRepository _repository;

  RefillHeartsUseCase(this._repository);

  Future<({HeartStateModel? heartState, Failure? failure})> call(
    String userId,
  ) {
    return _repository.refillHearts(userId);
  }
}

class GetCurrentHeartsUseCase {
  final HeartRepository _repository;

  GetCurrentHeartsUseCase(this._repository);

  Future<int> call(String userId) {
    return _repository.getCurrentHearts(userId);
  }
}

class HasHeartsUseCase {
  final HeartRepository _repository;

  HasHeartsUseCase(this._repository);

  Future<bool> call(String userId) {
    return _repository.hasHearts(userId);
  }
}

class GetTimeUntilNextHeartUseCase {
  final HeartRepository _repository;

  GetTimeUntilNextHeartUseCase(this._repository);

  Future<Duration?> call(String userId) {
    return _repository.getTimeUntilNextHeart(userId);
  }
}

class SyncHeartStateUseCase {
  final HeartRepository _repository;

  SyncHeartStateUseCase(this._repository);

  Future<void> call(String userId, DateTime lastSyncTime) {
    return _repository.syncHeartState(userId, lastSyncTime);
  }
}

class SyncPendingHeartStateUseCase {
  final HeartRepository _repository;

  SyncPendingHeartStateUseCase(this._repository);

  Future<void> call() {
    return _repository.syncPendingHeartState();
  }
}
