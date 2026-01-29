import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/follow_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/common.dart';
import '../../widgets/common/app_button.dart';
import '../../router.dart';

/// Friends screen showing followers and following
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followState = ref.watch(followProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Найзууд'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Дагагч (${followState.followers.length})'),
            Tab(text: 'Дагаж буй (${followState.following.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchTextField(
              controller: _searchController,
              hint: 'Хэрэглэгч хайх...',
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFollowersList(followState),
                _buildFollowingList(followState),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFindFriendsDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Найз нэмэх'),
      ),
    );
  }

  Widget _buildFollowersList(FollowState followState) {
    if (followState.isLoading) {
      return const Center(child: LoadingWidget());
    }

    final filteredFollowers = followState.followers.where((follower) {
      return follower.displayName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredFollowers.isEmpty) {
      return const EmptyWidget(
        icon: Icons.people_outline,
        title: 'Дагагч байхгүй',
        subtitle: 'Танд одоогоор дагагч байхгүй байна',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId != null) {
          await ref.read(followProvider.notifier).loadFollowData(userId);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredFollowers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final follower = filteredFollowers[index];
          return _UserListItem(
            userId: follower.id,
            displayName: follower.displayName,
            avatarUrl: follower.avatarUrl,
            isFollowing: followState.following.any(
              (f) => f.id == follower.id,
            ),
            onFollowTap: () {
              ref.read(followProvider.notifier)
                  .toggleFollow(follower.id);
            },
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.profile,
                arguments: follower.id,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFollowingList(FollowState followState) {
    if (followState.isLoading) {
      return const Center(child: LoadingWidget());
    }

    final filteredFollowing = followState.following.where((following) {
      return following.displayName.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredFollowing.isEmpty) {
      return const EmptyWidget(
        icon: Icons.person_add_alt_1,
        title: 'Дагаж буй хэрэглэгч байхгүй',
        subtitle: 'Найзуудаа хайж олоод дагаарай',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = ref.read(currentUserProvider)?.id;
        if (userId != null) {
          await ref.read(followProvider.notifier).loadFollowData(userId);
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredFollowing.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final following = filteredFollowing[index];
          return _UserListItem(
            userId: following.id,
            displayName: following.displayName,
            avatarUrl: following.avatarUrl,
            isFollowing: true,
            onFollowTap: () {
              ref.read(followProvider.notifier)
                  .toggleFollow(following.id);
            },
            onTap: () {
              Navigator.pushNamed(
                context,
                AppRouter.profile,
                arguments: following.id,
              );
            },
          );
        },
      ),
    );
  }

  void _showFindFriendsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _FindFriendsBottomSheet(),
    );
  }
}

/// Bottom sheet for finding friends with search functionality
class _FindFriendsBottomSheet extends ConsumerStatefulWidget {
  const _FindFriendsBottomSheet();

  @override
  ConsumerState<_FindFriendsBottomSheet> createState() => _FindFriendsBottomSheetState();
}

class _FindFriendsBottomSheetState extends ConsumerState<_FindFriendsBottomSheet> {
  final _searchController = TextEditingController();
  bool _showSearchResults = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(userSearchProvider.notifier).searchUsers(query);
      setState(() => _showSearchResults = true);
    } else {
      ref.read(userSearchProvider.notifier).clear();
      setState(() => _showSearchResults = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(userSearchProvider);
    final followState = ref.watch(followProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Найз хайх',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(userSearchProvider.notifier).clear();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchTextField(
              controller: _searchController,
              hint: 'Нэр эсвэл хэрэглэгчийн нэрээр хайх...',
              onChanged: _performSearch,
              onSubmitted: _performSearch,
            ),
          ),
          const SizedBox(height: 16),

          // Content - either search results or options
          Expanded(
            child: _showSearchResults
                ? _buildSearchResults(searchState, followState, scrollController)
                : _buildSearchOptions(scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    UserSearchState searchState,
    FollowState followState,
    ScrollController scrollController,
  ) {
    if (searchState.isLoading) {
      return const Center(child: LoadingWidget(message: 'Хайж байна...'));
    }

    if (searchState.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '"${searchState.query}" гэсэн хэрэглэгч олдсонгүй',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: searchState.results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final user = searchState.results[index];
        final isFollowing = followState.following.any((f) => f.id == user.id);

        return _UserListItem(
          userId: user.id,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          isFollowing: isFollowing,
          onFollowTap: () {
            ref.read(followProvider.notifier).toggleFollow(user.id);
          },
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(
              context,
              AppRouter.profile,
              arguments: user.id,
            );
          },
        );
      },
    );
  }

  Widget _buildSearchOptions(ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 16),
        Text(
          'Санал болгох',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Хэрэглэгч хайхын тулд дээрх талбарт нэрийг нь бичнэ үү',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _UserListItem extends ConsumerWidget {
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final bool isFollowing;
  final VoidCallback onFollowTap;
  final VoidCallback onTap;

  const _UserListItem({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.isFollowing,
    required this.onFollowTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(otherUserStatsProvider(userId));

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: AppAvatar(
        imageUrl: avatarUrl,
        name: displayName,
        size: 48,
      ),
      title: Text(displayName),
      subtitle: statsAsync.when(
        data: (stats) => Text('Түвшин ${stats.level} • ${stats.totalXp} XP'),
        loading: () => const Text('Уншиж байна...'),
        error: (_, __) => const Text('Түвшин 1 • 0 XP'),
      ),
      trailing: AppButton(
        text: isFollowing ? 'Дагаж байна' : 'Дагах',
        onPressed: onFollowTap,
        variant: isFollowing ? ButtonVariant.outline : ButtonVariant.primary,
        size: ButtonSize.small,
      ),
    );
  }
}
