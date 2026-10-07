// =============================================================================
// LessonPathway - Duolingo-style winding lesson path
// =============================================================================
// Ported from the user-provided snippet (LessonPathwayScreen) and adapted:
// - Fixed broken import line (`import 'import:flutter/rendering.dart'`)
// - Hardcoded demo lessons replaced with real LessonModel data
// - Node state (completed/unlocked/locked) derived from progressMap
// - Labels + background themed for light/dark mode
// - Tappable nodes (locked nodes ignore taps), auto-scroll to active lesson
//
// Layout math is shared between the item builder and the painter so the
// dashed connector always passes through the node centers:
//   nodeCenterY(i) = topPadding + i * itemHeight + circleCenterOffset
//   nodeCenterX(i) = width / 2 + alignmentFraction(i) * width / 2
// =============================================================================

import 'package:flutter/material.dart';

import '../../../data/models/lesson.dart';

/// Winding lesson pathway driven by real lesson data.
class LessonPathway extends StatefulWidget {
  final List<LessonModel> lessons;
  final Map<String, double> progressMap;
  final int? activeIndex;
  final ValueChanged<LessonModel> onLessonTap;

  const LessonPathway({
    super.key,
    required this.lessons,
    required this.progressMap,
    this.activeIndex,
    required this.onLessonTap,
  });

  // Layout constants shared with [PathConnectingPainter].
  static const double itemHeight = 150.0;
  static const double topPadding = 24.0;
  static const double circleDiameter = 72.0;
  static const double circleGap = 8.0;
  static const double labelHeight = 44.0;

  /// Vertical offset of a node circle center inside its item slot.
  static double get circleCenterOffset =>
      (itemHeight - (circleDiameter + circleGap + labelHeight)) / 2 +
      circleDiameter / 2;

  /// Horizontal alignment fraction per index: center, left, center, right...
  /// Must mirror the Alignment used in the item builder.
  static double alignmentFraction(int index) {
    switch (index % 4) {
      case 1:
        return -0.5;
      case 3:
        return 0.5;
      case 0:
      case 2:
      default:
        return 0.0;
    }
  }

  @override
  State<LessonPathway> createState() => _LessonPathwayState();
}

class _LessonPathwayState extends State<LessonPathway> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _activeNodeKey = GlobalKey();
  int? _lastScrolledIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant LessonPathway oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lessons.length != widget.lessons.length ||
        oldWidget.progressMap != widget.progressMap ||
        oldWidget.activeIndex != widget.activeIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToActive());
    }
  }

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

  void _maybeScrollToActive() {
    if (!mounted || widget.lessons.isEmpty) return;
    final targetIndex = _effectiveActiveIndex();
    if (_lastScrolledIndex != null && _lastScrolledIndex == targetIndex) return;
    final ctx = _activeNodeKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        alignment: 0.4,
        curve: Curves.easeOut,
      );
      _lastScrolledIndex = targetIndex;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'alphabet':
        return Icons.abc;
      case 'vocabulary':
        return Icons.menu_book;
      case 'grammar':
        return Icons.g_translate;
      case 'reading':
        return Icons.chrome_reader_mode;
      case 'listening':
        return Icons.headphones_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      case 'writing':
        return Icons.edit_rounded;
      case 'culture':
        return Icons.home;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.lessons.isEmpty) {
      return const Center(child: Text('Хичээлүүд байхгүй байна'));
    }

    final theme = Theme.of(context);
    final activeIdx = _effectiveActiveIndex();
    final highestUnlockedIdx = _highestUnlockedIndex();

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToActive());

    return Stack(
      children: [
        // Background connecting path painter (dashed bezier through nodes)
        Positioned.fill(
          child: CustomPaint(
            painter: PathConnectingPainter(
              nodeCount: widget.lessons.length,
              color: theme.colorScheme.outline.withOpacity(0.55),
            ),
          ),
        ),
        // Scrollable list of aligned nodes
        ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(
            top: LessonPathway.topPadding,
            bottom: 140,
          ),
          itemCount: widget.lessons.length,
          itemBuilder: (context, index) {
            final lesson = widget.lessons[index];
            final progress = widget.progressMap[lesson.id] ?? 0.0;
            final isCompleted = progress >= 1.0;
            final isLocked = index > highestUnlockedIdx;
            final isActive = index == activeIdx;
            final fraction = LessonPathway.alignmentFraction(index);

            final Alignment alignment;
            if (fraction == 0.0) {
              alignment = Alignment.center;
            } else {
              alignment = Alignment(fraction, 0);
            }

            final node = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PathwayNodeButton(
                  icon: _iconForType(lesson.type),
                  isCompleted: isCompleted,
                  isLocked: isLocked,
                  isActive: isActive,
                  onTap: isLocked ? null : () => widget.onLessonTap(lesson),
                ),
                const SizedBox(height: LessonPathway.circleGap),
                SizedBox(
                  height: LessonPathway.labelHeight,
                  width: 140,
                  child: Text(
                    lesson.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isLocked
                          ? theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.55)
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            );

            return Container(
              height: LessonPathway.itemHeight,
              alignment: alignment,
              child: isActive
                  ? KeyedSubtree(key: _activeNodeKey, child: node)
                  : node,
            );
          },
        ),
      ],
    );
  }
}

