import 'package:flutter/material.dart';
import '../../../data/models/leaderboard.dart';
import '../../../core/constants/app_colors.dart';
import '../common/app_avatar.dart';

/// Enhanced leaderboard item with medal styling for top ranks
/// iOS-inspired design with clean visual hierarchy
class LeaderboardItem extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final int rank;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final bool showWeeklyXp;

  const LeaderboardItem({
    super.key,
    required this.entry,
    required this.rank,
    this.isCurrentUser = false,
    this.onTap,
    this.showWeeklyXp = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Only highlight current user with app_colors - no alternating backgrounds
    final backgroundColor = isCurrentUser
        ? AppColors.primary.withOpacity(0.15)
        : Colors.transparent;

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: isCurrentUser
              ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Rank indicator
                  _RankIndicator(rank: rank),
                  const SizedBox(width: 14),
                  // Avatar with level ring
                  _AvatarWithLevel(
                    imageUrl: entry.avatarUrl,
                    name: entry.displayName ?? 'User',
                    level: entry.level,
                    isTopRank: rank <= 3,
                  ),
                  const SizedBox(width: 14),
                  // Name and stats
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                entry.displayName ?? 'Unknown',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: isCurrentUser
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isCurrentUser ? AppColors.primary : null,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Та',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.stars_rounded,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Түвшин ${entry.level}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (entry.streak > 0) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.local_fire_department_rounded,
                                size: 14,
                                color: AppColors.streakOrange,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${entry.streak}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.streakOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // XP display
                  _XpBadge(
                    xp: showWeeklyXp ? entry.weeklyXp : entry.totalXp,
                    isWeekly: showWeeklyXp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rank indicator with medal icons for top 3
class _RankIndicator extends StatelessWidget {
  final int rank;

  const _RankIndicator({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getMedalGradient(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            _getMedalIcon(),
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          '$rank',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }

  List<Color> _getMedalGradient() {
    switch (rank) {
      case 1:
        return [const Color(0xFFFFD700), const Color(0xFFFF8C00)];
      case 2:
        return [const Color(0xFFE8E8E8), const Color(0xFFA0A0A0)];
      case 3:
        return [const Color(0xFFCD7F32), const Color(0xFF8B5A2B)];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  IconData _getMedalIcon() {
    switch (rank) {
      case 1:
        return Icons.emoji_events_rounded;
      case 2:
        return Icons.workspace_premium_rounded;
      case 3:
        return Icons.military_tech_rounded;
      default:
        return Icons.circle;
    }
  }
}

/// Avatar with level indicator ring
class _AvatarWithLevel extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final int level;
  final bool isTopRank;

  const _AvatarWithLevel({
    this.imageUrl,
    required this.name,
    required this.level,
    this.isTopRank = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(
            imageUrl: imageUrl,
            name: name,
            size: 48,
          ),
        ],
      ),
    );
  }
}

/// XP badge with bolt icon
class _XpBadge extends StatelessWidget {
  final int xp;
  final bool isWeekly;

  const _XpBadge({
    required this.xp,
    this.isWeekly = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.bolt_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            _formatXp(xp),
            style: theme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(1)}K';
    }
    return '$xp';
  }
}

class LeaderboardPodium extends StatefulWidget {
  final LeaderboardEntryModel? first;
  final LeaderboardEntryModel? second;
  final LeaderboardEntryModel? third;
  final String? currentUserId;

  const LeaderboardPodium({
    super.key,
    this.first,
    this.second,
    this.third,
    this.currentUserId,
  });

  @override
  State<LeaderboardPodium> createState() => _LeaderboardPodiumState();
}

class _LeaderboardPodiumState extends State<LeaderboardPodium>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pause gradient animation when ticker mode is disabled (e.g., offscreen)
    final enabled = TickerMode.of(context);
    if (enabled) {
      if (!_gradientController.isAnimating) _gradientController.repeat(reverse: true);
    } else {
      if (_gradientController.isAnimating) _gradientController.stop();
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  Duration _getTimeUntilReset() {
    final now = DateTime.now();
    // Calculate days until next Monday
    int daysUntilMonday = (DateTime.monday - now.weekday) % 7;
    if (daysUntilMonday == 0 && now.hour >= 0) {
      daysUntilMonday = 7; // If it's Monday, show time until next Monday
    }
    final nextMonday = DateTime(now.year, now.month, now.day + daysUntilMonday);
    return nextMonday.difference(now);
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, child) {
        // Create a more dynamic gradient animation
        final animValue = _gradientController.value;
        
        final statusBar = MediaQuery.of(context).padding.top;
        // Move the whole gradient container up by the status bar height so
        // the gradient visually fills the area behind the system status bar.
        // We add the same amount to the container's top padding so the
        // visible content doesn't shift downward.
        return Transform.translate(
          offset: Offset(0, -statusBar),
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16 + statusBar, 16, 0),
            decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(
                  const Color(0xFFFFD700),
                  const Color(0xFFFF6B35),
                  animValue,
                )!.withOpacity(0.25),
                Color.lerp(
                  const Color(0xFFFF8C00),
                  const Color(0xFFFFD700),
                  animValue,
                )!.withOpacity(0.18),
                Color.lerp(
                  theme.colorScheme.primaryContainer,
                  const Color(0xFFFFB347),
                  animValue * 0.5,
                )!.withOpacity(0.12),
                theme.colorScheme.surface.withOpacity(0.05),
              ],
              stops: const [0.0, 0.35, 0.7, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              transform: GradientRotation(animValue * 0.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Timer - aligned to right
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(_getTimeUntilReset()),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Podium entries
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Second place
                  if (widget.second != null)
                    Expanded(
                      child: _PodiumEntry(
                        entry: widget.second!,
                        rank: 2,
                        podiumHeight: 72,
                        isCurrentUser: widget.second!.userId == widget.currentUserId,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  const SizedBox(width: 8),
                  // First place
                  if (widget.first != null)
                    Expanded(
                      child: _PodiumEntry(
                        entry: widget.first!,
                        rank: 1,
                        podiumHeight: 96,
                        isCurrentUser: widget.first!.userId == widget.currentUserId,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                  const SizedBox(width: 8),
                  // Third place
                  if (widget.third != null)
                    Expanded(
                      child: _PodiumEntry(
                        entry: widget.third!,
                        rank: 3,
                        podiumHeight: 56,
                        isCurrentUser: widget.third!.userId == widget.currentUserId,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ));
      },
    );
  }
}

class _PodiumEntry extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final int rank;
  final double podiumHeight;
  final bool isCurrentUser;

  const _PodiumEntry({
    required this.entry,
    required this.rank,
    required this.podiumHeight,
    this.isCurrentUser = false,
  });

  Color get _primaryColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return Colors.grey;
    }
  }

  Color get _secondaryColor {
    switch (rank) {
      case 1:
        return const Color(0xFFFF8C00);
      case 2:
        return const Color(0xFF9E9E9E);
      case 3:
        return const Color(0xFF8B5A2B);
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarSize = rank == 1 ? 72.0 : 60.0;

    return GestureDetector(
      onTap: isCurrentUser
          ? null
          : () {
              // Navigate to user profile
              Navigator.of(context).pushNamed(
                '/profile',
                arguments: entry.userId,
              );
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for first place
          if (rank == 1)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor, _secondaryColor],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            )
          else
            const SizedBox(height: 40),
          const SizedBox(height: 8),
          // Avatar with rank border
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _primaryColor,
                width: 3,
              ),
            ),
            child: AppAvatar(
              imageUrl: entry.avatarUrl,
              name: entry.displayName,
              size: avatarSize,
            ),
          ),
        const SizedBox(height: 8),
        // Name
        Container(
          constraints: const BoxConstraints(maxWidth: 100),
          child: Text(
            entry.displayName ?? 'Unknown',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        // XP
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt_rounded,
              size: 14,
              color: Colors.amber.shade600,
            ),
            Text(
              '${entry.weeklyXp}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.amber.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Podium
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    );
  }
}

class LeaderboardTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const LeaderboardTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab(
              context,
              title: 'Бүгд',
              index: 0,
            ),
          ),
          Expanded(
            child: _buildTab(
              context,
              title: 'Дагасан',
              index: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    BuildContext context, {
    required String title,
    required int index,
  }) {
    final isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.surface
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
