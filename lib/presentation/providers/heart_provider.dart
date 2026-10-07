import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/heart_state.dart';
import '../../core/error/failures.dart';
import '../../core/platform/secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import 'auth_provider.dart';
import 'core_providers.dart';
import 'remote_providers.dart';
import 'repository_providers.dart';

// Heart State
class HeartProviderState {
  final HeartStateModel? heartState;
  final bool isLoading;
  final Failure? failure;
  final Duration timeUntilNext;

  const HeartProviderState({
    this.heartState,
    this.isLoading = false,
    this.failure,
    this.timeUntilNext = Duration.zero,
  });

  HeartProviderState copyWith({
    HeartStateModel? heartState,
    bool? isLoading,
    Failure? failure,
    Duration? timeUntilNext,
  }) {
    return HeartProviderState(
      heartState: heartState ?? this.heartState,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      timeUntilNext: timeUntilNext ?? this.timeUntilNext,
    );
  }

  int get currentHearts => heartState?.currentHearts ?? 0;
  int get hearts => currentHearts; // Alias for UI compatibility
  bool get canUseHeart => (heartState?.currentHearts ?? 0) > 0;
  bool get isFull => heartState?.isFull ?? false;
  Duration? get timeUntilNextHeart => isFull ? null : timeUntilNext;
  Duration? get timeToNextHeart => timeUntilNextHeart; // Alias for UI compatibility
  
  static const initial = HeartProviderState();
}

// Heart Notifier
class HeartNotifier extends StateNotifier<HeartProviderState> {
  final Ref _ref;
  Timer? _countdownTimer;
  DateTime? _regenerationStartTime;
  bool _isDisposed = false;

  HeartNotifier(this._ref) : super(HeartProviderState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _safeUpdate(HeartProviderState Function(HeartProviderState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadHeartState(String userId) async {
    if (_isDisposed) return;
    final prev = state.heartState;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));

    try {
      // Read persisted lightweight heart state from secure storage
      final storage = SecureStorageService();
      final currentKey = AppConstants.keyHeartCurrentPrefix + userId;
      final lastChangeKey = AppConstants.keyHeartLastChangePrefix + userId;

      final currentStr = await storage.read(currentKey);
      final lastChangeStr = await storage.read(lastChangeKey);

      int current = HeartStateModel.maxHearts;
      DateTime lastChange = DateTime.now();

      if (currentStr != null) {
        current = int.tryParse(currentStr) ?? HeartStateModel.maxHearts;
      }

      if (lastChangeStr != null) {
        lastChange = DateTime.tryParse(lastChangeStr) ?? DateTime.now();
      }

      // Compute regeneration based on device time
      final now = DateTime.now();
      final elapsed = now.difference(lastChange);
      final regenPerMinutes = HeartStateModel.regenerationMinutes;
      final toRegenerate = elapsed.inMinutes ~/ regenPerMinutes;

      if (toRegenerate > 0 && current < HeartStateModel.maxHearts) {
        final newCount = (current + toRegenerate).clamp(0, HeartStateModel.maxHearts);
        current = newCount;

        // Advance lastChange forward by the regenerated cycles
        final advanced = lastChange.add(Duration(minutes: toRegenerate * regenPerMinutes));
        lastChange = advanced.isAfter(now) ? now : advanced;
      }

      var model = HeartStateModel(
        userId: userId,
        currentHearts: current,
        lastHeartLossAt: null,
        lastRegenerationAt: lastChange,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Reconcile with SQLite (source of truth for sync): adopt whichever
      // side has the most recent heart event so local progress is never
      // lost and state converges across app restarts.
      try {
        final repo = _ref.read(heartRepositoryProvider);
        final dbResult = await repo.getHeartState(userId);
        final dbModel = dbResult.heartState;
        if (dbModel != null) {
          model = _newerHeartModel(model, dbModel);
        }
      } catch (e) {
        AppLogger.warning('Heart load: DB reconcile skipped: $e');
      }

      // Pull remote state when online so a second device sees the latest.
      try {
        final networkInfo = _ref.read(networkInfoProvider);
        if (await networkInfo.isConnected) {
          final remote = _ref.read(heartRemoteProvider);
          final remoteModel = await remote.getHeartState(userId);
          if (remoteModel != null) {
            final regenerated = remoteModel.regenerate();
            if (_eventTime(regenerated).isAfter(_eventTime(model))) {
              model = regenerated;
            }
          }
        }
      } catch (e) {
        AppLogger.warning('Heart load: remote pull skipped: $e');
      }

      _safeUpdate((s) => s.copyWith(isLoading: false, heartState: model));

      // Persist to secure storage + SQLite (which pushes to Appwrite).
      // Skipped when nothing changed (e.g. repeated reloads).
      if (!_sameHeartState(prev, model)) {
        await _persistHeartState(userId, model);
      }

      _startCountdownTimer(userId);
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        failure: Failure.unknown(e.toString()),
      ));
    }
  }

