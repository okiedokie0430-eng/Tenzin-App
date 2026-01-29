import '../models/user_settings.dart';
import '../models/user.dart';
import '../local/daos/settings_dao.dart';
import '../remote/settings_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class SettingsRepository {
  final SettingsRemote _settingsRemote;
  final SettingsDao _settingsDao;
  final NetworkInfo _networkInfo;

  SettingsRepository(
    this._settingsRemote,
    this._settingsDao,
    this._networkInfo,
  );

  Future<({UserSettingsModel? settings, Failure? failure})> getSettings(
    String userId,
  ) async {
    try {
      // Try local first
      var settings = await _settingsDao.getByUserId(userId);

      if (settings == null && await _networkInfo.isConnected) {
        settings = await _settingsRemote.getUserSettings(userId);
        if (settings != null) {
          await _settingsDao.insert(settings);
        }
      }

      settings ??= UserSettingsModel.initial(userId);
      return (settings: settings, failure: null);
    } catch (e) {
      AppLogger.logError('SettingsRepository', 'getSettings', e);
      return (settings: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({UserSettingsModel? settings, Failure? failure})> updateSettings(
    UserSettingsModel settings,
  ) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final localSettings = settings.copyWith(
        syncStatus: SyncStatus.pending,
        lastModifiedAt: now,
      );
      await _settingsDao.insert(localSettings);

      if (await _networkInfo.isConnected) {
        final remoteSettings = await _settingsRemote.upsertUserSettings(localSettings);
        final syncedSettings = remoteSettings.copyWith(syncStatus: SyncStatus.synced);
        await _settingsDao.insert(syncedSettings);
        return (settings: syncedSettings, failure: null);
      }

      return (settings: localSettings, failure: null);
    } catch (e) {
      AppLogger.logError('SettingsRepository', 'updateSettings', e);
      return (settings: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<Failure?> updateNotificationSetting({
    required String userId,
    required String settingKey,
    required bool value,
  }) async {
    try {
      final currentResult = await getSettings(userId);
      final current = currentResult.settings;

      if (current == null) {
        return Failure.unknown('Settings not found');
      }

      final updated = _updateSettingByKey(current, settingKey, value);
      final result = await updateSettings(updated);
      return result.failure;
    } catch (e) {
      AppLogger.logError('SettingsRepository', 'updateNotificationSetting', e);
      return Failure.unknown(e.toString());
    }
  }

  UserSettingsModel _updateSettingByKey(
    UserSettingsModel settings,
    String key,
    bool value,
  ) {
    switch (key) {
      case 'newFollower':
        return settings.copyWith(notificationNewFollower: value);
      case 'leaderboardRank':
        return settings.copyWith(notificationLeaderboardRank: value);
      case 'messages':
        return settings.copyWith(notificationMessages: value);
      case 'achievements':
        return settings.copyWith(notificationAchievements: value);
      default:
        return settings;
    }
  }

  Future<void> syncSettings(String userId) async {
    try {
      if (!await _networkInfo.isConnected) return;

      final local = await _settingsDao.getByUserId(userId);
      if (local == null) return;

      if (local.syncStatus == SyncStatus.pending) {
        final remoteSettings = await _settingsRemote.upsertUserSettings(local);
        await _settingsDao.insert(
          remoteSettings.copyWith(syncStatus: SyncStatus.synced),
        );
      } else {
        // Pull remote changes
        final remoteSettings = await _settingsRemote.getUserSettings(userId);
        if (remoteSettings != null &&
            remoteSettings.lastModifiedAt > local.lastModifiedAt) {
          await _settingsDao.insert(
            remoteSettings.copyWith(syncStatus: SyncStatus.synced),
          );
        }
      }
    } catch (e) {
      AppLogger.logError('SettingsRepository', 'syncSettings', e);
    }
  }
}
