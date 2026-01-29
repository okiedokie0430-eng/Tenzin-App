import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/leaderboard.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Leaderboard State
class LeaderboardState {
  final List<LeaderboardEntryModel> entries;
  final List<LeaderboardEntryModel> followingEntriesList;
  final LeaderboardEntryModel? userEntry;
  final int userRank;
  final bool isLoading;
  final Failure? failure;
  final LeaderboardTab currentTab;

  const LeaderboardState({
    this.entries = const [],
    this.followingEntriesList = const [],
    this.userEntry,
    this.userRank = 0,
    this.isLoading = false,
    this.failure,
    this.currentTab = LeaderboardTab.global,
  });

  LeaderboardState copyWith({
    List<LeaderboardEntryModel>? entries,
    List<LeaderboardEntryModel>? followingEntriesList,
    LeaderboardEntryModel? userEntry,
    int? userRank,
    bool? isLoading,
    Failure? failure,
    LeaderboardTab? currentTab,
  }) {
    return LeaderboardState(
      entries: entries ?? this.entries,
      followingEntriesList: followingEntriesList ?? this.followingEntriesList,
      userEntry: userEntry ?? this.userEntry,
      userRank: userRank ?? this.userRank,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      currentTab: currentTab ?? this.currentTab,
    );
  }

  // Convenience getters for UI
  int get selectedTab => currentTab == LeaderboardTab.global ? 0 : 1;
  List<LeaderboardEntryModel> get globalEntries => entries;
  List<LeaderboardEntryModel> get followingEntries => followingEntriesList;

  static const initial = LeaderboardState();
}

enum LeaderboardTab { global, following }

// Leaderboard Notifier
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final Ref _ref;
  bool _isDisposed = false;

  LeaderboardNotifier(this._ref) : super(LeaderboardState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(LeaderboardState Function(LeaderboardState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadLeaderboard(String userId) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    
    try {
      final repository = _ref.read(leaderboardRepositoryProvider);
      
      final result = await repository.getWeeklyLeaderboard();
      final userEntryResult = await repository.getUserEntry(userId);
      final userRank = await repository.getUserRank(userId);
      
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        entries: result.entries,
        userEntry: userEntryResult.entry,
        userRank: userRank,
        failure: result.failure,
      ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        failure: Failure.unknown(e.toString()),
      ));
    }
  }

  Future<void> loadFollowingLeaderboard(
    String userId,
    List<String> followingIds,
  ) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    
    try {
      final repository = _ref.read(leaderboardRepositoryProvider);
      final result = await repository.getFollowingLeaderboard(userId, followingIds);
      
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        entries: result.entries,
        failure: result.failure,
      ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        failure: Failure.unknown(e.toString()),
      ));
    }
  }

  void switchTab(LeaderboardTab tab) {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(currentTab: tab));
  }

  void setTab(int index) {
    switchTab(index == 0 ? LeaderboardTab.global : LeaderboardTab.following);
  }

  Future<void> addXp({
    required String userId,
    required String userName,
    String? profileImageUrl,
    required int xpToAdd,
  }) async {
    if (_isDisposed) return;
    
    try {
      final repository = _ref.read(leaderboardRepositoryProvider);
      await repository.addXp(
        userId: userId,
        userName: userName,
        profileImageUrl: profileImageUrl,
        xpToAdd: xpToAdd,
      );
      
      // Refresh leaderboard
      await loadLeaderboard(userId);
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
    }
  }

  Future<void> refresh(String userId) async {
    if (_isDisposed) return;
    await loadLeaderboard(userId);
  }
}

// Leaderboard Provider
final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  final notifier = LeaderboardNotifier(ref);
  
  // Auto-load when user changes
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    notifier.loadLeaderboard(user.id);
  }
  
  return notifier;
});

// Convenience providers
final leaderboardEntriesProvider = Provider<List<LeaderboardEntryModel>>((ref) {
  return ref.watch(leaderboardProvider).entries;
});

final userLeaderboardRankProvider = Provider<int>((ref) {
  return ref.watch(leaderboardProvider).userRank;
});

final userLeaderboardEntryProvider = Provider<LeaderboardEntryModel?>((ref) {
  return ref.watch(leaderboardProvider).userEntry;
});

final currentLeaderboardTabProvider = Provider<LeaderboardTab>((ref) {
  return ref.watch(leaderboardProvider).currentTab;
});

// Top 3 providers
final topThreeLeaderboardProvider = Provider<List<LeaderboardEntryModel>>((ref) {
  final entries = ref.watch(leaderboardEntriesProvider);
  return entries.take(3).toList();
});
