import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user.dart';
import '../../../data/models/achievement.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../providers/follow_provider.dart';
import '../../providers/repository_providers.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/common/common.dart';
import '../../widgets/common/expandable_text.dart';
import '../../widgets/achievement/achievement.dart';
import '../../router.dart';
import '../achievements/other_user_achievements_screen.dart';

/// User profile screen
/// Handles both own profile and viewing other users' profiles
class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isOwnProfile = true;
  String? _targetUserId;
  final Map<String, Color> _dominantColorCache = {};
  final Map<String, String> _dominantUrlCache = {};
  Color? _dominantColor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _determineProfileType();
    });
  }

  void _determineProfileType() {
    final authState = ref.read(authProvider);
    _targetUserId = widget.userId;
    _isOwnProfile =
        widget.userId == null || widget.userId == authState.user?.id;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Determine if viewing own profile or another user's profile
    if (_isOwnProfile) {
      return _buildOwnProfile();
    } else {
      return _buildOtherUserProfile();
    }
  }

  /// Build own profile screen with full access
  Widget _buildOwnProfile() {
    final authState = ref.watch(authProvider);
    final progressState = ref.watch(progressProvider);
    final achievementState = ref.watch(achievementProvider);
    final followState = ref.watch(followProvider);

    final user = authState.user;
    final totalXp = progressState.totalXp;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: LoadingWidget(message: 'Ачааллаж байна...'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Миний профайл'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.editProfile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            ref.read(authProvider.notifier).refreshUser();
            await ref
                .read(followProvider.notifier)
                .loadFollowData(user.id, silent: true);
          } catch (e) {
            // Silently handle errors during refresh
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 24),
              _buildOwnStatsRow(totalXp, followState),
              const SizedBox(height: 24),
              _buildAchievementsSection(achievementState),
              const SizedBox(height: 24),
              _buildActivitySection(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build other user's profile screen with follow/unfollow options
  Widget _buildOtherUserProfile() {
    final otherUserAsync = ref.watch(otherUserProfileProvider(_targetUserId!));

    return otherUserAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Профайл'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Профайл'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_off_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Хэрэглэгч олдсонгүй',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Энэ хэрэглэгч устсан эсвэл профайлаа нууцалсан байна',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Буцах'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.invalidate(otherUserProfileProvider(_targetUserId!));
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Дахин оролдох'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Хэрэглэгч олдсонгүй'),
            ),
          );
        }

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(user.displayName),
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Removed three-dot menu when viewing other users
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              try {
                // Refresh user profile
                ref.invalidate(otherUserProfileProvider(_targetUserId!));
                ref.invalidate(userFollowStatusProvider(_targetUserId!));

                // Refresh follow data from server
                final currentUser = ref.read(currentUserProvider);
                if (currentUser != null) {
                  await ref
                      .read(followRepositoryProvider)
                      .getFollowers(currentUser.id);
                  await ref
                      .read(followRepositoryProvider)
                      .getFollowing(currentUser.id);
                }
              } catch (e) {
                // Silently handle errors during refresh
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 16),
                  // Achievements section (moved up to fill gap)
                  _buildAchievementsSectionForOtherUser(user),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    // Ensure we have a dominant color for this user's avatar
    _ensureDominantColorForUser(user);
    final theme = Theme.of(context);
    final base = _dominantColor ?? theme.colorScheme.primary;
    final bool isOther = !_isOwnProfile;

    return Container(
      width: isOther ? double.infinity : null,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            base.withOpacity(0.95),
            base.withOpacity(0.45),
            theme.scaffoldBackgroundColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: isOther
            ? const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              )
            : BorderRadius.circular(12),
      ),
      padding: isOther
          ? EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + kToolbarHeight + 16,
              16,
              16,
            )
          : const EdgeInsets.all(16),
      child: Column(
        children: [
          if (isOther) ...[
            // Match HomeScreen profile card for other users
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
                      // Show bio when viewing other users (expandable)
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
                      const SizedBox(height: 8),
                      // Mutual follow indicator moved into the header for other users
                      Builder(builder: (context) {
                        final followStatus = ref.watch(userFollowStatusProvider(user.id));
                        return followStatus.when(
                          data: (s) {
                            if (s.isFollowedBy) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Таныг дагадаг',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Icon-only follow button for other users (uses local isFollowing for instant update)
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Builder(builder: (context) {
                    final followState = ref.watch(followProvider);
                    final isProcessing = followState.isProcessing;
                    final locallyFollowing = ref.watch(isFollowingProvider(user.id));

                    return IconButton(
                      onPressed: isProcessing
                          ? null
                          : () async {
                              final success = await ref.read(followProvider.notifier).toggleFollow(user.id);
                              if (success) ref.invalidate(userFollowStatusProvider(user.id));
                            },
                      icon: isProcessing
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(locallyFollowing ? Icons.person_remove : Icons.person_add),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats: XP / Streak / Followers / Following (followers/following
            // derive from remote status but reflect local follow state instantly)
            Builder(builder: (context) {
              final status = ref.watch(userFollowStatusProvider(user.id));
              final locallyFollowing = ref.watch(isFollowingProvider(user.id));

              return status.when(
                data: (s) {
                  final baselineFollowers = s.followersCount;
                  final baselineFollowing = s.followingCount;
                  final originallyFollowing = s.isFollowing;

                  int displayedFollowers = baselineFollowers;
                  if (locallyFollowing && !originallyFollowing) displayedFollowers += 1;
                  if (!locallyFollowing && originallyFollowing) displayedFollowers -= 1;

                  int displayedFollowing = baselineFollowing;
                  // For following count we don't infer change from local state (it's the target user's following count)

                      return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(context, '${user.totalXp}', 'XP'),
                      _buildStat(context, '${user.streak}', 'Streak'),
                      GestureDetector(
                        onTap: () => _showFollowersDialogForUser(user.id),
                        child: _buildStat(context, '$displayedFollowers', 'Дагагч'),
                      ),
                      GestureDetector(
                        onTap: () => _showFollowingDialogForUser(user.id),
                        child: _buildStat(context, '$displayedFollowing', 'Дагадаг'),
                      ),
                    ],
                  );
                },
                loading: () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(context, '${user.totalXp}', 'XP'),
                    _buildStat(context, '${user.streak}', 'Streak'),
                    GestureDetector(onTap: () => _showFollowersDialogForUser(user.id), child: _buildStat(context, '...', 'Дагагч')),
                    GestureDetector(onTap: () => _showFollowingDialogForUser(user.id), child: _buildStat(context, '...', 'Дагадаг')),
                  ],
                ),
                error: (_, __) => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStat(context, '${user.totalXp}', 'XP'),
                    _buildStat(context, '${user.streak}', 'Streak'),
                    GestureDetector(onTap: () => _showFollowersDialogForUser(user.id), child: _buildStat(context, '${user.followerCount}', 'Дагагч')),
                    GestureDetector(onTap: () => _showFollowingDialogForUser(user.id), child: _buildStat(context, '${user.followingCount}', 'Дагадаг')),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            LevelProgress(currentXp: user.totalXp % 1000, xpForNextLevel: 1000, level: user.level),
          ] else ...[
            // Own profile layout (keeps existing behaviour)
            // Avatar with edit button for own profile
            Stack(
              children: [
                AppAvatar(
                  imageUrl: user.avatarUrl,
                  name: user.displayName,
                  size: 100,
                ),
                if (_isOwnProfile)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRouter.editProfile),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              user.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),

            // Username
            if (user.username != null && user.username!.isNotEmpty)
              Text(
                '@${user.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            const SizedBox(height: 8),

            // Bio
            if (user.bio != null && user.bio!.isNotEmpty)
              Text(
                user.bio!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),

            // Level badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    'Түвшин ${user.level}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // When viewing other users, show stats row and level progress inline
            if (!_isOwnProfile) ...[
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
              LevelProgress(currentXp: user.totalXp % 1000, xpForNextLevel: 1000, level: user.level),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _ensureDominantColorForUser(UserModel user) async {
    final key = user.id.isNotEmpty ? user.id : user.displayName;
    final imageUrl = user.avatarUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;

    // If we've cached a color for this user and the avatar URL hasn't changed,
    // re-use the cached color. Otherwise continue to regenerate.
    if (_dominantColorCache.containsKey(key) && _dominantUrlCache[key] == imageUrl) {
      if (_dominantColor != _dominantColorCache[key]) {
        setState(() {
          _dominantColor = _dominantColorCache[key];
        });
      }
      return;
    }

    try {
      final provider = CachedNetworkImageProvider(imageUrl);
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 8,
      );

      final color = palette.dominantColor?.color ?? palette.vibrantColor?.color;
      if (color != null) {
        _dominantColorCache[key] = color;
        _dominantUrlCache[key] = imageUrl;
        if (mounted) {
          setState(() => _dominantColor = color);
        }
      }
    } catch (_) {
      // ignore errors; keep default theme colors
    }
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

  Widget _buildOwnStatsRow(int totalXp, FollowState followState) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // XP stat
          Expanded(
            child: _CompactStat(
              value: '$totalXp',
              label: 'XP',
              icon: Icons.bolt_rounded,
              iconColor: Colors.amber,
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor.withOpacity(0.2),
          ),
          // Followers stat
          Expanded(
            child: GestureDetector(
              onTap: () => _showFollowersDialog(),
              child: _CompactStat(
                value: '${followState.followers.length}',
                label: 'Дагагч',
                icon: Icons.people_rounded,
                iconColor: Colors.blue,
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 40,
            color: theme.dividerColor.withOpacity(0.2),
          ),
          // Following stat
          Expanded(
            child: GestureDetector(
              onTap: () => _showFollowingDialog(),
              child: _CompactStat(
                value: '${followState.following.length}',
                label: 'Дагаж буй',
                icon: Icons.person_add_rounded,
                iconColor: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildAchievementsSection(AchievementState achievementState) {
    final unlockedAchievements = achievementState.achievements
        .where((AchievementWithStatus a) => a.isUnlocked)
        .take(6)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Амжилтууд',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.achievements),
                child: const Text('Бүгдийг харах'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (unlockedAchievements.isEmpty)
            const Center(
              child: Text(
                'Одоогоор амжилт байхгүй',
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: unlockedAchievements.map((achievement) {
                return AchievementBadge(
                  achievement: achievement,
                  size: 50,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSectionForOtherUser(UserModel user) {
    // Fetch achievements for the viewed user and show unlocked ones
    final repo = ref.read(achievementRepositoryProvider);
    return AppCard(
      child: FutureBuilder(
        future: repo.getAchievementsWithStatus(user.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final achievements = snap.data?.achievements ?? [];
          final unlocked = achievements.where((a) => a.isUnlocked).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Амжилтууд',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (achievements.isEmpty)
                const Center(
                  child: Text(
                    'Одоогоор амжилт байхгүй',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: unlocked.take(6).map((achievement) {
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                                  child: SingleChildScrollView(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: AchievementCard(achievement: achievement),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: AchievementBadge(
                            achievement: achievement,
                            size: 64,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    if (unlocked.length > 6)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => OtherUserAchievementsScreen(userId: user.id),
                            ));
                          },
                          child: const Text('Бүгдийг харах'),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivitySection() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сүүлийн үйл ажиллагаа',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          // Activity list placeholder
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.school),
                ),
                title: const Text('Хичээл дууссан'),
                subtitle: const Text('Үндсэн үгс - 1-р хичээл'),
                trailing: Text(
                  '${index + 1} цагийн өмнө',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showFollowersDialog() {
    final followState = ref.read(followProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дагагчид'),
        content: SizedBox(
          width: double.maxFinite,
          child: followState.followers.isEmpty
              ? const Center(child: Text('Дагагч байхгүй'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: followState.followers.length,
                  itemBuilder: (context, index) {
                    final follower = followState.followers[index];
                    return ListTile(
                      leading: AppAvatar(
                        imageUrl: follower.avatarUrl,
                        name: follower.displayName,
                        size: 40,
                      ),
                      title: Text(follower.displayName),
                      subtitle: follower.username != null &&
                              follower.username!.isNotEmpty
                          ? Text('@${follower.username}')
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRouter.profile,
                          arguments: follower.id,
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Хаах'),
          ),
        ],
      ),
    );
  }

  void _showFollowingDialog() {
    final followState = ref.read(followProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дагаж буй'),
        content: SizedBox(
          width: double.maxFinite,
          child: followState.following.isEmpty
              ? const Center(child: Text('Дагаж буй хэрэглэгч байхгүй'))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: followState.following.length,
                  itemBuilder: (context, index) {
                    final following = followState.following[index];
                    return ListTile(
                      leading: AppAvatar(
                        imageUrl: following.avatarUrl,
                        name: following.displayName,
                        size: 40,
                      ),
                      title: Text(following.displayName),
                      subtitle: following.username != null &&
                              following.username!.isNotEmpty
                          ? Text('@${following.username}')
                          : null,
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove),
                        onPressed: () {
                          ref
                              .read(followProvider.notifier)
                              .toggleFollow(following.id);
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(
                          context,
                          AppRouter.profile,
                          arguments: following.id,
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Хаах'),
          ),
        ],
      ),
    );
  }

  /// Show followers for an arbitrary user id (used when viewing other profiles)
  void _showFollowersDialogForUser(String userId) {
    final repo = ref.read(followRepositoryProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дагагчид'),
        content: SizedBox(
          width: double.maxFinite,
          // Load followers asynchronously inside the dialog so it appears instantly
          child: FutureBuilder(
            future: repo.getFollowers(userId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return const Center(child: Text('Ачааллахад алдаа гарлаа'));
              }
              final result = snap.data;
              final followers = result?.followers ?? [];
              if (followers.isEmpty) return const Center(child: Text('Дагагч байхгүй'));

              return ListView.builder(
                shrinkWrap: true,
                itemCount: followers.length,
                itemBuilder: (context, index) {
                  final follower = followers[index];
                  return ListTile(
                    leading: AppAvatar(
                      imageUrl: follower.avatarUrl,
                      name: follower.displayName,
                      size: 40,
                    ),
                    title: Text(follower.displayName),
                    subtitle: follower.username != null && follower.username!.isNotEmpty
                        ? Text('@${follower.username}')
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRouter.profile,
                        arguments: follower.id,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Хаах'),
          ),
        ],
      ),
    );
  }

  /// Show following list for an arbitrary user id
  void _showFollowingDialogForUser(String userId) {
    final repo = ref.read(followRepositoryProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Дагаж буй'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder(
            future: repo.getFollowing(userId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snap.hasError) {
                return const Center(child: Text('Ачааллахад алдаа гарлаа'));
              }
              final result = snap.data;
              final following = result?.following ?? [];
              if (following.isEmpty) return const Center(child: Text('Дагаж буй хэрэглэгч байхгүй'));

              return ListView.builder(
                shrinkWrap: true,
                itemCount: following.length,
                itemBuilder: (context, index) {
                  final f = following[index];
                  return ListTile(
                    leading: AppAvatar(
                      imageUrl: f.avatarUrl,
                      name: f.displayName,
                      size: 40,
                    ),
                    title: Text(f.displayName),
                    subtitle: f.username != null && f.username!.isNotEmpty
                        ? Text('@${f.username}')
                        : null,
                    trailing: null,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AppRouter.profile,
                        arguments: f.id,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Хаах'),
          ),
        ],
      ),
    );
  }

  
}

// =============================================================================
// COMPACT STAT WIDGET - For profile stats row
// =============================================================================

class _CompactStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _CompactStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
