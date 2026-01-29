import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';
import '../../../core/constants/colors.dart';

/// Duolingo-style roadmap node widget
/// Displays a single lesson node in the roadmap
///
/// Performance: Uses RepaintBoundary to isolate repaints
class RoadmapNode extends StatefulWidget {
  final LessonModel lesson;
  final double progress;
  final bool isLocked;
  final bool isActive;
  final int index;
  final bool enableOffset;
  final double sizeFactor;
  final VoidCallback? onTap;

  const RoadmapNode({
    super.key,
    required this.lesson,
    required this.index,
    this.enableOffset = true,
    this.sizeFactor = 1.0,
    this.progress = 0,
    this.isLocked = false,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<RoadmapNode> createState() => _RoadmapNodeState();
}

class _RoadmapNodeState extends State<RoadmapNode>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.progress >= 1.0;
    final nodeSize = (widget.isActive ? 76.0 : 62.0) * widget.sizeFactor;
    final tileSize = nodeSize - 8;
    final radius = (widget.isActive ? 22.0 : 20.0) * widget.sizeFactor;

    // Calculate horizontal offset for zigzag pattern
    final offsetX = widget.enableOffset ? _calculateOffset(widget.index) : 0.0;

    return RepaintBoundary(
      child: Transform.translate(
        offset: Offset(offsetX, 0),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          scale: widget.isActive && !widget.isLocked ? 1.02 : 1.0,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(radius),
            child: InkWell(
              onTap: widget.isLocked ? null : widget.onTap,
              borderRadius: BorderRadius.circular(radius),
              child: SizedBox(
                width: nodeSize,
                height: nodeSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!widget.isLocked && widget.progress > 0 && !isCompleted)
                      SizedBox(
                        width: nodeSize,
                        height: nodeSize,
                        child: CircularProgressIndicator(
                          value: widget.progress.clamp(0.0, 1.0),
                          strokeWidth: (4 * widget.sizeFactor).clamp(2.0, 4.0),
                          backgroundColor: AppColors.divider.withOpacity(0.7),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getNodeColor(
                                isCompleted, widget.isLocked, widget.isActive),
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    if (isCompleted)
                      SizedBox(
                        width: nodeSize,
                        height: nodeSize,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius + 2),
                            border: Border.all(
                              color: AppColors.progressComplete,
                              width: (4 * widget.sizeFactor).clamp(2.0, 4.0),
                            ),
                          ),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      width: tileSize,
                      height: tileSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(radius),
                        color: widget.isLocked
                            ? AppColors.progressLocked
                            : _getTileFill(isCompleted, widget.isActive),
                        border: Border.all(
                          color: widget.isLocked
                              ? Colors.transparent
                              : _getTileBorder(isCompleted, widget.isActive),
                          width: widget.isActive && !widget.isLocked ? 2.5 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _buildNodeContent(
                            isCompleted, widget.isLocked, context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodeContent(
      bool isCompleted, bool isLocked, BuildContext context) {
    final scale = widget.sizeFactor;
    if (isLocked) {
      return Icon(
        Icons.lock_rounded,
        color: Colors.white,
        size: 24 * scale,
      );
    }

    if (isCompleted) {
      return Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 28 * scale,
      );
    }

    if (widget.isActive) {
      return Icon(
        Icons.play_arrow_rounded,
        color: Colors.white,
        size: 30 * scale,
      );
    }

    return Icon(_getTypeIcon(), color: Colors.white, size: 24 * scale);
  }

  double _calculateOffset(int index) {
    // Zigzag pattern: alternate between left and right
    // Creates a winding path effect
    const amplitude = 60.0;
    const cycle = 4; // Every 4 nodes complete a cycle
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

  Color _getNodeColor(bool isCompleted, bool isLocked, bool isActive) {
    if (isLocked) {
      return AppColors.progressLocked;
    }
    if (isCompleted) {
      return AppColors.progressComplete;
    }
    if (isActive) {
      return AppColors.primary;
    }
    return AppColors.primary.withOpacity(0.75);
  }

  Color _getTileFill(bool isCompleted, bool isActive) {
    if (isCompleted) return AppColors.primary;
    if (isActive) return AppColors.primary;
    return AppColors.primary.withOpacity(0.78);
  }

  Color _getTileBorder(bool isCompleted, bool isActive) {
    if (isActive) return Colors.white.withOpacity(0.95);
    if (isCompleted) return Colors.white.withOpacity(0.85);
    return Colors.white.withOpacity(0.65);
  }

  IconData _getTypeIcon() {
    switch (widget.lesson.type) {
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
}
