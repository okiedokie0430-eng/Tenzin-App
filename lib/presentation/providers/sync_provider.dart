import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/error/failures.dart';
import 'core_providers.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Sync State
class SyncState {
  final bool isSyncing;
  final int pendingCount;
  final int syncedCount;
  final int failedCount;
  final DateTime? lastSyncAt;
  final Failure? failure;
  final String? currentOperation;

  const SyncState({
    this.isSyncing = false,
    this.pendingCount = 0,
    this.syncedCount = 0,
    this.failedCount = 0,
    this.lastSyncAt,
    this.failure,
    this.currentOperation,
  });

  SyncState copyWith({
    bool? isSyncing,
    int? pendingCount,
    int? syncedCount,
    int? failedCount,
    DateTime? lastSyncAt,
    Failure? failure,
    String? currentOperation,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      syncedCount: syncedCount ?? this.syncedCount,
      failedCount: failedCount ?? this.failedCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      failure: failure,
      currentOperation: currentOperation,
    );
  }

  static const initial = SyncState();
}

// Sync Notifier
class SyncNotifier extends StateNotifier<SyncState> {
  final Ref _ref;
  Timer? _autoSyncTimer;
  bool _isDisposed = false;
  static const _autoSyncInterval = Duration(minutes: 5);

  SyncNotifier(this._ref) : super(SyncState.initial) {
    _startAutoSync();
  }

  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(_autoSyncInterval, (_) {
      if (!_isDisposed) syncAll();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  void _safeUpdate(SyncState Function(SyncState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> syncAll() async {
    if (_isDisposed) return;
    
    final networkInfo = _ref.read(networkInfoProvider);
    final isConnected = await networkInfo.isConnected;
    
    if (!isConnected) {
      _safeUpdate((s) => s.copyWith(failure: Failure.network()));
      return;
    }

    final user = _ref.read(currentUserProvider);
    if (user == null || _isDisposed) return;

    _safeUpdate((s) => s.copyWith(isSyncing: true, failure: null, syncedCount: 0, failedCount: 0));
    
    try {
      // Sync progress
      if (_isDisposed) return;
      _safeUpdate((s) => s.copyWith(currentOperation: 'Progress'));
      final progressRepo = _ref.read(progressRepositoryProvider);
      await progressRepo.syncPendingProgress();
      
      // Sync heart state
      if (_isDisposed) return;
      _safeUpdate((s) => s.copyWith(currentOperation: 'Hearts'));
      final heartRepo = _ref.read(heartRepositoryProvider);
      await heartRepo.syncPendingHeartState();
      
      // Sync leaderboard
      if (_isDisposed) return;
      _safeUpdate((s) => s.copyWith(currentOperation: 'Leaderboard'));
      final leaderboardRepo = _ref.read(leaderboardRepositoryProvider);
      await leaderboardRepo.syncPendingEntries();
      
      // Sync settings
      if (_isDisposed) return;
      _safeUpdate((s) => s.copyWith(currentOperation: 'Settings'));
      final settingsRepo = _ref.read(settingsRepositoryProvider);
      await settingsRepo.syncSettings(user.id);
      
      // Sync follow data
      if (_isDisposed) return;
      _safeUpdate((s) => s.copyWith(currentOperation: 'Follow'));
      final followRepo = _ref.read(followRepositoryProvider);
      await followRepo.syncPendingChanges();
      // Refresh follow data from server
      await followRepo.getFollowers(user.id);
      await followRepo.getFollowing(user.id);
      
      // Sync support messages
      if (_isDisposed) return;
      _safeUpdate((s) => s.copyWith(currentOperation: 'Support'));
      final supportRepo = _ref.read(supportRepositoryProvider);
      await supportRepo.syncPendingMessages();
      
      _safeUpdate((s) => s.copyWith(
        isSyncing: false,
        lastSyncAt: DateTime.now(),
        currentOperation: null,
      ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isSyncing: false,
        failure: Failure.unknown(e.toString()),
        currentOperation: null,
      ));
    }
  }

  void triggerSync() {
    syncAll();
  }
}

// Sync Provider
final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});

// Convenience providers
final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider).isSyncing;
});

final lastSyncAtProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncProvider).lastSyncAt;
});

final syncFailureProvider = Provider<Failure?>((ref) {
  return ref.watch(syncProvider).failure;
});

final currentSyncOperationProvider = Provider<String?>((ref) {
  return ref.watch(syncProvider).currentOperation;
});
