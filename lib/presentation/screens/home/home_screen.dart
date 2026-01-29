import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/leaderboard_provider.dart';
import '../../widgets/common/progress_bar.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/expandable_text.dart';
import '../../widgets/leaderboard/leaderboard_item.dart';
import '../tarni/tarni_screen.dart';
import 'lessons_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0; // navigation selection
  int _displayedIndex = 0; // which child is currently shown
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
    _displayedIndex = widget.initialTab;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..value = 1.0;
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(
          4,
          (i) {
            final child = [
              const LessonsTab(),
              const TarniScreen(),
              const _LeaderboardTab(),
              const _ProfileTab(),
            ][i];

            return Offstage(
              offstage: i != _displayedIndex,
              child: TickerMode(
                enabled: i == _displayedIndex,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) async {
          if (index == _selectedIndex) return;

          // Update selected state for the bar first so UI reflects choice
          setState(() => _selectedIndex = index);

          // Fade out current screen
          await _fadeController.animateTo(0.0);

          // Swap displayed child
          if (!mounted) return;
          setState(() => _displayedIndex = index);

          // Fade in new screen
          await _fadeController.animateTo(1.0);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Сурах',
          ),
            NavigationDestination(
              icon: _selectedIndex == 1 ? const Icon(Icons.volunteer_activism) : const Icon(Icons.volunteer_activism_outlined),
              selectedIcon: const Icon(Icons.volunteer_activism),
              label: 'Тоолол',
            ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Тэргүүлэгчид',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профайл',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// OLD _LearnTab REMOVED - Now using LessonsTab from lessons_tab.dart
// UI-ONLY: The new continuous vertical layout preserves all logic and data flow
// =============================================================================

// =============================================================================
// LEADERBOARD TAB - Weekly rankings with current user position
// NO TIERS/LEAGUES - Simple weekly XP leaderboard
// =============================================================================

class _LeaderboardTab extends ConsumerWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final leaderboardState = ref.watch(leaderboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Долоо хоногийн тэргүүлэгчид'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(context, ref, leaderboardState, user, theme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    LeaderboardState state,
    user,
    ThemeData theme,
  ) {
    // Loading state
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (state.failure != null && state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Өгөгдөл ачаалахад алдаа гарлаа',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.failure!.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (user != null) {
                  ref.read(leaderboardProvider.notifier).refresh(user.id);
                }
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Дахин оролдох'),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.leaderboard_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Энэ долоо хоногт тоглогчид алга байна',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'XP цуглуулж эхний байранд орооройё!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Get top 3 entries for podium
    final top3 = state.entries.take(3).toList();
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    // Remaining entries (after top 3)
    final remainingEntries =
        state.entries.length > 3 ? state.entries.sublist(3) : <dynamic>[];

    // Main leaderboard content
    return RefreshIndicator(
      onRefresh: () async {
        if (user != null) {
          await ref.read(leaderboardProvider.notifier).refresh(user.id);
        }
      },
      child: CustomScrollView(
        slivers: [
          // SafeArea sliver for top padding under transparent AppBar
          SliverToBoxAdapter(
            child: SizedBox(
                height: MediaQuery.of(context).padding.top + kToolbarHeight),
          ),
          // Top 3 Podium Visual
          if (first != null)
            SliverToBoxAdapter(
              child: LeaderboardPodium(
                first: first,
                second: second,
                third: third,
                currentUserId: user?.id,
              ),
            ),
          // User position card (only if not in top 3)
          if (user != null && state.userRank > 3)
            SliverToBoxAdapter(
              child: _UserPositionCard(
                userRank: state.userRank,
                userEntry: state.userEntry,
                theme: theme,
              ),
            ),
          // Remaining leaderboard entries (starting from rank 4) - no top gap
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = remainingEntries[index];
                  final rank = index + 4; // Ranks start from 4
                  final isCurrentUser = user?.id == entry.userId;

                  return LeaderboardItem(
                    entry: entry,
                    rank: rank,
                    isCurrentUser: isCurrentUser,
                    showWeeklyXp: true,
                    onTap: isCurrentUser
                        ? null
                        : () {
                            // Navigate to user profile
                            Navigator.of(context).pushNamed(
                              '/profile',
                              arguments: entry.userId,
                            );
                          },
                  );
                },
                childCount: remainingEntries.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky card showing current user's position in the leaderboard
class _UserPositionCard extends StatelessWidget {
  final int userRank;
  final dynamic userEntry;
  final ThemeData theme;

  const _UserPositionCard({
    required this.userRank,
    required this.userEntry,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.6),
            theme.colorScheme.primaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#$userRank',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Таны байр',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEntry != null
                      ? '${userEntry.weeklyXp} XP энэ долоо хоногт'
                      : 'XP цуглуулж эхлээрэй!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Arrow up indicator
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final Map<String, Color> _dominantCache = {};
  final Map<String, String> _dominantUrlCache = {};
  Color? _dominantColor;

  Future<void> _ensureDominant(String? imageUrl, String key) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    // If cached and avatar URL unchanged, reuse cached color.
    if (_dominantCache.containsKey(key) && _dominantUrlCache[key] == imageUrl) {
      if (_dominantColor != _dominantCache[key]) {
        setState(() => _dominantColor = _dominantCache[key]);
      }
      return;
    }

    try {
      final provider = CachedNetworkImageProvider(imageUrl);
      final palette = await PaletteGenerator.fromImageProvider(provider, maximumColorCount: 8);
      final color = palette.dominantColor?.color ?? palette.vibrantColor?.color;
      if (color != null) {
        _dominantCache[key] = color;
        _dominantUrlCache[key] = imageUrl;
        if (mounted) setState(() => _dominantColor = color);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user != null) _ensureDominant(user.avatarUrl, user.id.isNotEmpty ? user.id : user.displayName);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Профайл'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushNamed('/settings');
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Нэвтэрнэ үү'))
          : SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Revamped profile header with adaptive gradient from avatar
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ( _dominantColor ?? Theme.of(context).colorScheme.primary ).withOpacity(0.95),
                          ( _dominantColor ?? Theme.of(context).colorScheme.primary ).withOpacity(0.45),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                      16,
                      16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: AppAvatar(imageUrl: user.avatarUrl, name: user.displayName, size: 80),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.displayName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  if (user.username != null && user.username!.isNotEmpty)
                                    Text('@${user.username}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  const SizedBox(height: 8),
                                  if (user.bio != null && user.bio!.isNotEmpty) ...[
                                    ExpandableText(
                                      text: user.bio!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                      maxLines: 2,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                                        child: Text('Түвшин ${user.level}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${user.lessonsCompleted} хичээл', style: Theme.of(context).textTheme.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Stats row: XP / Streak / Followers / Following
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStat(context, '${user.totalXp}', 'XP'),
                            _buildStat(context, '${user.streak}', 'Streak'),
                            _buildStat(context, '${user.followerCount}', 'Дагагч'),
                            _buildStat(context, '${user.followingCount}', 'Дагадаг'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Level progress
                        LevelProgress(currentXp: user.totalXp % 1000, xpForNextLevel: 1000, level: user.level),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Menu items
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          context,
                          icon: Icons.emoji_events,
                          title: 'Шагнал',
                          onTap: () {
                            Navigator.of(context).pushNamed('/achievements');
                          },
                        ),
                        _buildMenuItem(
                          context,
                          icon: Icons.people,
                          title: 'Найзууд',
                          onTap: () {
                            Navigator.of(context).pushNamed('/friends');
                          },
                        ),
                        // Support button removed per user request
                        _buildMenuItem(
                          context,
                          icon: Icons.logout,
                          title: 'Гарах',
                          onTap: () {
                            _showLogoutDialog(context, ref);
                          },
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Гарах'),
        content: const Text('Та гарахдаа итгэлтэй байна уу?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Үгүй'),
          ),
          TextButton(
            onPressed: () {
              ref.read(authProvider.notifier).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
            },
            child: const Text(
              'Тийм',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
