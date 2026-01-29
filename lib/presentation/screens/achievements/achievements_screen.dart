import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/achievement.dart';
import '../../providers/achievement_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/achievement/achievement_card.dart';
import 'achievement_unlock_presentation.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementState = ref.watch(achievementProvider);

    // Show fancy unlock presentation for newly unlocked achievements
    ref.listen<AchievementState>(achievementProvider, (previous, next) {
      if (next.newlyUnlocked.isNotEmpty) {
        for (final achievement in next.newlyUnlocked) {
          final achievementWithStatus = AchievementWithStatus(
            achievement: achievement,
            userAchievement: null,
          );
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  AchievementUnlockPresentation(
                achievement: achievementWithStatus,
                onDismiss: () {
                  ref.read(achievementProvider.notifier).clearNewlyUnlocked();
                },
              ),
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 300),
              opaque: false,
              barrierDismissible: false,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        }
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Шагнал'),
        centerTitle: true,
      ),
      body: achievementState.isLoading
          ? const LoadingWidget(message: 'Шагналууд ачааллаж байна...')
          : achievementState.failure != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(achievementState.failure!.message),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Refresh achievements
                        },
                        child: const Text('Дахин оролдох'),
                      ),
                    ],
                  ),
                )
              : achievementState.achievements.isEmpty
                  ? const Center(
                      child: Text('Шагнал байхгүй байна'),
                    )
                  : _buildAchievementsGrid(context, achievementState),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context, AchievementState state) {
    final total = state.achievements.length;
    final unlocked = state.unlockedAchievements.length;
    final progress = total > 0 ? unlocked / total : 0.0;

    // Group achievements by type
    final achievementsByType = <String, List<AchievementWithStatus>>{};
    for (final achievement in state.achievements) {
      final type = achievement.achievement.type;
      achievementsByType.putIfAbsent(type, () => []).add(achievement);
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Stats header - Duolingo style
          _buildStatsHeader(context, unlocked, total, progress),

          const SizedBox(height: 8),

          // Achievement categories
          ...achievementsByType.entries.map((entry) {
            return _buildCategorySection(context, entry.key, entry.value);
          }),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatsHeader(
      BuildContext context, int unlocked, int total, double progress) {
    // Redesigned header: circular progress + basic stats
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Circular progress indicator with centered percentage
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.gold.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Дууссан',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Stats summary
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Амжилт',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text('${unlocked} шагнал авсан', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text('Нийт: $total', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.emoji_events_outlined),
                        label: const Text('Шагнал үзэх'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Тусламж'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String type,
    List<AchievementWithStatus> achievements,
  ) {
    final categoryInfo = _getCategoryInfo(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: categoryInfo.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  categoryInfo.icon,
                  color: categoryInfo.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryInfo.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${achievements.where((a) => a.isUnlocked).length}/${achievements.length} авсан',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Grid of achievements - Duolingo style blocks
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              return _AchievementGridTile(
                achievement: achievements[index],
                categoryColor: categoryInfo.color,
                onTap: () => _showAchievementDetail(context, achievements[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  _CategoryInfo _getCategoryInfo(String type) {
    switch (type) {
      case 'streak':
        return _CategoryInfo(
          title: 'Streak шагнал',
          icon: Icons.local_fire_department,
          color: Colors.orange,
        );
      case 'lessons':
        return _CategoryInfo(
          title: 'Хичээлийн шагнал',
          icon: Icons.school,
          color: AppColors.primary,
        );
      case 'xp':
        return _CategoryInfo(
          title: 'XP шагнал',
          icon: Icons.star,
          color: Colors.amber,
        );
      case 'perfect':
        return _CategoryInfo(
          title: 'Төгс гүйцэтгэл',
          icon: Icons.workspace_premium,
          color: Colors.purple,
        );
      case 'social':
        return _CategoryInfo(
          title: 'Нийгмийн шагнал',
          icon: Icons.people,
          color: Colors.blue,
        );
      case 'time':
        return _CategoryInfo(
          title: 'Цаг хугацааны шагнал',
          icon: Icons.access_time,
          color: Colors.teal,
        );
      default:
        return _CategoryInfo(
          title: 'Бусад шагнал',
          icon: Icons.emoji_events,
          color: AppColors.gold,
        );
    }
  }

  void _showAchievementDetail(
      BuildContext context, AchievementWithStatus achievement) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: AchievementCard(achievement: achievement),
          ),
        ),
      ),
    );
  }
}

class _CategoryInfo {
  final String title;
  final IconData icon;
  final Color color;

  _CategoryInfo({
    required this.title,
    required this.icon,
    required this.color,
  });
}

/// Duolingo-style achievement grid tile
class _AchievementGridTile extends StatelessWidget {
  final AchievementWithStatus achievement;
  final Color categoryColor;
  final VoidCallback onTap;

  const _AchievementGridTile({
    required this.achievement,
    required this.categoryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: isUnlocked ? 6 : 0,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              AchievementBadge(achievement: achievement, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      achievement.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      achievement.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (isUnlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.check, size: 14, color: AppColors.gold),
                                SizedBox(width: 6),
                                Text('Авсан', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 14, color: Colors.grey),
                                SizedBox(width: 6),
                                Text('Түгжигдсэн', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
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
