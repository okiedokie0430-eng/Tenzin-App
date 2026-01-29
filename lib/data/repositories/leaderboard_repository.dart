import '../models/leaderboard.dart';
import '../models/user.dart';
import '../local/daos/leaderboard_dao.dart';
import '../local/daos/user_dao.dart';
import '../remote/leaderboard_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class LeaderboardRepository {
  final LeaderboardRemote _leaderboardRemote;
  final LeaderboardDao _leaderboardDao;
  final UserDao _userDao;
  final NetworkInfo _networkInfo;

  LeaderboardRepository(
    this._leaderboardRemote,
    this._leaderboardDao,
    this._userDao,
    this._networkInfo,
  );

  Future<({List<LeaderboardEntryModel> entries, Failure? failure})> 
      getWeeklyLeaderboard({int limit = 50}) async {
    try {
      if (await _networkInfo.isConnected) {
        final remoteEntries = await _leaderboardRemote.getWeeklyLeaderboard(
          limit: limit,
        );
        
        // Cache locally - ensure user profiles exist first
        for (final entry in remoteEntries) {
          try {
            await _userDao.ensureUserExists(entry.odUserId, displayName: entry.displayName);
            await _leaderboardDao.insert(entry);
          } catch (e) {
            AppLogger.logError('LeaderboardRepository', 'getWeeklyLeaderboard.insert', e);
          }
        }

        return (entries: remoteEntries, failure: null);
      }

      final localEntries = await _leaderboardDao.getWeeklyLeaderboard(limit: limit);
      return (entries: localEntries, failure: null);
    } catch (e) {
      AppLogger.logError('LeaderboardRepository', 'getWeeklyLeaderboard', e);
      final localEntries = await _leaderboardDao.getWeeklyLeaderboard(limit: limit);
      return (
        entries: localEntries,
        failure: Failure.unknown(e.toString()),
      );
    }
  }

  Future<({LeaderboardEntryModel? entry, Failure? failure})> getUserEntry(
    String userId,
  ) async {
    try {
      if (await _networkInfo.isConnected) {
        final remoteEntry = await _leaderboardRemote.getUserEntry(userId);
        if (remoteEntry != null) {
          try {
            await _userDao.ensureUserExists(remoteEntry.odUserId, displayName: remoteEntry.displayName);
            await _leaderboardDao.insert(remoteEntry);
          } catch (e) {
            AppLogger.logError('LeaderboardRepository', 'getUserEntry.insert', e);
          }
        }
        return (entry: remoteEntry, failure: null);
      }

      final localEntry = await _leaderboardDao.getCurrentWeekEntry(userId);
      return (entry: localEntry, failure: null);
    } catch (e) {
      AppLogger.logError('LeaderboardRepository', 'getUserEntry', e);
      final localEntry = await _leaderboardDao.getCurrentWeekEntry(userId);
      return (entry: localEntry, failure: Failure.unknown(e.toString()));
    }
  }

  Future<int> getUserRank(String userId) async {
    try {
      if (await _networkInfo.isConnected) {
        return await _leaderboardRemote.getUserRank(userId);
      }
      return await _leaderboardDao.getUserRank(userId) ?? 0;
    } catch (e) {
      AppLogger.logError('LeaderboardRepository', 'getUserRank', e);
      return 0;
    }
  }

  Future<({LeaderboardEntryModel? entry, Failure? failure})> addXp({
    required String userId,
    required int xpToAdd,
    String? userName,
    String? profileImageUrl,
  }) async {
    try {
      // Update local first
      final existingEntry = await _leaderboardDao.getCurrentWeekEntry(userId);
      
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final entry = LeaderboardEntryModel(
        id: existingEntry?.id ?? '${userId}_${weekStartDate.millisecondsSinceEpoch}',
        odUserId: userId,
        weeklyXp: (existingEntry?.weeklyXp ?? 0) + xpToAdd,
        weekStartDate: weekStartDate,
        syncStatus: SyncStatus.pending,
        lastModifiedAt: now.millisecondsSinceEpoch,
        displayName: userName ?? existingEntry?.displayName,
      );

      await _leaderboardDao.insert(entry);

      if (await _networkInfo.isConnected) {
        final remoteEntry = await _leaderboardRemote.updateUserXp(
          userId,
          userName ?? 'User',
          profileImageUrl,
          xpToAdd,
        );
        await _leaderboardDao.insert(remoteEntry.copyWith(syncStatus: SyncStatus.synced));
        return (entry: remoteEntry, failure: null);
      }

      return (entry: entry, failure: null);
    } catch (e) {
      AppLogger.logError('LeaderboardRepository', 'addXp', e);
      return (entry: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({List<LeaderboardEntryModel> entries, Failure? failure})> 
      getFollowingLeaderboard(String userId, List<String> followingIds) async {
    try {
      if (await _networkInfo.isConnected) {
        final entries = await _leaderboardRemote.getFollowingLeaderboard(
          userId,
          followingIds,
        );
        return (entries: entries, failure: null);
      }

      // Fallback to local data - filter by following IDs
      final allEntries = await _leaderboardDao.getWeeklyLeaderboard(limit: 100);
      final filteredEntries = allEntries
          .where((e) => followingIds.contains(e.odUserId) || e.odUserId == userId)
          .toList()
        ..sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));

      // Assign ranks
      final rankedEntries = filteredEntries.asMap().entries.map((e) {
        return e.value.copyWith(rank: e.key + 1);
      }).toList();

      return (entries: rankedEntries, failure: null);
    } catch (e) {
      AppLogger.logError('LeaderboardRepository', 'getFollowingLeaderboard', e);
      return (entries: <LeaderboardEntryModel>[], failure: Failure.unknown(e.toString()));
    }
  }

  Future<({List<LeaderboardEntryModel> entries, Failure? failure})> 
      getHistoricalLeaderboard(DateTime weekStart, {int limit = 50}) async {
    try {
      if (await _networkInfo.isConnected) {
        final entries = await _leaderboardRemote.getHistoricalLeaderboard(
          weekStart,
          limit: limit,
        );
        return (entries: entries, failure: null);
      }

      return (entries: <LeaderboardEntryModel>[], failure: Failure.network());
    } catch (e) {
      AppLogger.logError('LeaderboardRepository', 'getHistoricalLeaderboard', e);
      return (entries: <LeaderboardEntryModel>[], failure: Failure.unknown(e.toString()));
    }
  }

  Future<void> syncPendingEntries() async {
    try {
      if (!await _networkInfo.isConnected) return;

      final pendingEntries = await _leaderboardDao.getPendingSync();
      
      for (final entry in pendingEntries) {
        try {
          // Use setUserXp to SET the absolute value, not add
          // This prevents XP duplication on retry
          await _leaderboardRemote.setUserXp(
            entry.odUserId,
            entry.displayName ?? 'User',
            entry.weeklyXp,
          );
          await _leaderboardDao.markAsSynced(entry.id);
        } catch (e) {
          AppLogger.logError('LeaderboardRepository', 'syncPendingEntries', e);
        }
      }
    } catch (e) {
      AppLogger.logError('LeaderboardRepository', 'syncPendingEntries', e);
    }
  }
}
