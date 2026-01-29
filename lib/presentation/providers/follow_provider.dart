import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'dao_providers.dart';
import 'auth_provider.dart';

// ==================== FOLLOW STATE ====================

class FollowState {
  final List<UserModel> followers;
  final List<UserModel> following;
  final int followersCount;
  final int followingCount;
  final bool isLoading;
  final bool isProcessing;
  final Failure? failure;
  final DateTime? lastSyncAt;

  const FollowState({
    this.followers = const [],
    this.following = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.isLoading = false,
    this.isProcessing = false,
    this.failure,
    this.lastSyncAt,
  });

  FollowState copyWith({
    List<UserModel>? followers,
    List<UserModel>? following,
    int? followersCount,
    int? followingCount,
    bool? isLoading,
    bool? isProcessing,
    Failure? failure,
    DateTime? lastSyncAt,
  }) {
    return FollowState(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      failure: failure,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  static const initial = FollowState();
}

// ==================== FOLLOW NOTIFIER ====================

class FollowNotifier extends StateNotifier<FollowState> {
  final Ref _ref;
  bool _isDisposed = false;

  FollowNotifier(this._ref) : super(FollowState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Safe state update that checks if mounted
  void _safeUpdate(FollowState Function(FollowState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  /// Load follow data for a user from repository
  Future<void> loadFollowData(String userId, {bool silent = false}) async {
    if (_isDisposed) return;

    if (!silent) {
      _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    }

    try {
      final repository = _ref.read(followRepositoryProvider);
      final followDao = _ref.read(followDaoProvider);
      final userDao = _ref.read(userDaoProvider);
      
      // Sync pending changes first, then fetch latest
      await repository.syncPendingChanges();
      
      final followersResult = await repository.getFollowers(userId);
      final followingResult = await repository.getFollowing(userId);

      // Keep optimistic/pending follows visible even if server hasn't reflected them yet
      final pending = await followDao.getPendingSync();
      final pendingFollowingIds = pending
          .where((f) => f.followerId == userId)
          .map((f) => f.followingId)
          .toSet();

      final mergedFollowing = <UserModel>[...followingResult.following];
      for (final pendingId in pendingFollowingIds) {
        if (mergedFollowing.any((u) => u.id == pendingId)) continue;
        final cachedUser = await userDao.getById(pendingId);
        if (cachedUser != null) {
          mergedFollowing.add(cachedUser);
        }
      }
      
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        followers: followersResult.followers,
        following: mergedFollowing,
        followersCount: followersResult.followers.length,
        followingCount: mergedFollowing.length,
        failure: followersResult.failure ?? followingResult.failure,
        lastSyncAt: DateTime.now(),
      ));
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        failure: Failure.unknown(e.toString()),
      ));
    }
  }

  /// Follow a user
  Future<bool> followUser(String followerId, String followingId) async {
    if (_isDisposed) return false;

    _safeUpdate((s) => s.copyWith(isProcessing: true, failure: null));
    
    try {
      final repository = _ref.read(followRepositoryProvider);
      final userDao = _ref.read(userDaoProvider);
      final failure = await repository.follow(followerId, followingId);
      
      if (failure == null) {
        // Optimistically update local state immediately
        // Get the user we just followed
        final followedUser = await userDao.getById(followingId);
        if (followedUser != null && !_isDisposed) {
          _safeUpdate((s) {
            // Add to following list if not already present
            final newFollowing = List<UserModel>.from(s.following);
            if (!newFollowing.any((u) => u.id == followingId)) {
              newFollowing.add(followedUser);
            }
            return s.copyWith(
              isProcessing: false,
              following: newFollowing,
              followingCount: newFollowing.length,
            );
          });
        } else {
          _safeUpdate((s) => s.copyWith(isProcessing: false));
        }
        
        // Background refresh after a short delay to let server sync
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            loadFollowData(followerId, silent: true);
          }
        });
        
        return true;
      } else {
        _safeUpdate((s) => s.copyWith(isProcessing: false, failure: failure));
        return false;
      }
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isProcessing: false, 
        failure: Failure.unknown(e.toString()),
      ));
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String followerId, String followingId) async {
    if (_isDisposed) return false;

    _safeUpdate((s) => s.copyWith(isProcessing: true, failure: null));
    
    try {
      final repository = _ref.read(followRepositoryProvider);
      final failure = await repository.unfollow(followerId, followingId);
      
      if (failure == null) {
        // Optimistically update local state immediately
        _safeUpdate((s) {
          final newFollowing = s.following.where((u) => u.id != followingId).toList();
          return s.copyWith(
            isProcessing: false,
            following: newFollowing,
            followingCount: newFollowing.length,
          );
        });
        
        // Background refresh after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            loadFollowData(followerId, silent: true);
          }
        });
        
        return true;
      } else {
        _safeUpdate((s) => s.copyWith(isProcessing: false, failure: failure));
        return false;
      }
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isProcessing: false, 
        failure: Failure.unknown(e.toString()),
      ));
      return false;
    }
  }

  /// Toggle follow status for a user
  Future<bool> toggleFollow(String targetUserId) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) return false;
    
    final isCurrentlyFollowing = state.following.any((u) => u.id == targetUserId);
    
    if (isCurrentlyFollowing) {
      return await unfollowUser(currentUser.id, targetUserId);
    } else {
      return await followUser(currentUser.id, targetUserId);
    }
  }

  /// Check if currently following a user (from local state)
  bool isFollowing(String userId) {
    return state.following.any((u) => u.id == userId);
  }

  /// Refresh follow data
  Future<void> refresh(String userId) async {
    await loadFollowData(userId);
  }
}

