import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_settings.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Settings State
class SettingsState {
  final UserSettingsModel? settings;
  final bool isLoading;
  final bool isSaving;
  final Failure? failure;

  const SettingsState({
    this.settings,
    this.isLoading = false,
    this.isSaving = false,
    this.failure,
  });

  SettingsState copyWith({
    UserSettingsModel? settings,
    bool? isLoading,
    bool? isSaving,
    Failure? failure,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      failure: failure,
    );
  }

  static const initial = SettingsState();
}

// Settings Notifier
class SettingsNotifier extends StateNotifier<SettingsState> {
  final Ref _ref;
  bool _isDisposed = false;

  SettingsNotifier(this._ref) : super(SettingsState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(SettingsState Function(SettingsState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadSettings(String userId) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));

    try {
      final repository = _ref.read(settingsRepositoryProvider);
      final result = await repository.getSettings(userId);

      _safeUpdate((s) => s.copyWith(
            isLoading: false,
            settings: result.settings,
            failure: result.failure,
          ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
            isLoading: false,
            failure: Failure.unknown(e.toString()),
          ));
    }
  }

  Future<bool> updateSettings(UserSettingsModel settings) async {
    if (_isDisposed) return false;
    _safeUpdate((s) => s.copyWith(isSaving: true, failure: null));

    try {
      final repository = _ref.read(settingsRepositoryProvider);
      final result = await repository.updateSettings(settings);

      if (result.failure == null) {
        _safeUpdate((s) => s.copyWith(
              isSaving: false,
              settings: result.settings ?? settings,
            ));
        return true;
      } else {
        _safeUpdate((s) => s.copyWith(
              isSaving: false,
              failure: result.failure,
            ));
        return false;
      }
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
            isSaving: false,
            failure: Failure.unknown(e.toString()),
          ));
      return false;
    }
  }

  Future<bool> toggleNewFollowerNotification(String userId) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      notificationNewFollower: !current.notificationNewFollower,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> toggleLeaderboardRankNotification(String userId) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      notificationLeaderboardRank: !current.notificationLeaderboardRank,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> toggleMessagesNotification(String userId) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      notificationMessages: !current.notificationMessages,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> toggleAchievementsNotification(String userId) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      notificationAchievements: !current.notificationAchievements,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> setStoragePermissionGranted(String userId, bool granted) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      storagePermissionGranted: granted,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> toggleNotifications(bool value) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      notificationNewFollower: value,
      notificationLeaderboardRank: value,
      notificationMessages: value,
      notificationAchievements: value,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Update state immediately for instant UI response
    state = state.copyWith(settings: updated);

    // Notifications disabled: do not call platform notification APIs.

    // Then persist in background
    return await updateSettings(updated);
  }

  Future<bool> toggleDailyReminder(bool value) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      dailyReminderEnabled: value,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final success = await updateSettings(updated);

    // Notifications disabled: do not call platform notification APIs.

    return success;
  }

  Future<bool> setDailyReminderTime(String time) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      dailyReminderTime: time,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> toggleSound(bool value) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      soundEnabled: value,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> toggleMusic(bool value) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      musicEnabled: value,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    return await updateSettings(updated);
  }

  Future<bool> setTheme(String theme) async {
    final current = state.settings;
    if (current == null) return false;

    final updated = current.copyWith(
      theme: theme,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    // Update state immediately for instant UI response
    state = state.copyWith(settings: updated);

    // Then persist in background
    return await updateSettings(updated);
  }

  Future<void> refresh(String userId) async {
    await loadSettings(userId);
  }
}

// Settings Provider
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final notifier = SettingsNotifier(ref);

  // Auto-load when user changes, but only if settings not already loaded
  ref.listen(currentUserProvider, (previous, next) {
    if (next != null && (previous == null || previous.id != next.id)) {
      // Only reload when user actually changes (login/logout/switch)
      notifier.loadSettings(next.id);
    }
  });

  return notifier;
});

// Convenience providers
final userSettingsProvider = Provider<UserSettingsModel?>((ref) {
  return ref.watch(settingsProvider).settings;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(userSettingsProvider);
  if (settings == null) return true;
  return settings.notificationNewFollower ||
      settings.notificationLeaderboardRank ||
      settings.notificationMessages ||
      settings.notificationAchievements;
});

final newFollowerNotificationProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider)?.notificationNewFollower ?? true;
});

final leaderboardRankNotificationProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider)?.notificationLeaderboardRank ?? true;
});

final messagesNotificationProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider)?.notificationMessages ?? true;
});

final achievementsNotificationProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider)?.notificationAchievements ?? true;
});

final storagePermissionProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider)?.storagePermissionGranted ?? false;
});
