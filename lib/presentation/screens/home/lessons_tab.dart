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
import '../../widgets/common/heart_display.dart';
import '../../widgets/lesson/lesson_pathway.dart';
import '../streaks/streak_overview_screen.dart';
// lesson_picking_sheet removed: lessons open directly now

// Home-tab palette is monochrome for now (theme onSurface greys).
// TODO(accent): add the chosen brand accent here and thread it through
// the pills, current-lesson card and pathway nodes.

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
            // UI: Dictionary FAB - floats above the bottom dock
            Positioned(
              right: 16,
              bottom: 104,
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
        // UI: Winding lesson pathway (tried snippet design, wired to real data)
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (user != null) {
                await ref.read(lessonsProvider.notifier).loadLessons();
              }
            },
            child: LessonPathway(
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
                    // TODO(accent): monochrome for now; tint with brand accent later.
                    iconColor: theme.colorScheme.onSurface,
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
                      iconColor: theme.colorScheme.onSurface,
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
              color: theme.colorScheme.onSurface,
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Theme.of(context).colorScheme.onSurface,
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
                              color:
                                  Theme.of(context).colorScheme.onSurface,
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
                    color: index < currentHearts
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey.shade300,
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
    // Monochrome current-lesson card (accent TBD).
    // TODO(accent): restore brand tint using the chosen accent color.
    final onSurface = theme.colorScheme.onSurface;
    final onContrast = theme.colorScheme.surface;

    return Material(
      color: onSurface.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: onSurface.withOpacity(0.18),
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
                      backgroundColor: onSurface.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        onSurface,
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: onSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: onContrast,
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
                        color: onSurface,
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
                  color: onSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: onContrast,
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
    final theme = Theme.of(context);
    return FloatingActionButton.extended(
      heroTag: 'dictionary_fab',
      onPressed: onPressed,
      backgroundColor: theme.colorScheme.onSurface,
      foregroundColor: theme.colorScheme.surface,
      icon: const Icon(Icons.menu_book_rounded),
      label: const Text('Толь'),
    );
  }
}
