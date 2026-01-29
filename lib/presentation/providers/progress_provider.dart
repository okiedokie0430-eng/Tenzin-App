import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/progress.dart';
import '../../core/error/failures.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

// Progress State
class ProgressState {
  final List<ProgressModel> progressList;
  final bool isLoading;
  final Failure? failure;
  final int completedCount;
  final int totalXp;

  const ProgressState({
    this.progressList = const [],
    this.isLoading = false,
    this.failure,
    this.completedCount = 0,
    this.totalXp = 0,
  });

  ProgressState copyWith({
    List<ProgressModel>? progressList,
    bool? isLoading,
    Failure? failure,
    int? completedCount,
    int? totalXp,
  }) {
    return ProgressState(
      progressList: progressList ?? this.progressList,
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
      completedCount: completedCount ?? this.completedCount,
      totalXp: totalXp ?? this.totalXp,
    );
  }

  // Convenience getters for UI
  int get completedLessonsCount => completedCount;
  int get todayXp => totalXp; // Simplified - could track daily XP separately
  
  /// Get overall progress percentage (0.0 to 1.0)
  double get currentProgress {
    if (progressList.isEmpty) return 0.0;
    final completed = progressList.where((p) => p.isCompleted).length;
    return completed / progressList.length;
  }
  
  /// Get progress percentage for a lesson by id
  Map<String, double> get lessonProgress {
    final Map<String, double> result = {};
    for (final progress in progressList) {
      if (progress.isCompleted) {
        result[progress.lessonId] = 1.0;
      } else if (progress.totalQuestions > 0) {
        result[progress.lessonId] = progress.correctAnswers / progress.totalQuestions;
      } else {
        result[progress.lessonId] = 0.0;
      }
    }
    return result;
  }

  static const initial = ProgressState();
}

// Progress Notifier
class ProgressNotifier extends StateNotifier<ProgressState> {
  final Ref _ref;
  bool _isDisposed = false;

  ProgressNotifier(this._ref) : super(ProgressState.initial);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(ProgressState Function(ProgressState) update) {
    if (!_isDisposed && mounted) {
      state = update(state);
    }
  }

  Future<void> loadProgress(String userId) async {
    if (_isDisposed) return;
    _safeUpdate((s) => s.copyWith(isLoading: true, failure: null));
    
    try {
      final repository = _ref.read(progressRepositoryProvider);
      
      final result = await repository.getUserProgress(userId);
      final completedCount = await repository.getCompletedLessonCount(userId);
      final totalXp = await repository.getTotalXP(userId);
      
      // CRITICAL FIX: Preserve completed lessons from current state
      // This prevents race conditions where DB read returns stale data
      _safeUpdate((s) {
        // Merge: keep any completed lessons from current state that might
        // not be in the new result (prevents lessons from becoming locked)
        final Map<String, ProgressModel> mergedProgress = {};
        
        // First, add all current completed lessons
        for (final p in s.progressList) {
          if (p.isCompleted) {
            mergedProgress[p.lessonId] = p;
          }
        }
        
        // Then, update with new data (newer data takes precedence)
        for (final p in result.progress) {
          final existing = mergedProgress[p.lessonId];
          if (existing == null || 
              p.lastModifiedAt >= existing.lastModifiedAt ||
              p.isCompleted) {
            mergedProgress[p.lessonId] = p;
          }
        }
        
        // Also add non-completed lessons from result that aren't in merged
        for (final p in result.progress) {
          if (!mergedProgress.containsKey(p.lessonId)) {
            mergedProgress[p.lessonId] = p;
          }
        }
        
        return s.copyWith(
          isLoading: false,
          progressList: mergedProgress.values.toList(),
          failure: result.failure,
          completedCount: completedCount,
          totalXp: totalXp,
        );
      });
    } catch (e) {
      _safeUpdate((s) => s.copyWith(
        isLoading: false,
        failure: Failure.unknown(e.toString()),
      ));
    }
  }

  Future<ProgressModel?> completeLesson({
    required String userId,
    required String lessonId,
    required int correctAnswers,
    required int totalQuestions,
    required int xpEarned,
    required int heartsRemaining,
    required int timeSpentSeconds,
  }) async {
    if (_isDisposed) return null;
    
    try {
      final repository = _ref.read(progressRepositoryProvider);
      final result = await repository.completeLesson(
        userId: userId,
        lessonId: lessonId,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        xpEarned: xpEarned,
        heartsRemaining: heartsRemaining,
        timeSpentSeconds: timeSpentSeconds,
      );

      if (result.progress != null && !_isDisposed) {
        // OPTIMISTIC UPDATE: Immediately update state with completed lesson
        // This ensures the UI reflects completion before full reload
        // NOTE: We do NOT call loadProgress() afterwards to avoid race conditions
        // where the DB read returns stale data before the write is committed
        _safeUpdate((s) {
          final updatedList = List<ProgressModel>.from(s.progressList);
          final existingIndex = updatedList.indexWhere((p) => p.lessonId == lessonId);
          if (existingIndex >= 0) {
            updatedList[existingIndex] = result.progress!;
          } else {
            updatedList.add(result.progress!);
          }
          return s.copyWith(
            progressList: updatedList,
            completedCount: s.completedCount + 1,
            totalXp: s.totalXp + xpEarned,
          );
        });
        
        // Delayed refresh to ensure DB write is committed
        // Using a slight delay to prevent race condition
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!_isDisposed) {
            loadProgress(userId);
          }
        });
      }

      return result.progress;
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
      return null;
    }
  }

  Future<ProgressModel?> startLesson(String userId, String lessonId) async {
    if (_isDisposed) return null;
    
    try {
      final repository = _ref.read(progressRepositoryProvider);
      final result = await repository.startLesson(userId, lessonId);
      return result.progress;
    } catch (e) {
      _safeUpdate((s) => s.copyWith(failure: Failure.unknown(e.toString())));
      return null;
    }
  }

  ProgressModel? getProgressForLesson(String lessonId) {
    try {
      return state.progressList.firstWhere(
        (p) => p.lessonId == lessonId,
      );
    } catch (_) {
      return null;
    }
  }

  bool isLessonCompleted(String lessonId) {
    final progress = getProgressForLesson(lessonId);
    return progress?.isCompleted ?? false;
  }

  bool isLessonInProgress(String lessonId) {
    final progress = getProgressForLesson(lessonId);
    return progress?.status == ProgressStatus.inProgress;
  }
}

// Progress Provider
final progressProvider = StateNotifierProvider<ProgressNotifier, ProgressState>((ref) {
  final notifier = ProgressNotifier(ref);
  
  // Auto-load when user changes
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    notifier.loadProgress(user.id);
  }
  
  return notifier;
});

// Convenience providers
final completedLessonCountProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).completedCount;
});

final totalXpProvider = Provider<int>((ref) {
  return ref.watch(progressProvider).totalXp;
});

final lessonProgressProvider = Provider.family<ProgressModel?, String>((ref, lessonId) {
  final progressState = ref.watch(progressProvider);
  try {
    return progressState.progressList.firstWhere(
      (p) => p.lessonId == lessonId,
    );
  } catch (_) {
    return null;
  }
});

final isLessonCompletedProvider = Provider.family<bool, String>((ref, lessonId) {
  final progress = ref.watch(lessonProgressProvider(lessonId));
  return progress?.isCompleted ?? false;
});