// ==================== PROVIDERS ====================

/// Main follow provider for current user
final followProvider = StateNotifierProvider<FollowNotifier, FollowState>((ref) {
  final notifier = FollowNotifier(ref);
  
  // Auto-load when current user changes
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    // Use Future.microtask to avoid calling during build
    Future.microtask(() => notifier.loadFollowData(user.id));
  }
  
  return notifier;
});

/// Check if following a specific user (derived from state)
final isFollowingProvider = Provider.family<bool, String>((ref, userId) {
  final following = ref.watch(followProvider).following;
  return following.any((u) => u.id == userId);
});

/// Followers list provider
final followersListProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(followProvider).followers;
});

/// Following list provider
final followingListProvider = Provider<List<UserModel>>((ref) {
  return ref.watch(followProvider).following;
});

/// Followers count provider
final followersCountProvider = Provider<int>((ref) {
  return ref.watch(followProvider).followersCount;
});

/// Following count provider
final followingCountProvider = Provider<int>((ref) {
  return ref.watch(followProvider).followingCount;
});

// ==================== OTHER USER FOLLOW STATUS ====================

/// Follow status for viewing another user's profile
class UserFollowStatus {
  final bool isFollowing;
  final bool isFollowedBy;
  final int followersCount;
  final int followingCount;
  final bool isLoading;

  const UserFollowStatus({
    this.isFollowing = false,
    this.isFollowedBy = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isLoading = true,
  });

  UserFollowStatus copyWith({
    bool? isFollowing,
    bool? isFollowedBy,
    int? followersCount,
    int? followingCount,
    bool? isLoading,
  }) {
    return UserFollowStatus(
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy ?? this.isFollowedBy,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Provider for checking follow status of another user
final userFollowStatusProvider = FutureProvider.family<UserFollowStatus, String>((ref, userId) async {
  final repository = ref.watch(followRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) {
    return const UserFollowStatus(isLoading: false);
  }
  
  try {
    // Check follow relationships
    final isFollowing = await repository.isFollowing(currentUser.id, userId);
    final isFollowedBy = await repository.isFollowing(userId, currentUser.id);
    
    // Get counts
    final followersCount = await repository.getFollowerCount(userId);
    final followingCount = await repository.getFollowingCount(userId);
    
    return UserFollowStatus(
      isFollowing: isFollowing,
      isFollowedBy: isFollowedBy,
      followersCount: followersCount,
      followingCount: followingCount,
      isLoading: false,
    );
  } catch (e) {
    return const UserFollowStatus(isLoading: false);
  }
});
