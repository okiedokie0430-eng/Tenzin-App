import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/achievement.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/achievement/achievement_card.dart';

class OtherUserAchievementsScreen extends ConsumerWidget {
  final String userId;
  const OtherUserAchievementsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(achievementRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Шагнал'),
      ),
      body: FutureBuilder(
        future: repo.getAchievementsWithStatus(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const Center(child: Text('Ачааллахад алдаа гарлаа'));
          }

            final result = snap.data as dynamic;
            final all = (result?.achievements as List<AchievementWithStatus>? ?? [])
              .where((a) => a.isUnlocked)
              .toList();

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: all.length,
              itemBuilder: (context, index) {
                final a = all[index];
                return GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: AchievementCard(achievement: a),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: AchievementBadge(achievement: a, size: 64),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
