import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/heart_state.dart';
import '../../core/error/failures.dart';
import '../../core/platform/secure_storage.dart';
import '../../core/constants/app_constants.dart';
import 'auth_provider.dart';

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
  Timer? _countdownTimer;
  DateTime? _regenerationStartTime;
  bool _isDisposed = false;

  HeartNotifier(Ref ref) : super(HeartProviderState.initial);

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

        // Persist updated values
        await storage.write(currentKey, current.toString());
        await storage.write(lastChangeKey, lastChange.toIso8601String());
      }

      final model = HeartStateModel(
        userId: userId,
        currentHearts: current,
        lastHeartLossAt: null,
        lastRegenerationAt: lastChange,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      _safeUpdate((s) => s.copyWith(isLoading: false, heartState: model));

      _startCountdownTimer(userId);
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        failure: Failure.unknown(e.toString()),
      ));
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
    final storage = SecureStorageService();
    final currentKey = AppConstants.keyHeartCurrentPrefix + userId;
    final lastChangeKey = AppConstants.keyHeartLastChangePrefix + userId;

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

    try {
      await storage.write(currentKey, updated.currentHearts.toString());
      await storage.write(lastChangeKey, newLastChange.toIso8601String());

      if (_isDisposed) return;

      _regenerationStartTime = DateTime.now();
      _safeUpdate((s) => s.copyWith(heartState: updated));

      if (updated.isFull) {
        _countdownTimer?.cancel();
        _safeUpdate((s) => s.copyWith(timeUntilNext: Duration.zero));
      }
    } catch (_) {
      // Ignore storage failures silently for regeneration
    }
  }

  Future<bool> useHeart(String userId) async {
    if (_isDisposed || !state.canUseHeart) return false;
    try {
      final storage = SecureStorageService();
      final currentKey = AppConstants.keyHeartCurrentPrefix + userId;
      final lastChangeKey = AppConstants.keyHeartLastChangePrefix + userId;

      final now = DateTime.now();
      final current = state.heartState!.currentHearts - 1;

      final updated = state.heartState!.copyWith(
        currentHearts: current,
        lastHeartLossAt: now,
        lastRegenerationAt: now,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      await storage.write(currentKey, updated.currentHearts.toString());
      await storage.write(lastChangeKey, now.toIso8601String());

      if (_isDisposed) return false;

      _regenerationStartTime = now;
      _safeUpdate((s) => s.copyWith(heartState: updated));
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
      final storage = SecureStorageService();
      final currentKey = AppConstants.keyHeartCurrentPrefix + userId;
      final lastChangeKey = AppConstants.keyHeartLastChangePrefix + userId;

      final now = DateTime.now();

      final updated = state.heartState?.refillHearts() ?? HeartStateModel.initial(userId);

      await storage.write(currentKey, updated.currentHearts.toString());
      await storage.write(lastChangeKey, now.toIso8601String());

      if (_isDisposed) return;

      _safeUpdate((s) => s.copyWith(heartState: updated));
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
