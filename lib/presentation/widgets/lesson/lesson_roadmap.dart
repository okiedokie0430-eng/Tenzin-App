import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';
import '../../../core/constants/colors.dart';
import 'roadmap_node.dart';
import '../common/heart_display.dart';

/// Duolingo-style lesson roadmap view
/// Displays lessons as nodes on a winding path
/// "Одоогийн хичээл" header is FIXED at top, roadmap scrolls below
///
/// Set [showHeader] to false to render only the winding node path (e.g.
/// when the parent screen already provides its own stats header).
class LessonRoadmap extends StatefulWidget {
  final List<LessonModel> lessons;
  final Map<String, double> progressMap;
  final int hearts;
  final Duration? timeToNextHeart;
  final int xp;
  final int streak;
  final bool isSyncing;
  final int pendingSyncCount;
  final VoidCallback? onSyncTap;
  final int? activeIndex;
  final bool showHeader;
  final Function(LessonModel) onLessonTap;

  const LessonRoadmap({
    super.key,
    required this.lessons,
    required this.progressMap,
    this.hearts = 5,
    this.timeToNextHeart,
    this.xp = 0,
    this.streak = 0,
    this.isSyncing = false,
    this.pendingSyncCount = 0,
    this.onSyncTap,
    this.activeIndex,
    this.showHeader = true,
    required this.onLessonTap,
  });

  @override
  State<LessonRoadmap> createState() => _LessonRoadmapState();
}