  /// Latest heart event (loss or regen) — used to pick the newest state
  /// when reconciling secure storage, SQLite and Appwrite.
  DateTime _eventTime(HeartStateModel m) {
    final loss = m.lastHeartLossAt;
    final regen = m.lastRegenerationAt;
    if (loss == null && regen == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    if (loss == null) return regen!;
    if (regen == null) return loss;
    return loss.isAfter(regen) ? loss : regen;
  }

  /// Returns whichever model has the most recent heart event.
  /// Ties break toward [b] (the database side).
  HeartStateModel _newerHeartModel(HeartStateModel a, HeartStateModel b) {
    final ta = _eventTime(a);
    final tb = _eventTime(b);
    if (tb.isAfter(ta)) return b;
    if (ta.isAfter(tb)) return a;
    return b;
  }

  bool _sameHeartState(HeartStateModel? a, HeartStateModel b) {
    if (a == null || a.userId != b.userId) return false;
    return a.currentHearts == b.currentHearts &&
        a.lastHeartLossAt?.millisecondsSinceEpoch ==
            b.lastHeartLossAt?.millisecondsSinceEpoch &&
        a.lastRegenerationAt?.millisecondsSinceEpoch ==
            b.lastRegenerationAt?.millisecondsSinceEpoch;
  }

  /// Writes heart state to secure storage (fast local cache) AND to SQLite
  /// via the repository, which syncs to Appwrite in the background.
  /// Never throws — sync failures must not break the UI.
  Future<void> _persistHeartState(String userId, HeartStateModel model) async {
    if (_isDisposed) return;
    try {
      final storage = SecureStorageService();
      await storage.write(
        AppConstants.keyHeartCurrentPrefix + userId,
        model.currentHearts.toString(),
      );
      final change =
          model.lastRegenerationAt ?? model.lastHeartLossAt ?? DateTime.now();
      await storage.write(
        AppConstants.keyHeartLastChangePrefix + userId,
        change.toIso8601String(),
      );
    } catch (e) {
      AppLogger.warning('Heart persist: secure storage failed: $e');
    }
    try {
      await _ref.read(heartRepositoryProvider).updateHeartState(model);
    } catch (e) {
      AppLogger.warning('Heart persist: database sync failed: $e');
    }
  }

  void _startCountdownTimer(String userId) {
    _countdownTimer?.cancel();
    
    if (_isDisposed || state.heartState == null || state.heartState!.isFull) {
      _safeUpdate((s) => s.copyWith(timeUntilNext: Duration.zero));
      return;
    }
    _regenerationStartTime = state.heartState!.lastRegenerationAt ?? state.heartState!.lastHeartLossAt ?? DateTime.now();
    
    // Throttle countdown updates to reduce UI rebuild frequency on lists.
    // Updating every 5 seconds is sufficient for a smooth UX and lowers CPU/GPU cost.
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateCountdown(userId),
    );
    
    // Update immediately
    _updateCountdown(userId);
  }

  void _updateCountdown(String userId) {
    if (_isDisposed) {
      _countdownTimer?.cancel();
      return;
    }
    
    if (state.heartState == null || state.heartState!.isFull) {
      _countdownTimer?.cancel();
      _safeUpdate((s) => s.copyWith(timeUntilNext: Duration.zero));
      return;
    }

    final now = DateTime.now();
    final elapsed = now.difference(_regenerationStartTime!);
    final cycleSeconds = HeartStateModel.regenerationMinutes * 60;

    // Calculate how many full cycles have passed. If one or more cycles
    // have completed, trigger regeneration immediately so hearts increase.
    final completedCycles = elapsed.inSeconds ~/ cycleSeconds;
    if (completedCycles > 0) {
      _regenerateHeart(userId);
      return;
    }

    // Otherwise compute remaining seconds until the next cycle completes.
    final elapsedInCycle = elapsed.inSeconds % cycleSeconds;
    final secondsRemaining = cycleSeconds - elapsedInCycle;
    _safeUpdate((s) => s.copyWith(timeUntilNext: Duration(seconds: secondsRemaining)));
  }

