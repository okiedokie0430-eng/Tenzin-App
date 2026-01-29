// =============================================================================
// Lessons Tab - Continuous Vertical Learning Structure
// =============================================================================
// UI-ONLY REVAMP: All logic, state, navigation, and data flow are preserved.
// PERFORMANCE OPTIMIZED: Minimal re-renders, efficient list virtualization
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/heart_provider.dart';
import '../../providers/sync_provider.dart';
import '../../../data/models/lesson.dart';
import '../../../core/constants/app_colors.dart' as app;
import '../../widgets/common/heart_display.dart';
import '../streaks/streak_overview_screen.dart';
// lesson_picking_sheet removed: lessons open directly now

// =============================================================================
// PERFORMANCE: Pre-computed colors to avoid repeated allocations
// =============================================================================
class _LessonColors {
  static const Color completedGreen = Color(0xFF38A169);
  static const Color lockedGray = Color(0xFF9CA3AF);
  static const Color lockedGrayLight = Color(0xFFE5E7EB);
  static const Color heartRed = Color(0xFFE53E3E);
  static const Color xpYellow = Color(0xFFECC94B);
  static const Color streakOrange = Color(0xFFED8936);
}

// =============================================================================
// LessonsTab - Main Widget (LOGIC PRESERVED FROM _LearnTab)
// =============================================================================

class LessonsTab extends ConsumerStatefulWidget {
  const LessonsTab({super.key});

