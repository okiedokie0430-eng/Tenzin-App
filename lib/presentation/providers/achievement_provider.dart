import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/achievement.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Achievement State
class AchievementState {
  final List<AchievementWithStatus> achievements;
  final int unlockedCount;
  final bool isLoading;
  final Failure? failure;
  final List<AchievementModel> newlyUnlocked;

  const AchievementState({
    this.achievements = const [],
    this.unlockedCount = 0,
    this.isLoading = false,
    this.failure,
    this.newlyUnlocked = const [],
  });

  AchievementState copyWith({
    List<AchievementWithStatus>? achievements,
    int? unlockedCount,
    bool? isLoading,
    Failure? failure,
    List<AchievementModel>? newlyUnlocked,
  }) {
    return AchievementState(
      achievements: achievements ?? this.achievements,
      unlockedCount: unlockedCount ?? this.unlockedCount,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      newlyUnlocked: newlyUnlocked ?? this.newlyUnlocked,
    );
  }

  // Convenience getters for UI
  List<AchievementWithStatus> get unlockedAchievements =>
      achievements.where((a) => a.isUnlocked).toList();
      
  List<AchievementWithStatus> get lockedAchievements =>
      achievements.where((a) => !a.isUnlocked).toList();

  static const initial = AchievementState();
}

// Achievement Notifier
class AchievementNotifier extends StateNotifier<AchievementState> {
  final Ref _ref;
  bool _isDisposed = false;

  AchievementNotifier(this._ref) : super(AchievementState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(AchievementState Function(AchievementState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadAchievements(String userId) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(achievementRepositoryProvider);
    
    final result = await repository.getAchievementsWithStatus(userId);
    final unlockedCount = await repository.getUnlockedCount(userId);
    
    _safeUpdate((s) => s.copyWith(
      isLoading: false,
      achievements: result.achievements,
      unlockedCount: unlockedCount,
      failure: result.failure,
    ));
  }

  Future<List<AchievementModel>> checkAndUnlock({
    required String userId,
    int? currentStreak,
    int? totalXp,
    int? lessonsCompleted,
    int? followersCount,
    String? completedTreePath,
    int? leaderboardRank,
    int? wordsLearned,
    bool? perfectLesson,
  }) async {
    if (_isDisposed) return [];
    final repository = _ref.read(achievementRepositoryProvider);
    final newlyUnlocked = await repository.checkAndUnlockAchievements(
      userId: userId,
      currentStreak: currentStreak,
      totalXp: totalXp,
      lessonsCompleted: lessonsCompleted,
      followersCount: followersCount,
      completedTreePath: completedTreePath,
      leaderboardRank: leaderboardRank,
      wordsLearned: wordsLearned,
      perfectLesson: perfectLesson,
    );

    if (newlyUnlocked.isNotEmpty && !_isDisposed) {
      _safeUpdate((s) => s.copyWith(newlyUnlocked: newlyUnlocked));
      // Refresh achievements
      await loadAchievements(userId);
    }

    return newlyUnlocked;
  }

  void clearNewlyUnlocked() {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(newlyUnlocked: []));
  }

  List<AchievementWithStatus> get unlockedAchievements {
    return state.achievements.where((a) => a.isUnlocked).toList();
  }

  List<AchievementWithStatus> get lockedAchievements {
    return state.achievements.where((a) => !a.isUnlocked).toList();
  }
}

// Achievement Provider
final achievementProvider = StateNotifierProvider<AchievementNotifier, AchievementState>((ref) {
  final notifier = AchievementNotifier(ref);
  
  // Auto-load when user changes
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    notifier.loadAchievements(user.id);
  }
  
  return notifier;
});

// Convenience providers
final achievementsListProvider = Provider<List<AchievementWithStatus>>((ref) {
  return ref.watch(achievementProvider).achievements;
});

final unlockedAchievementCountProvider = Provider<int>((ref) {
  return ref.watch(achievementProvider).unlockedCount;
});

final newlyUnlockedAchievementsProvider = Provider<List<AchievementModel>>((ref) {
  return ref.watch(achievementProvider).newlyUnlocked;
});

final unlockedAchievementsProvider = Provider<List<AchievementWithStatus>>((ref) {
  return ref.watch(achievementProvider).achievements.where((a) => a.isUnlocked).toList();
});

final lockedAchievementsProvider = Provider<List<AchievementWithStatus>>((ref) {
  return ref.watch(achievementProvider).achievements.where((a) => !a.isUnlocked).toList();
});
