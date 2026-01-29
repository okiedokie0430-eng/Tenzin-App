import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'core_providers.dart';

// Auth State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final Failure? failure;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.failure,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    Failure? failure,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }

  static const initial = AuthState();
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  bool _isDisposed = false;

  AuthNotifier(this._ref, {bool autoCheck = true}) : super(AuthState.initial) {
    if (autoCheck) {
      _checkAuthStatus();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(AuthState Function(AuthState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> _checkAuthStatus() async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true));
    final repository = _ref.read(authRepositoryProvider);
    final user = await repository.getCurrentUser();
    _safeUpdate((s) => s.copyWith(
      isLoading: false,
      user: user,
      isAuthenticated: user != null,
    ));

    // Online-only streak reset check.
    if (user != null) {
      await _resetStreakIfExpired(user);
    }
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  /// Streak is ONLINE-ONLY.
  /// Rules:
  /// - First lesson completion of a day => +1 streak (max 1 per day)
  /// - If no completion for >3 days => reset and restart (next completion => 1)
  Future<void> awardDailyStreakIfEligible() async {
    if (_isDisposed) return;
    final currentUser = state.user;
    if (currentUser == null) return;

    final networkInfo = _ref.read(networkInfoProvider);
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) return;

    final now = DateTime.now();
    final today = _dateOnly(now);
    final last = currentUser.lastLessonDate;

    // Already got today's streak.
    if (last != null && _dateOnly(last) == today) return;

    int nextStreak;
    if (last == null) {
      nextStreak = 1;
    } else {
      final diffDays = today.difference(_dateOnly(last)).inDays;
      if (diffDays > 3) {
        nextStreak = 1;
      } else {
        nextStreak = currentUser.currentStreakDays + 1;
      }
    }

    final nextLongest = nextStreak > currentUser.longestStreakDays
        ? nextStreak
        : currentUser.longestStreakDays;

    final updatedUser = currentUser.copyWith(
      currentStreakDays: nextStreak,
      longestStreakDays: nextLongest,
      lastLessonDate: now,
      lastModifiedAt: now.millisecondsSinceEpoch,
    );

    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.updateProfile(updatedUser);
    if (result.user != null && !_isDisposed) {
      _safeUpdate((s) => s.copyWith(user: result.user));
    }
  }

  Future<void> _resetStreakIfExpired(UserModel user) async {
    final networkInfo = _ref.read(networkInfoProvider);
    final isConnected = await networkInfo.isConnected;
    if (!isConnected) return;

    if (user.currentStreakDays <= 0) return;
    final last = user.lastLessonDate;
    if (last == null) return;

    final now = DateTime.now();
    final diffDays = _dateOnly(now).difference(_dateOnly(last)).inDays;
    if (diffDays <= 3) return;

    final updatedUser = user.copyWith(
      currentStreakDays: 0,
      lastModifiedAt: now.millisecondsSinceEpoch,
    );

    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.updateProfile(updatedUser);
    if (result.user != null && !_isDisposed) {
      _safeUpdate((s) => s.copyWith(user: result.user));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.signInWithEmail(
      email: email,
      password: password,
    );
    
    if (result.failure != null) {
      _safeUpdate((s) => s.copyWith(isLoading: false, failure: result.failure));
    } else {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
      ));
    }
  }

  Future<void> signUpWithEmail(String email, String password, String name) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.signUpWithEmail(
      email: email,
      password: password,
      name: name,
    );
    
    if (result.failure != null) {
      _safeUpdate((s) => s.copyWith(isLoading: false, failure: result.failure));
    } else {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
      ));
    }
  }

  Future<void> signInWithGoogle() async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.signInWithGoogle();
    
    if (result.failure != null) {
      _safeUpdate((s) => s.copyWith(isLoading: false, failure: result.failure));
    } else {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        user: result.user,
        isAuthenticated: true,
      ));
    }
  }

  Future<void> signOut() async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true));
    final repository = _ref.read(authRepositoryProvider);
    await repository.signOut();
    _safeUpdate((_) => AuthState.initial);
  }

  /// Delete user account and related data.
  /// Returns a Failure if deletion failed, otherwise null on success.
  Future<Failure?> deleteAccount() async {
    if (_isDisposed) return Failure.unknown('Disposed');
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(authRepositoryProvider);
    final failure = await repository.deleteAccount();

    if (failure == null) {
      // Try to sign out and clear local state
      try {
        await repository.signOut();
      } catch (_) {}
      _safeUpdate((_) => AuthState.initial);
      return null;
    }

    _safeUpdate((s) => s.copyWith(isLoading: false, failure: failure));
    return failure;
  }

  Future<void> updateProfile(UserModel user) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.updateProfile(user);
    
    if (result.failure != null) {
      _safeUpdate((s) => s.copyWith(isLoading: false, failure: result.failure));
    } else {
      _safeUpdate((s) => s.copyWith(isLoading: false, user: result.user));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    final repository = _ref.read(authRepositoryProvider);
    final failure = await repository.sendPasswordResetEmail(email);
    _safeUpdate((s) => s.copyWith(isLoading: false, failure: failure));
  }

  void clearFailure() {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(failure: null));
  }

  void refreshUser() {
    _checkAuthStatus();
  }

  /// Update user stats after lesson completion
  /// This updates the denormalized XP and lesson count in user_profiles
  Future<void> updateUserStats({
    required int xpEarned,
    required bool lessonCompleted,
  }) async {
    if (_isDisposed) return;
    final currentUser = state.user;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      totalXp: currentUser.totalXp + xpEarned,
      weeklyXp: currentUser.weeklyXp + xpEarned,
      lessonsCompleted: lessonCompleted 
          ? currentUser.lessonsCompleted + 1 
          : currentUser.lessonsCompleted,
      lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.updateProfile(updatedUser);
    
    if (result.user != null && !_isDisposed) {
      _safeUpdate((s) => s.copyWith(user: result.user));
    }
  }
}

// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

// Convenience providers
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

// User Search State
class UserSearchState {
  final List<UserModel> results;
  final bool isLoading;
  final Failure? failure;
  final String query;

  const UserSearchState({
    this.results = const [],
    this.isLoading = false,
    this.failure,
    this.query = '',
  });

  UserSearchState copyWith({
    List<UserModel>? results,
    bool? isLoading,
    Failure? failure,
    String? query,
  }) {
    return UserSearchState(
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      query: query ?? this.query,
    );
  }

  static const initial = UserSearchState();
}

// User Search Notifier
class UserSearchNotifier extends StateNotifier<UserSearchState> {
  final Ref _ref;
  bool _isDisposed = false;

  UserSearchNotifier(this._ref) : super(UserSearchState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(UserSearchState Function(UserSearchState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> searchUsers(String query) async {
    if (_isDisposed) return;
    if (query.trim().isEmpty) {
      _safeUpdate((_) => UserSearchState.initial);
      return;
    }

    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null, query: query));
    final repository = _ref.read(authRepositoryProvider);
    final result = await repository.searchUsers(query);

    // Filter out current user from results
    final currentUser = _ref.read(currentUserProvider);
    final filteredResults = result.users
        .where((u) => u.id != currentUser?.id)
        .toList();

    _safeUpdate((s) => s.copyWith(
      isLoading: false,
      results: filteredResults,
      failure: result.failure,
    ));
  }

  void clear() {
    if (_isDisposed) return;
    _safeUpdate((_) => UserSearchState.initial);
  }
}

// User Search Provider
final userSearchProvider = StateNotifierProvider<UserSearchNotifier, UserSearchState>((ref) {
  return UserSearchNotifier(ref);
});

// Convenience providers for user search
final userSearchResultsProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(userSearchProvider).results;
});

final isUserSearchLoadingProvider = Provider<bool>((ref) {
  return ref.watch(userSearchProvider).isLoading;
});

/// Provider to fetch another user's profile by ID
/// Returns AsyncValue<UserModel?> - loading, data, or error state
final otherUserProfileProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final repository = ref.watch(authRepositoryProvider);
  final result = await repository.getUserById(userId);
  
  if (result.failure != null) {
    throw Exception(result.failure!.message);
  }
  
  return result.user;
});

/// Provider to get another user's stats (XP, level, streak, etc.)
/// Used in profile screens and leaderboard
class OtherUserStats {
  final int totalXp;
  final int level;
  final int streak;
  final int lessonsCompleted;
  final int followerCount;
  final int followingCount;

  const OtherUserStats({
    this.totalXp = 0,
    this.level = 1,
    this.streak = 0,
    this.lessonsCompleted = 0,
    this.followerCount = 0,
    this.followingCount = 0,
  });

  factory OtherUserStats.fromUser(UserModel user) {
    return OtherUserStats(
      totalXp: user.totalXp,
      level: user.level,
      streak: user.currentStreakDays,
      lessonsCompleted: user.lessonsCompleted,
      followerCount: user.followerCount,
      followingCount: user.followingCount,
    );
  }
}

final otherUserStatsProvider = FutureProvider.family<OtherUserStats, String>((ref, userId) async {
  final user = await ref.watch(otherUserProfileProvider(userId).future);
  if (user == null) {
    return const OtherUserStats();
  }
  return OtherUserStats.fromUser(user);
});
