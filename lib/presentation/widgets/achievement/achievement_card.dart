import 'package:flutter/material.dart';
import '../../../data/models/achievement.dart';
import '../../../core/constants/app_colors.dart';

class AchievementCard extends StatelessWidget {
  final AchievementWithStatus achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: isUnlocked ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIcon(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (isUnlocked && achievement.unlockedAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Авсан: ${_formatDate(achievement.unlockedAt!)}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isUnlocked)
                  const Icon(Icons.lock, color: Colors.grey)
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? AppColors.gold.withOpacity(0.2)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: achievement.iconUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImageWidget(achievement.iconUrl!, 56, achievement.isUnlocked),
            )
          : Icon(
              _getTypeIcon(achievement.type),
              color: achievement.isUnlocked ? AppColors.gold : Colors.grey,
              size: 28,
            ),
    );
  }

  Widget _buildImageWidget(String path, double size, bool isUnlocked) {
    // Only honor remote URLs for custom icons; ignore local asset PNGs and fall
    // back to the type-based built-in icon. This prevents relying on bundled
    // PNGs and ensures a consistent vector icon look.
    if (!path.startsWith('http')) {
      return Icon(_getTypeIcon(achievement.type), color: isUnlocked ? AppColors.gold : Colors.grey, size: size * 0.5);
    }

    final widget = Image.network(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Icon(
        _getTypeIcon(achievement.type),
        color: isUnlocked ? AppColors.gold : Colors.grey,
        size: size * 0.5,
      ),
    );

    if (isUnlocked) return widget;

    // For locked remote images, render desaturated version
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: Opacity(opacity: 0.7, child: widget),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'streak':
        return Icons.local_fire_department;
      case 'lessons':
        return Icons.school;
      case 'xp':
        return Icons.star;
      case 'perfect':
        return Icons.workspace_premium;
      case 'social':
        return Icons.people;
      case 'time':
        return Icons.access_time;
      default:
        return Icons.emoji_events;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

// Helper for badge images (used inside AchievementBadge)
Widget _buildBadgeImage(String path, double size, bool isUnlocked) {
  // Only use remote images for icons; prefer the built-in type icon otherwise.
  if (!path.startsWith('http')) {
    return Icon(
      _getTypeIconStatic(path) ?? Icons.emoji_events,
      color: isUnlocked ? Colors.white : Colors.grey,
      size: size * 0.5,
    );
  }

  final widget = Image.network(
    path,
    fit: BoxFit.contain,
    errorBuilder: (context, error, stackTrace) => Icon(
      Icons.emoji_events,
      color: isUnlocked ? Colors.white : Colors.grey,
      size: size * 0.5,
    ),
    loadingBuilder: (context, child, loadingProgress) {
      if (loadingProgress == null) return child;
      return Center(
        child: SizedBox(
          width: size * 0.4,
          height: size * 0.4,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isUnlocked ? Colors.white : Colors.grey,
            ),
          ),
        ),
      );
    },
  );

  if (isUnlocked) return widget;

  return ColorFiltered(
    colorFilter: const ColorFilter.matrix(<double>[
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0.2126, 0.7152, 0.0722, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    child: Opacity(opacity: 0.8, child: widget),
  );
}

// Helper mapping when an asset path was provided; try to infer an icon by type
IconData? _getTypeIconStatic(String pathOrType) {
  // The `pathOrType` may be an asset path or a type string; check keywords.
  final p = pathOrType.toLowerCase();
  if (p.contains('streak') || p.contains('fire')) return Icons.local_fire_department;
  if (p.contains('lesson') || p.contains('school')) return Icons.school;
  if (p.contains('xp') || p.contains('star')) return Icons.star;
  if (p.contains('perfect') || p.contains('premium')) return Icons.workspace_premium;
  if (p.contains('social') || p.contains('people')) return Icons.people;
  if (p.contains('time') || p.contains('clock')) return Icons.access_time;
  return null;
}

class AchievementBadge extends StatelessWidget {
  final AchievementWithStatus achievement;
  final double size;
  final VoidCallback? onTap;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.size = 64,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: achievement.isUnlocked
                  ? const LinearGradient(
                      colors: [AppColors.gold, Color(0xFFFFD54F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: achievement.isUnlocked ? null : Colors.grey.shade300,
              shape: BoxShape.circle,
              boxShadow: achievement.isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: achievement.iconUrl != null
                      ? _buildBadgeImage(achievement.iconUrl!, size, achievement.isUnlocked)
                      : Icon(
                          Icons.emoji_events,
                          color: achievement.isUnlocked ? Colors.white : Colors.grey,
                          size: size * 0.5,
                        ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size * 1.5,
            child: Text(
              achievement.title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: achievement.isUnlocked
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class AchievementUnlockDialog extends StatelessWidget {
  final AchievementWithStatus achievement;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gold, Color(0xFFFFD54F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Шагнал авлаа!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Гайхалтай!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