class _PathwayNodeButton extends StatelessWidget {
  final IconData icon;
  final bool isCompleted;
  final bool isLocked;
  final bool isActive;
  final VoidCallback? onTap;

  const _PathwayNodeButton({
    required this.icon,
    required this.isCompleted,
    required this.isLocked,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Monochrome node system (accent TBD): completed/active = solid
    // on-surface fill, locked = tonal grey.
    // TODO(accent): tint the active node with the chosen brand accent here.
    final Color solidFill = isDark ? Colors.white : const Color(0xFF1A1A1E);
    final Color solidIcon = isDark ? const Color(0xFF1A1A1E) : Colors.white;
    final Color lockedFill =
        isDark ? const Color(0xFF2A2A30) : const Color(0xFFE4E4E7);
    final Color lockedIcon =
        isDark ? const Color(0xFF8E8E99) : const Color(0xFF9E9E9E);

    final bool filled = isCompleted || !isLocked;
    final Color buttonColor = filled ? solidFill : lockedFill;
    final Color iconColor = filled ? solidIcon : lockedIcon;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: isActive && !isLocked ? 1.1 : 1.0,
        child: Container(
          width: LessonPathway.circleDiameter,
          height: LessonPathway.circleDiameter,
          decoration: BoxDecoration(
            color: buttonColor,
            shape: BoxShape.circle,
            border: isActive && !isLocked
                ? Border.all(
                    color: isDark ? Colors.black : Colors.white, width: 3)
                : null,
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// Custom painter to draw the connecting bezier curve through node centers.
class PathConnectingPainter extends CustomPainter {
  final int nodeCount;
  final Color color;

  PathConnectingPainter({
    required this.nodeCount,
    this.color = const Color(0xFF616161),
  });

  double _nodeX(int index, double width) {
    return width / 2 +
        LessonPathway.alignmentFraction(index) * width / 2;
  }

  double _nodeY(int index) {
    return LessonPathway.topPadding +
        index * LessonPathway.itemHeight +
        LessonPathway.circleCenterOffset;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (nodeCount <= 1 || size.width <= 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();
    path.moveTo(_nodeX(0, size.width), _nodeY(0));

    for (int i = 1; i < nodeCount; i++) {
      final currentX = _nodeX(i - 1, size.width);
      final nextX = _nodeX(i, size.width);
      final nextY = _nodeY(i);
      final controlY = (_nodeY(i - 1) + nextY) / 2;
      path.cubicTo(currentX, controlY, nextX, controlY, nextX, nextY);
    }

    // Draws a dashed line effect over the path
    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const double dashWidth = 8.0;
    const double dashSpace = 6.0;

    final Path dashedPath = Path();
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant PathConnectingPainter oldDelegate) =>
      oldDelegate.nodeCount != nodeCount || oldDelegate.color != color;
}
