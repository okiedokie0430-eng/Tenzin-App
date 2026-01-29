import '../models/heart_state.dart';
import '../models/user.dart';
import '../local/daos/heart_dao.dart';
import '../remote/heart_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class HeartRepository {
  final HeartRemote _heartRemote;
  final HeartDao _heartDao;
  final NetworkInfo _networkInfo;

  HeartRepository(this._heartRemote, this._heartDao, this._networkInfo);

  Future<({HeartStateModel? heartState, Failure? failure})> getHeartState(
    String userId,
  ) async {
    try {
      // Local-first: always use local DAO for reads and regeneration.
      // Do NOT perform remote fetches here — syncing happens separately
      // in background so regeneration and UI remain fully local.
      var heartState = await _heartDao.getByUserId(userId);

      // Create initial state if none exists
      if (heartState == null) {
        heartState = HeartStateModel.initial(userId);
        await _heartDao.insert(heartState);
      }

      // Apply regeneration
      final regenerated = heartState.regenerate();
      if (regenerated.currentHearts != heartState.currentHearts) {
        await _heartDao.update(regenerated);
        heartState = regenerated;
      }

      return (heartState: heartState, failure: null);
    } catch (e) {
      AppLogger.logError('HeartRepository', 'getHeartState', e);
      return (heartState: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({HeartStateModel? heartState, Failure? failure})> useHeart(
    String userId,
  ) async {
    try {
      final result = await getHeartState(userId);
      var heartState = result.heartState;
      
      if (heartState == null) {
        return (heartState: null, failure: Failure.heart('Heart state not found'));
      }

      if (heartState.isEmpty) {
        return (heartState: heartState, failure: Failure.heart('No hearts available'));
      }

      heartState = heartState.loseHeart();
      await _heartDao.update(heartState);

      // Sync to remote in background
      _syncHeartStateInBackground(heartState);

      return (heartState: heartState, failure: null);
    } catch (e) {
      AppLogger.logError('HeartRepository', 'useHeart', e);
      return (heartState: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({HeartStateModel? heartState, Failure? failure})> refillHearts(
    String userId,
  ) async {
    try {
      final result = await getHeartState(userId);
      var heartState = result.heartState;
      
      if (heartState == null) {
        return (heartState: null, failure: Failure.heart('Heart state not found'));
      }

      heartState = heartState.refillHearts();
      await _heartDao.update(heartState);

      // Sync to remote in background
      _syncHeartStateInBackground(heartState);

      return (heartState: heartState, failure: null);
    } catch (e) {
      AppLogger.logError('HeartRepository', 'refillHearts', e);
      return (heartState: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({HeartStateModel? heartState, Failure? failure})> updateHeartState(
    HeartStateModel heartState,
  ) async {
    try {
      await _heartDao.update(heartState.copyWith(syncStatus: SyncStatus.pending));
      
      // Sync to remote in background
      _syncHeartStateInBackground(heartState);
      
      return (heartState: heartState, failure: null);
    } catch (e) {
      AppLogger.logError('HeartRepository', 'updateHeartState', e);
      return (heartState: null, failure: Failure.unknown(e.toString()));
    }
  }

  void _syncHeartStateInBackground(HeartStateModel heartState) async {
    try {
      if (!await _networkInfo.isConnected) return;

      await _heartRemote.upsertHeartState(heartState);
      await _heartDao.update(
        heartState.copyWith(syncStatus: SyncStatus.synced),
      );
    } catch (e) {
      AppLogger.logError('HeartRepository', '_syncHeartStateInBackground', e);
    }
  }

  Future<int> getCurrentHearts(String userId) async {
    final result = await getHeartState(userId);
    return result.heartState?.currentHearts ?? 0;
  }

  Future<bool> hasHearts(String userId) async {
    final result = await getHeartState(userId);
    return !(result.heartState?.isEmpty ?? true);
  }

  Future<Duration?> getTimeUntilNextHeart(String userId) async {
    final result = await getHeartState(userId);
    return result.heartState?.timeUntilNextHeart;
  }

  Future<void> syncHeartState(String userId, DateTime lastSyncTime) async {
    try {
      if (!await _networkInfo.isConnected) return;

      final remoteState = await _heartRemote.getHeartStateUpdatedAfter(
        userId,
        lastSyncTime,
      );

      if (remoteState != null) {
        final local = await _heartDao.getByUserId(userId);
        if (local == null || 
            remoteState.lastModifiedAt > local.lastModifiedAt) {
          await _heartDao.insert(
            remoteState.copyWith(syncStatus: SyncStatus.synced),
          );
        }
      }
    } catch (e) {
      AppLogger.logError('HeartRepository', 'syncHeartState', e);
    }
  }

  Future<void> syncPendingHeartState() async {
    try {
      if (!await _networkInfo.isConnected) return;

      final pendingState = await _heartDao.getPendingSync();
      if (pendingState == null) return;
      
      try {
        await _heartRemote.upsertHeartState(pendingState);
        await _heartDao.update(
          pendingState.copyWith(syncStatus: SyncStatus.synced),
        );
      } catch (e) {
        AppLogger.logError('HeartRepository', 'syncPendingHeartState', e);
      }
    } catch (e) {
      AppLogger.logError('HeartRepository', 'syncPendingHeartState', e);
    }
  }
}
