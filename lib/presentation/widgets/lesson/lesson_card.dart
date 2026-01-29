import 'package:flutter/material.dart';
import '../../../data/models/lesson.dart';
import '../common/progress_bar.dart';

class LessonCard extends StatelessWidget {
  final LessonModel lesson;
  final double progress;
  final bool isLocked;
  final VoidCallback? onTap;

  const LessonCard({
    super.key,
    required this.lesson,
    this.progress = 0,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isLocked ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildIcon(context),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lesson.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lesson.description ?? '',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isLocked)
                      const Icon(Icons.lock, color: Colors.grey)
                    else if (progress >= 1.0)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: Colors.green.shade700,
                          size: 20,
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
                if (progress > 0 && progress < 1.0) ...[
                  const SizedBox(height: 12),
                  ProgressBar(
                    progress: progress,
                    height: 6,
                    showPercentage: true,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getTypeColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getTypeIcon(),
        color: _getTypeColor(),
        size: 24,
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (lesson.type) {
      case 'alphabet':
        return Icons.abc;
      case 'vocabulary':
        return Icons.book;
      case 'grammar':
        return Icons.rule;
      case 'reading':
        return Icons.menu_book;
      case 'listening':
        return Icons.headphones;
      case 'speaking':
        return Icons.mic;
      case 'writing':
        return Icons.edit;
      case 'culture':
        return Icons.temple_buddhist;
      default:
        return Icons.school;
    }
  }

  Color _getTypeColor() {
    switch (lesson.type) {
      case 'alphabet':
        return Colors.purple;
      case 'vocabulary':
        return Colors.blue;
      case 'grammar':
        return Colors.orange;
      case 'reading':
        return Colors.teal;
      case 'listening':
        return Colors.indigo;
      case 'speaking':
        return Colors.pink;
      case 'writing':
        return Colors.brown;
      case 'culture':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }
}

class LessonListItem extends StatelessWidget {
  final LessonModel lesson;
  final int index;
  final double progress;
  final bool isLocked;
  final bool isActive;
  final VoidCallback? onTap;

  const LessonListItem({
    super.key,
    required this.lesson,
    required this.index,
    this.progress = 0,
    this.isLocked = false,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: isLocked ? null : onTap,
      leading: _buildLeading(context),
      title: Text(
        lesson.title,
        style: TextStyle(
          color: isLocked 
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) 
              : null,
        ),
      ),
      subtitle: lesson.description != null
          ? Text(
              lesson.description!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isLocked 
                    ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5) 
                    : null,
              ),
            )
          : null,
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildLeading(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor;
    Widget child;

    if (progress >= 1.0) {
      backgroundColor = Colors.green.shade100;
      foregroundColor = Colors.green.shade700;
      child = const Icon(Icons.check, size: 20);
    } else if (isActive) {
      backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      foregroundColor = Theme.of(context).colorScheme.onPrimaryContainer;
      child = Text(
        '${index + 1}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      );
    } else if (isLocked) {
      backgroundColor = Colors.grey.shade200;
      foregroundColor = Colors.grey;
      child = const Icon(Icons.lock, size: 20);
    } else {
      backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
      foregroundColor = Theme.of(context).colorScheme.onSurfaceVariant;
      child = Text(
        '${index + 1}',
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: foregroundColor,
        ),
      );
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (isLocked) return null;
    if (progress >= 1.0) return null;
    if (progress > 0) {
      // Lightweight static progress indicator: text percentage to avoid continuous animations
      return SizedBox(
        width: 48,
        child: Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    return Icon(
      Icons.chevron_right,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