class _LessonRoadmapState extends State<LessonRoadmap> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeNodeKey = GlobalKey();
  int? _lastScrolledIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LessonRoadmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessons.length != widget.lessons.length ||
        oldWidget.progressMap != widget.progressMap ||
        oldWidget.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToActive());
    }
  }

  void _maybeScrollToActive() {
    if (!mounted || widget.lessons.isEmpty) return;
    final targetIndex = _effectiveActiveIndex();
    if (_lastScrolledIndex != null && _lastScrolledIndex == targetIndex) return;
    final ctx = _activeNodeKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        alignment: 0.35,
        curve: Curves.easeOut,
      );
      _lastScrolledIndex = targetIndex;
    }
  }

  /// Highest unlocked lesson (next to learn): one past the highest completed.
  /// Matches the home tab semantics so locking stays consistent.
  int _highestUnlockedIndex() {
    if (widget.lessons.isEmpty) return 0;
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

  int _effectiveActiveIndex() {
    final fromParent = widget.activeIndex;
    if (fromParent != null &&
        fromParent >= 0 &&
        fromParent < widget.lessons.length) {
      return fromParent;
    }
    return _highestUnlockedIndex();
  }

  bool _isLessonLocked(int index, int highestUnlockedIndex) {
    return index > highestUnlockedIndex;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lessons.isEmpty) {
      return const Center(child: Text('Хичээлүүд байхгүй байна'));
    }

    final activeIdx = _effectiveActiveIndex();
    final highestUnlockedIdx = _highestUnlockedIndex();
    final activeLesson = (activeIdx >= 0 && activeIdx < widget.lessons.length)
        ? widget.lessons[activeIdx]
        : null;
    final completedCount = widget.lessons
        .where((l) => (widget.progressMap[l.id] ?? 0.0) >= 1.0)
        .length;
    final overallProgress = widget.lessons.isEmpty
        ? 0.0
        : completedCount / widget.lessons.length;

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToActive());

    return Stack(
      children: [
        const Positioned.fill(child: _DottedBackground()),
        CustomScrollView(
          controller: _scrollController,
          slivers: [
            if (widget.showHeader)
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopStatsRow(
                          hearts: widget.hearts,
                          timeToNextHeart: widget.timeToNextHeart,
                          xp: widget.xp,
                          streak: widget.streak,
                          isSyncing: widget.isSyncing,
                          pendingSyncCount: widget.pendingSyncCount,
                          onSyncTap: widget.onSyncTap,
                        ),
                        const SizedBox(height: 10),
                        _SectionPill(title: 'Хичээлүүд'),
                        const SizedBox(height: 14),
                        if (activeLesson != null)
                          _CurrentCard(
                            title: activeLesson.title,
                            progress: overallProgress,
                            onTap: () => widget.onLessonTap(activeLesson),
                          ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lesson = widget.lessons[index];
                    final progress = widget.progressMap[lesson.id] ?? 0.0;
                    final isLocked = _isLessonLocked(index, highestUnlockedIdx);
                    final isActive = index == activeIdx;

                    final node = RoadmapNode(
                      lesson: lesson,
                      index: index,
                      progress: progress,
                      isLocked: isLocked,
                      isActive: isActive,
                      onTap: isLocked
                          ? null
                          : () => widget.onLessonTap(lesson),
                    );

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        children: [
                          if (index > 0)
                            _buildConnectionLine(
                              context,
                              index,
                              widget.progressMap[widget.lessons[index - 1].id] ??
                                  0.0,
                            ),
                          if (isActive)
                            KeyedSubtree(
                              key: _activeNodeKey,
                              child: node,
                            )
                          else
                            node,
                          const SizedBox(height: 8),
                          _buildLessonLabel(context, lesson, isLocked,
                              progress >= 1.0, index),
                        ],
                      ),
                    );
                  },
                  childCount: widget.lessons.length,
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionLine(BuildContext context, int index, double previousProgress) {
    final isCompleted = previousProgress >= 1.0;
    
    // Calculate offset based on zigzag pattern
    final currentOffset = _calculateOffset(index);
    final previousOffset = _calculateOffset(index - 1);
    final deltaX = currentOffset - previousOffset;
    
    return SizedBox(
      height: 40,
      child: CustomPaint(
        size: const Size(double.infinity, 40),
        painter: _ConnectionPainter(
          deltaX: deltaX,
          isCompleted: isCompleted,
        ),
      ),
    );
  }

  Widget _buildLessonLabel(
    BuildContext context,
    LessonModel lesson,
    bool isLocked,
    bool isCompleted,
    int index,
  ) {
    final offsetX = _calculateOffset(index);
    
    return Transform.translate(
      offset: Offset(offsetX, 0),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 120),
        child: Column(
          children: [
            Text(
              lesson.title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isLocked
                        ? Colors.grey.shade400
                        : Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (lesson.description != null && lesson.description!.isNotEmpty)
              Text(
                lesson.description!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: isLocked
                          ? Colors.grey.shade400
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // Word count badge
            if (!isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lesson.wordCount} үг',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isCompleted ? AppColors.success : AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculateOffset(int index) {
    final amplitude = 60.0;
    final cycle = 4;
    final position = index % cycle;
    
    switch (position) {
      case 0:
        return 0;
      case 1:
        return amplitude;
      case 2:
        return 0;
      case 3:
        return -amplitude;
      default:
        return 0;
    }
  }
}

class _TopStatsRow extends StatelessWidget {
  final int hearts;
  final Duration? timeToNextHeart;
  final int xp;
  final int streak;
  final bool isSyncing;
  final int pendingSyncCount;
  final VoidCallback? onSyncTap;

  const _TopStatsRow({
    required this.hearts,
    required this.timeToNextHeart,
    required this.xp,
    required this.streak,
    required this.isSyncing,
    required this.pendingSyncCount,
    required this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _StatPill(
            child: HeartDisplay(
              currentHearts: hearts,
              maxHearts: 5,
              timeToNextHeart: timeToNextHeart,
            ),
          ),
          const SizedBox(width: 10),
          _StatPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code_rounded, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '$xp',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _StatPill(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department_rounded,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '$streak',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (isSyncing || pendingSyncCount > 0) ...[
            const SizedBox(width: 10),
            _StatPill(
              onTap: onSyncTap,
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
                        Icon(Icons.sync_rounded,
                            size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 6),
                        Text(
                          '$pendingSyncCount',
                          style: theme.textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _StatPill({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withOpacity(0.16),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  final String title;

  const _SectionPill({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.16)),
      ),
      child: Row(
        children: [
          Icon(Icons.view_list_rounded,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _CurrentCard extends StatelessWidget {
  final String title;
  final double progress;
  final VoidCallback onTap;

  const _CurrentCard({
    required this.title,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (progress.clamp(0.0, 1.0) * 100).round();

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.16)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      strokeWidth: 6,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest.withOpacity(0.8),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '$pct%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedBackground extends StatelessWidget {
  const _DottedBackground();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      painter: _DottedBackgroundPainter(
        color: theme.colorScheme.onSurfaceVariant.withOpacity(0.06),
      ),
    );
  }
}

class _DottedBackgroundPainter extends CustomPainter {
  final Color color;

  const _DottedBackgroundPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const spacing = 26.0;
    const radius = 1.25;

    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DottedBackgroundPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Custom painter for connection lines between nodes
class _ConnectionPainter extends CustomPainter {
  final double deltaX;
  final bool isCompleted;

  _ConnectionPainter({
    required this.deltaX,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted
          ? AppColors.progressComplete.withOpacity(0.65)
          : AppColors.divider.withOpacity(0.70)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerX = size.width / 2;
    final startX = centerX - deltaX / 2;
    final endX = centerX + deltaX / 2;
    
    // Create a curved path
    path.moveTo(startX, 0);
    path.quadraticBezierTo(
      centerX,
      size.height / 2,
      endX,
      size.height,
    );
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConnectionPainter oldDelegate) {
    return deltaX != oldDelegate.deltaX || isCompleted != oldDelegate.isCompleted;
  }
}