  Future<void> _regenerateHeart(String userId) async {
    if (_isDisposed || state.heartState == null) return;
    final currentModel = state.heartState!;

    // Compute how many hearts should be regenerated from device time
    final lastChange = currentModel.lastRegenerationAt ?? DateTime.now();
    final now = DateTime.now();
    final elapsed = now.difference(lastChange);
    final regenMinutes = HeartStateModel.regenerationMinutes;
    final toRegenerate = elapsed.inMinutes ~/ regenMinutes;

    if (toRegenerate <= 0) return;

    final newCount = (currentModel.currentHearts + toRegenerate).clamp(0, HeartStateModel.maxHearts);

    final advanced = lastChange.add(Duration(minutes: toRegenerate * regenMinutes));
    final newLastChange = advanced.isAfter(now) ? now : advanced;

    final updated = currentModel.copyWith(
      currentHearts: newCount,
      lastRegenerationAt: newLastChange,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    if (_isDisposed) return;

    _regenerationStartTime = DateTime.now();
    _safeUpdate((s) => s.copyWith(heartState: updated));

    // Persist to secure storage + SQLite (syncs to Appwrite in background).
    await _persistHeartState(userId, updated);

    if (updated.isFull) {
      _countdownTimer?.cancel();
      _safeUpdate((s) => s.copyWith(timeUntilNext: Duration.zero));
    }
  }

  Future<bool> useHeart(String userId) async {
    if (_isDisposed || !state.canUseHeart) return false;
    try {
      final now = DateTime.now();
      final current = state.heartState!.currentHearts - 1;

      final updated = state.heartState!.copyWith(
        currentHearts: current,
        lastHeartLossAt: now,
        lastRegenerationAt: now,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      if (_isDisposed) return false;

      _regenerationStartTime = now;
      _safeUpdate((s) => s.copyWith(heartState: updated));

      // Persist to secure storage + SQLite (syncs to Appwrite in background).
      await _persistHeartState(userId, updated);

      _startCountdownTimer(userId);
      return true;
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
      return false;
    }
  }

  Future<void> refillHearts(String userId) async {
    if (_isDisposed) return;
    try {
      final updated = state.heartState?.refillHearts() ?? HeartStateModel.initial(userId);

      if (_isDisposed) return;

      _safeUpdate((s) => s.copyWith(heartState: updated));

      // Persist to secure storage + SQLite (syncs to Appwrite in background).
      await _persistHeartState(userId, updated);

      _countdownTimer?.cancel();
      _safeUpdate((s) => s.copyWith(timeUntilNext: Duration.zero));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
    }
  }
}

// Heart Provider
final heartProvider = StateNotifierProvider<HeartNotifier, HeartProviderState>((ref) {
  final notifier = HeartNotifier(ref);
  
  // Auto-load when user changes
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    notifier.loadHeartState(user.id);
  }
  
  return notifier;
});

// Convenience providers
final currentHeartsProvider = Provider<int>((ref) {
  return ref.watch(heartProvider).currentHearts;
});

final canUseHeartProvider = Provider<bool>((ref) {
  return ref.watch(heartProvider).canUseHeart;
});

final heartsFullProvider = Provider<bool>((ref) {
  return ref.watch(heartProvider).isFull;
});

final timeUntilNextHeartProvider = Provider<Duration?>((ref) {
  return ref.watch(heartProvider).timeUntilNextHeart;
});

// Formatted time string provider
final timeUntilNextHeartStringProvider = Provider<String>((ref) {
  final duration = ref.watch(heartProvider).timeUntilNext;
  if (duration == Duration.zero) return '';
  
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
});

// Full time string (including hours)
final fullTimeUntilHeartsStringProvider = Provider<String>((ref) {
  final heartState = ref.watch(heartProvider).heartState;
  if (heartState == null || heartState.isFull) return '';
  
  final duration = heartState.timeUntilFullHearts;
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  
  if (hours > 0) {
    return '$hours цаг $minutes мин';
  }
  return '$minutes минут';
});