  @override
  ConsumerState<LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends ConsumerState<LessonsTab> {
  @override
  Widget build(BuildContext context) {
    // LOGIC PRESERVED: Same provider watches as original _LearnTab
    final user = ref.watch(currentUserProvider);
    final lessonsState = ref.watch(lessonsProvider);
    // avoid watching heartProvider here to prevent frequent rebuilds of the whole list
    // heart updates (timers) are handled inside the header to limit rebuild scope
    final progressState = ref.watch(progressProvider);
    final syncState = ref.watch(syncProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _buildContent(
              context,
              ref,
              lessonsState,
              progressState,
              user,
              syncState,
              isOnline,
            ),
            // UI: Sync indicator chip
            if (syncState.isSyncing || syncState.pendingCount > 0)
              Positioned(
                top: 12,
                right: 12,
                child: _SyncChip(
                  isSyncing: syncState.isSyncing,
                  pending: syncState.pendingCount,
                  onTap: syncState.isSyncing
                      ? null
                      : () {
                          // LOGIC PRESERVED: Same sync trigger
                          ref.read(syncProvider.notifier).syncAll();
                        },
                ),
              ),
            // UI: Dictionary FAB - positioned at bottom right, snapped near nav bar
            Positioned(
              right: 16,
              bottom: 8,
              child: _DictionaryFab(
                onPressed: () {
                  // LOGIC PRESERVED: Same navigation
                  Navigator.of(context).pushNamed(AppRouter.dictionary);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    LessonsState lessonsState,
    ProgressState progressState,
    user,
    SyncState syncState,
    bool isOnline,
  ) {
    // LOGIC PRESERVED: Loading state handling
    if (lessonsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // LOGIC PRESERVED: Error state handling
    if (lessonsState.failure != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(lessonsState.failure!.message),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(lessonsProvider.notifier).loadLessons();
              },
              child: const Text('Дахин оролдох'),
            ),
          ],
        ),
      );
    }

    final lessons = lessonsState.lessons;

    // Lesson opening now navigates directly; sheet removed.

    // LOGIC PRESERVED: Active lesson detection
    final activeIndex = _findActiveIndex(
      lessons: lessons,
      progressMap: progressState.lessonProgress,
    );
    final currentLesson = (activeIndex >= 0 && activeIndex < lessons.length)
        ? lessons[activeIndex]
        : null;
    final currentProgress = currentLesson == null
        ? 0.0
        : (progressState.lessonProgress[currentLesson.id] ?? 0.0);

    // LOGIC PRESERVED: Direct lesson opening
    void openLessonDirect(LessonModel lesson) {
      if (ref.read(heartProvider).hearts > 0) {
        Navigator.of(context).pushNamed(
          '/lesson',
          arguments: lesson.id,
        );
      } else {
        _showNoHeartsDialog(context, ref);
      }
    }

    return Column(
      children: [
        // UI REVAMPED: New header design
        _LessonsHeader(
          user: user,
          streakEnabled: isOnline,
          currentLesson: currentLesson,
          currentProgress: currentProgress,
          onCurrentLessonTap: currentLesson == null
              ? null
              : () => openLessonDirect(currentLesson),
        ),
        // UI REVAMPED: Continuous vertical lesson list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                await ref.read(lessonsProvider.notifier).loadLessons();
              }
            },
            child: _ContinuousLessonList(
                  lessons: lessons,
                  progressMap: progressState.lessonProgress,
                  activeIndex: activeIndex,
                  onLessonTap: openLessonDirect,
                ),
          ),
        ),
      ],
    );
  }

  // LOGIC PRESERVED: No hearts dialog
  void _showNoHeartsDialog(BuildContext context, WidgetRef ref) {
    final heartState = ref.read(heartProvider);

    showDialog(
      context: context,
      builder: (context) => NoHeartsDialog(
        timeToNextHeart: heartState.timeToNextHeart,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  // FIXED: Active index is the HIGHEST UNLOCKED lesson (next to learn)
  // This ensures current lesson points to the most advanced available lesson
  static int _findActiveIndex({
    required List<LessonModel> lessons,
    required Map<String, double> progressMap,
  }) {
    if (lessons.isEmpty) return 0;

    int highestCompletedIndex = -1;

    // Scan from the END to find the HIGHEST completed lesson efficiently
    for (var i = lessons.length - 1; i >= 0; i--) {
      final progress = progressMap[lessons[i].id] ?? 0.0;
      if (progress >= 1.0) {
        highestCompletedIndex = i;
        break; // Found the highest, stop searching
      }
    }

    // The active lesson is the next one after the highest completed
    // If no lessons completed, it's the first lesson
    // If all lessons completed, it's the last lesson
    if (highestCompletedIndex < 0) {
      return 0; // First lesson
    }

    // Return the next lesson index (capped at last lesson)
    return (highestCompletedIndex + 1).clamp(0, lessons.length - 1);
  }
}

// =============================================================================
// UI COMPONENTS - REVAMPED DESIGN
// =============================================================================

/// Revamped header with stats pills and current lesson card
class _LessonsHeader extends ConsumerWidget {
  final dynamic user;
  final bool streakEnabled;
  final LessonModel? currentLesson;
  final double currentProgress;
  final VoidCallback? onCurrentLessonTap;

  const _LessonsHeader({
    required this.user,
    required this.streakEnabled,
    required this.currentLesson,
    required this.currentProgress,
    required this.onCurrentLessonTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final heartState = ref.watch(heartProvider);
    final xp = user?.totalXp ?? 0;
    final streak = user?.streak ?? 0;

    // PERFORMANCE: Removed heavy boxShadow, using simple border instead
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Hearts Pill with Dropdown
                Expanded(
                  child: _HeartStatPill(
                    hearts: heartState.hearts,
                    maxHearts: 5,
                    timeToNextHeart: heartState.timeToNextHeart,
                  ),
                ),
                const SizedBox(width: 10),
                // XP Pill
                Expanded(
                  child: _StatPill(
                    icon: Icons.bolt_rounded,
                    iconColor: _LessonColors.xpYellow,
                    value: '$xp',
                    subtitle: 'XP',
                  ),
                ),
                const SizedBox(width: 10),
                // Streak Pill (tappable to open overview)
                Expanded(
                  child: GestureDetector(
                    onTap: streakEnabled
                        ? () {
                            Navigator.of(context).push(CupertinoPageRoute(
                              builder: (_) => const StreakOverviewScreen(),
                            ));
                          }
                        : null,
                    child: _StatPill(
                      icon: Icons.local_fire_department_rounded,
                      iconColor: _LessonColors.streakOrange,
                      value: '$streak',
                      subtitle: 'Streak',
                      enabled: streakEnabled,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Current Lesson Card
          if (currentLesson != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _CurrentLessonCard(
                lesson: currentLesson!,
                progress: currentProgress,
                onTap: onCurrentLessonTap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Individual stat pill widget
class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String subtitle;
  final bool enabled;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.subtitle,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = enabled ? 1.0 : 0.4;

    return Opacity(
      opacity: opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Heart stat pill with dropdown - matches _StatPill style
class _HeartStatPill extends StatefulWidget {
  final int hearts;
  final int maxHearts;
  final Duration? timeToNextHeart;

  const _HeartStatPill({
    required this.hearts,
    this.maxHearts = 5,
    this.timeToNextHeart,
  });

  @override
  State<_HeartStatPill> createState() => _HeartStatPillState();
}

class _HeartStatPillState extends State<_HeartStatPill> 
    with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isDropdownVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<double>(begin: -10, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isDropdownVisible) {
      _hideDropdown();
    } else {
      _showDropdown();
    }
  }

  void _showDropdown() {
    if (_isDropdownVisible) return;

    final RenderBox? renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    const dropdownWidth = 280.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final safeLeft = MediaQuery.of(context).padding.left;
    final safeRight = MediaQuery.of(context).padding.right;
    const horizontalMargin = 12.0;

    var left = offset.dx;
    final maxLeft = screenWidth - safeRight - horizontalMargin - dropdownWidth;
    final minLeft = safeLeft + horizontalMargin;
    if (left > maxLeft) left = maxLeft;
    if (left < minLeft) left = minLeft;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Transparent backdrop to close dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideDropdown,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Dropdown content
          Positioned(
            top: offset.dy + size.height + 8,
            left: left,
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: child,
                ),
              ),
              child: _HeartDropdownContent(
                currentHearts: widget.hearts,
                maxHearts: widget.maxHearts,
                timeToNextHeart: widget.timeToNextHeart,
                onClose: _hideDropdown,
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isDropdownVisible = true;
    _animationController.forward();
  }

  void _hideDropdown() {
    if (!_isDropdownVisible) return;
    _animationController.reverse().then((_) {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isDropdownVisible = false;
  }

  static String _formatDuration(Duration? d) {
    if (d == null) return '--:--';
    final total = d.inSeconds.clamp(0, 24 * 3600);
    final m = (total ~/ 60).toString().padLeft(2, '0');
    final s = (total % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      key: _key,
      onTap: _toggleDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_rounded,
              size: 20,
              color: _LessonColors.heartRed,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.hearts}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                Text(
                  widget.hearts >= widget.maxHearts
                      ? 'Дүүрэн'
                      : _formatDuration(widget.timeToNextHeart),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Heart dropdown content widget for _HeartStatPill
class _HeartDropdownContent extends StatelessWidget {
  final int currentHearts;
  final int maxHearts;
  final Duration? timeToNextHeart;
  final VoidCallback onClose;

  const _HeartDropdownContent({
    required this.currentHearts,
    required this.maxHearts,
    required this.timeToNextHeart,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with hearts icon and count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _LessonColors.heartRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: _LessonColors.heartRed,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Зүрх',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '$currentHearts / $maxHearts',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: _LessonColors.heartRed,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Heart row visualization
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                maxHearts,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < currentHearts ? Icons.favorite : Icons.favorite_border,
                    color: index < currentHearts ? _LessonColors.heartRed : Colors.grey.shade300,
                    size: 28,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Time to next heart
            if (currentHearts < maxHearts && timeToNextHeart != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Дараагийн зүрх: ${_formatDuration(timeToNextHeart!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Info text
            Text(
              'Зүрх нь хичээл дээр алдаа гаргахад хасагдана. 20 минут тутамд 1 зүрх нөхөгдөнө.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutesм $secondsс';
  }
}

/// Current lesson card with progress indicator
class _CurrentLessonCard extends StatelessWidget {
  final LessonModel lesson;
  final double progress;
  final VoidCallback? onTap;

  const _CurrentLessonCard({
    required this.lesson,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: app.AppColors.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: app.AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Circular Progress with Icon
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 4,
                      backgroundColor: app.AppColors.primary.withOpacity(0.15),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        app.AppColors.primary,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: app.AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Lesson info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Үргэлжлүүлэх',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: app.AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toInt()}% дууссан',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: app.AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// CONTINUOUS VERTICAL LESSON LIST - PERFORMANCE OPTIMIZED
// =============================================================================

class _ContinuousLessonList extends StatefulWidget {
  final List<LessonModel> lessons;
  final Map<String, double> progressMap;
  final int activeIndex;
  final ValueChanged<LessonModel> onLessonTap;

  const _ContinuousLessonList({
    required this.lessons,
    required this.progressMap,
    required this.activeIndex,
    required this.onLessonTap,
  });

  @override
  State<_ContinuousLessonList> createState() => _ContinuousLessonListState();

}


class _ContinuousLessonListState extends State<_ContinuousLessonList> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _itemKeys = {};
  int? _lastScrolledIndex;

  // Approximate item height used by the painter for positioning
  static const double _approxItemHeight = 104.0;
  static const double _listTopPadding = 8.0;


  int _findHighestUnlockedIndex() {
    int highestCompletedIndex = -1;
    for (var i = widget.lessons.length - 1; i >= 0; i--) {
      final progress = widget.progressMap[widget.lessons[i].id] ?? 0.0;
      if (progress >= 1.0) {
        highestCompletedIndex = i;
        break;
      }
    }
    if (highestCompletedIndex < 0) return 0;
    return (highestCompletedIndex + 1).clamp(0, widget.lessons.length - 1);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToUnlocked());
  }

  @override
  void didUpdateWidget(covariant _ContinuousLessonList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If lessons changed or progress changed, consider scrolling to newest unlocked
    if (oldWidget.lessons.length != widget.lessons.length || oldWidget.progressMap != widget.progressMap) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToUnlocked());
    }
  }

  void _maybeScrollToUnlocked() {
    if (widget.lessons.isEmpty) return;
    final targetIndex = _findHighestUnlockedIndex();
    if (_lastScrolledIndex != null && _lastScrolledIndex == targetIndex) return;

    // If we have a key for the target item, try to ensure it's visible at the top.
    final key = _itemKeys[targetIndex];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.0,
        curve: Curves.easeOut,
      );
      _lastScrolledIndex = targetIndex;
      return;
    }

    // Fallback: approximate item height and jump to offset
    const approxItemHeight = 104.0; // average between 100 and 108
    final offset = (targetIndex * approxItemHeight).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    ).then((_) => _lastScrolledIndex = targetIndex);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Reuse the original build logic but hook controller and keys
  @override
  Widget build(BuildContext context) {
    if (widget.lessons.isEmpty) {
      return const Center(child: Text('Хичээлүүд байхгүй байна'));
    }

    final highestUnlockedIndex = _findHighestUnlockedIndex();

    return Stack(
      children: [
        // Connector layer painted once for visible items
        Positioned.fill(
          child: CustomPaint(
            painter: LessonConnectorPainter(
              lessons: widget.lessons,
              progressMap: widget.progressMap,
              scrollController: _scrollController,
              itemHeight: _ContinuousLessonListState._approxItemHeight,
              topPadding: _ContinuousLessonListState._listTopPadding,
              theme: Theme.of(context),
            ),
          ),
        ),

        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: widget.lessons.length,
          cacheExtent: 300,
          itemBuilder: (context, index) {
        final lesson = widget.lessons[index];
        // reuse the helper by creating a temporary _LessonState
        final progress = widget.progressMap[lesson.id] ?? 0.0;
        final isCompleted = progress >= 1.0;
        final isLocked = index > highestUnlockedIndex;
        final isActive = index == widget.activeIndex;

        Color statusColor;
        Color lineColor;
        Color nextLineColor;

        if (isLocked) {
          statusColor = _LessonColors.lockedGray;
          lineColor = _LessonColors.lockedGrayLight;
        } else if (isCompleted) {
          statusColor = _LessonColors.completedGreen;
          lineColor = _LessonColors.completedGreen.withOpacity(0.4);
        } else if (isActive) {
          statusColor = app.AppColors.primary;
          lineColor = app.AppColors.primary.withOpacity(0.4);
        } else {
          statusColor = app.AppColors.primary.withOpacity(0.7);
          lineColor = app.AppColors.primary.withOpacity(0.3);
        }

        if (index < widget.lessons.length - 1) {
          final nextProgress = widget.progressMap[widget.lessons[index + 1].id] ?? 0.0;
          final nextIsCompleted = nextProgress >= 1.0;
          final nextIsLocked = (index + 1) > highestUnlockedIndex;

          if (nextIsLocked) {
            nextLineColor = _LessonColors.lockedGrayLight;
          } else if (nextIsCompleted) {
            nextLineColor = _LessonColors.completedGreen.withOpacity(0.4);
          } else {
            nextLineColor = app.AppColors.primary.withOpacity(0.4);
          }
        } else {
          nextLineColor = lineColor;
        }

        final state = _LessonState(
          progress: progress,
          isCompleted: isCompleted,
          isLocked: isLocked,
          isActive: isActive,
          statusColor: statusColor,
          lineColor: lineColor,
          nextLineColor: nextLineColor,
        );

        // Assign a key for the target index so we can locate it later
        final key = index == highestUnlockedIndex ? (_itemKeys[index] ??= GlobalKey()) : null;

        return RepaintBoundary(
          key: key,
          child: _LessonCard(
            lesson: lesson,
            index: index,
            progress: state.progress,
            isLocked: state.isLocked,
            isActive: state.isActive,
            isCompleted: state.isCompleted,
            isFirst: index == 0,
            isLast: index == widget.lessons.length - 1,
            statusColor: state.statusColor,
            lineColor: state.lineColor,
            nextLineColor: state.nextLineColor,
            onTap: state.isLocked ? null : () => widget.onLessonTap(lesson),
          ),
        );
      },
    ),
      ],
    );
  }
}

/// Pre-computed lesson state for performance
class _LessonState {
  final double progress;
  final bool isCompleted;
  final bool isLocked;
  final bool isActive;
  final Color statusColor;
  final Color lineColor;
  final Color nextLineColor;

  const _LessonState({
    required this.progress,
    required this.isCompleted,
    required this.isLocked,
    required this.isActive,
    required this.statusColor,
    required this.lineColor,
    required this.nextLineColor,
  });
}

/// Painter that draws the vertical connector between lesson nodes.
class LessonConnectorPainter extends CustomPainter {
  final List<LessonModel> lessons;
  final Map<String, double> progressMap;
  final ScrollController scrollController;
  final double itemHeight;
  final double topPadding;
  final ThemeData theme;

  LessonConnectorPainter({
    required this.lessons,
    required this.progressMap,
    required this.scrollController,
    required this.itemHeight,
    required this.topPadding,
    required this.theme,
  }) : super(repaint: scrollController);

  static const double _lineX = 40.0; // x position of the connector center
  static const double _lineWidth = 3.0;
  // Stop drawing the connector at this lesson number (1-based)
  static const int _endAtLessonNumber = 54;

  Color _segmentColorFor(int index, int highestUnlockedIndex) {
    // Completed segments are green, unlocked (next) segments are primary, locked are gray
    final progress = progressMap[lessons[index].id] ?? 0.0;
    final nextProgress = (index + 1) < lessons.length ? (progressMap[lessons[index + 1].id] ?? 0.0) : 0.0;
    if (progress >= 1.0 && nextProgress >= 1.0) {
      return _LessonColors.completedGreen;
    }
    if (index < highestUnlockedIndex) {
      return app.AppColors.primary;
    }
    return _LessonColors.lockedGrayLight;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (lessons.isEmpty) return;

    final highestUnlockedIndex = _computeHighestUnlockedIndex();

    final paint = Paint()
      ..strokeWidth = _lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // visible viewport offsets
    final offset = scrollController.hasClients ? scrollController.offset : 0.0;
    // Clip drawing to the visible list area to avoid lines "penetrating"
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Determine last node index to draw up to (0-based)
    int lastNodeIndex = lessons.length - 1;
    final int maxNode = (_endAtLessonNumber - 1).clamp(0, lessons.length - 1);
    if (lastNodeIndex > maxNode) lastNodeIndex = maxNode;

    // Draw segments between node i and i+1 for i in [0, lastNodeIndex-1]
    for (var i = 0; i < lastNodeIndex; i++) {
      final startY = topPadding + (i * itemHeight) + (itemHeight / 2) - offset;
      final endY = topPadding + ((i + 1) * itemHeight) + (itemHeight / 2) - offset;

      // cheap skip if completely outside viewport
      if (endY < 0 && startY < 0) continue;
      if (startY > size.height && endY > size.height) continue;

      // Clamp the drawn segment to the visible bounds to prevent overshoot
      final drawStart = startY.clamp(0.0, size.height);
      final drawEnd = endY.clamp(0.0, size.height);
      if (drawEnd <= drawStart) continue;

      paint.color = _segmentColorFor(i, highestUnlockedIndex);

      // subtle glow for completed segments (drawn using clamped coords)
      if (paint.color == _LessonColors.completedGreen) {
        final glow = Paint()
          ..color = paint.color.withOpacity(0.16)
          ..strokeWidth = _lineWidth * 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(_lineX, drawStart), Offset(_lineX, drawEnd), glow);
      }

      canvas.drawLine(Offset(_lineX, drawStart), Offset(_lineX, drawEnd), paint);
    }

    canvas.restore();
  }

  int _computeHighestUnlockedIndex() {
    int highestCompletedIndex = -1;
    for (var i = lessons.length - 1; i >= 0; i--) {
      final progress = progressMap[lessons[i].id] ?? 0.0;
      if (progress >= 1.0) {
        highestCompletedIndex = i;
        break;
      }
    }
    if (highestCompletedIndex < 0) return 0;
    return (highestCompletedIndex + 1).clamp(0, lessons.length - 1);
  }

  @override
  bool shouldRepaint(covariant LessonConnectorPainter oldDelegate) {
    return oldDelegate.lessons != lessons || oldDelegate.progressMap != progressMap || oldDelegate.scrollController != scrollController;
  }
}

/// Individual lesson card - PERFORMANCE: Simplified, no IntrinsicHeight
class _LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final int index;
  final double progress;
  final bool isLocked;
  final bool isActive;
  final bool isCompleted;
  final bool isFirst;
  final bool isLast;
  final Color statusColor;
  final Color lineColor;
  final Color nextLineColor;
  final VoidCallback? onTap;

  const _LessonCard({
    required this.lesson,
    required this.index,
    required this.progress,
    required this.isLocked,
    required this.isActive,
    required this.isCompleted,
    required this.isFirst,
    required this.isLast,
    required this.statusColor,
    required this.lineColor,
    required this.nextLineColor,
    required this.onTap,
  });

  IconData _getTypeIcon() {
    switch (lesson.type) {
      case 'alphabet':
        return Icons.abc;
      case 'vocabulary':
        return Icons.book_rounded;
      case 'grammar':
        return Icons.rule_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'listening':
        return Icons.headphones_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      case 'writing':
        return Icons.edit_rounded;
      case 'culture':
        return Icons.temple_buddhist_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // PERFORMANCE: Fixed height for consistent layout, no IntrinsicHeight
    final cardHeight = isActive ? 108.0 : 100.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: cardHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left: Progress Line & Circle - FIXED: Gradient transitions
            SizedBox(
              width: 48,
              child: _buildProgressIndicator(cardHeight),
            ),
            const SizedBox(width: 12),
            // Right: Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildCard(context, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// FIXED: Progress indicator with smooth gradient transitions between states
  Widget _buildProgressIndicator(double cardHeight) {
    final circleSize = isActive ? 42.0 : 36.0;
    final circleTop = (cardHeight - circleSize) / 2;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Top line segment (from top to circle center)
        if (!isFirst)
          Positioned(
            top: 0,
            left: 22.5, // Center of 48px width, minus half line width
            child: Container(
              width: 3,
              height: circleTop + (circleSize / 2),
              decoration: BoxDecoration(
                // Use solid color for top segment (matches current lesson)
                color: lineColor,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        // Bottom line segment (from circle center to bottom)
        if (!isLast)
          Positioned(
            top: circleTop + (circleSize / 2),
            left: 22.5,
            child: Container(
              width: 3,
              height: cardHeight - circleTop - (circleSize / 2),
              decoration: BoxDecoration(
                // FIXED: Gradient transition to next lesson's color
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [lineColor, nextLineColor],
                ),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
          ),
        // Circle indicator - positioned absolutely to avoid gaps
        Positioned(
          top: circleTop,
          child: Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: isLocked
                  ? _LessonColors.lockedGrayLight
                  : isCompleted
                      ? statusColor
                      : statusColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: statusColor,
                width: isActive ? 3 : 2,
              ),
            ),
            child: Icon(
              isLocked
                  ? Icons.lock_rounded
                  : isCompleted
                      ? Icons.check_rounded
                      : _getTypeIcon(),
              size: isActive ? 22 : 18,
              color: isLocked
                  ? _LessonColors.lockedGray
                  : isCompleted
                      ? Colors.white
                      : statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, ThemeData theme) {
    final cardColor =
        isActive ? statusColor.withOpacity(0.06) : theme.colorScheme.surface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? statusColor.withOpacity(0.3)
                  : theme.dividerColor.withOpacity(0.12),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lesson number badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Хичээл ${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      lesson.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isLocked
                            ? theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.6)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    // Progress bar for in-progress lessons (no description to save space)
                    if (!isLocked && progress > 0 && !isCompleted) ...[
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: statusColor.withOpacity(0.15),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right side action indicator
              _buildActionIndicator(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionIndicator(ThemeData theme) {
    if (isLocked) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _LessonColors.lockedGrayLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.lock_rounded,
          color: _LessonColors.lockedGray,
          size: 20,
        ),
      );
    }

    if (isCompleted) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _LessonColors.completedGreen,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 22,
        ),
      );
    }

    if (isActive) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: app.AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color: statusColor,
        size: 16,
      ),
    );
  }
}

// =============================================================================
// SUPPORTING WIDGETS (LOGIC PRESERVED)
// =============================================================================

/// Sync status chip
class _SyncChip extends StatelessWidget {
  final bool isSyncing;
  final int pending;
  final VoidCallback? onTap;

  const _SyncChip({
    required this.isSyncing,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.7),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: isSyncing
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$pending',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Dictionary floating action button - always shows icon and text
class _DictionaryFab extends StatelessWidget {
  final VoidCallback onPressed;

  const _DictionaryFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'dictionary_fab',
      onPressed: onPressed,
      icon: const Icon(Icons.menu_book_rounded),
      label: const Text('Толь'),
    );
  }
}
