import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/progress_provider.dart';
import '../../providers/auth_provider.dart';

class StreakOverviewScreen extends ConsumerWidget {
  const StreakOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final progressState = ref.watch(progressProvider);

    final streak = user?.streak ?? 0;

    // Build a set of completed dates (local date-only)
    final completedDates = <DateTime>{};
    for (final p in progressState.progressList) {
      if (p.completedAt != null) {
        final d = DateTime(p.completedAt!.year, p.completedAt!.month, p.completedAt!.day);
        completedDates.add(d);
      }
    }

    // Current date
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Streak'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // Prominent streak card with gradient
            Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.streakOrange.withOpacity(0.95), AppColors.streakOrange.withOpacity(0.55)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.streakOrange.withOpacity(0.18), blurRadius: 24, offset: const Offset(0, 8))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12)],
                    ),
                    child: Center(child: Icon(Icons.local_fire_department_rounded, size: 36, color: AppColors.streakOrange)),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$streak', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('хоног', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Week preview (last 7 days)
            _WeekPreview(completedDates: completedDates),

            const SizedBox(height: 18),

            // Month title and calendar card
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_monthName(today)} ${today.year}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            // Weekday labels (Mongolian short names)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: ['Ням','Дав','Мяг','Лха','Пүр','Баа','Бям'].map((w) => Expanded(
                child: Center(child: Text(w, style: Theme.of(context).textTheme.bodySmall)),
              )).toList(),
            ),
            const SizedBox(height: 8),

            // Calendar grid inside a subtle surface card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0,4))],
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  // Build calendar slots for the current month
                  final firstOfMonth = DateTime(today.year, today.month, 1);
                  final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
                  final startWeekday = firstOfMonth.weekday % 7; // make Sunday=0

                  final totalSlots = startWeekday + daysInMonth;
                  final rows = (totalSlots / 7).ceil();

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: rows * 7,
                    itemBuilder: (context, index) {
                      final dayIndex = index - startWeekday + 1;
                      if (dayIndex < 1 || dayIndex > daysInMonth) {
                        return const SizedBox.shrink();
                      }
                      final d = DateTime(today.year, today.month, dayIndex);
                      final done = completedDates.contains(DateTime(d.year, d.month, d.day));
                      return _DayTile(date: d, done: done);
                    },
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),
            Text('Streak-ээ хадгалахын тулд өдөр бүр хичээлээ хийгээрэй.', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ойлголоо'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekPreview extends StatelessWidget {
  final Set<DateTime> completedDates;
  const _WeekPreview({required this.completedDates});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final last7 = List<DateTime>.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: last7.map((d) {
        final done = completedDates.contains(DateTime(d.year, d.month, d.day));
        return Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: done ? AppColors.streakOrange : Colors.grey.shade800,
              child: done ? const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 18) : const SizedBox.shrink(),
            ),
            const SizedBox(height: 6),
            Text(
              _shortWeekday(d.weekday),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  String _shortWeekday(int wd) {
    switch (wd) {
      case DateTime.monday:
        return 'Да';
      case DateTime.tuesday:
        return 'Мя';
      case DateTime.wednesday:
        return 'Лх';
      case DateTime.thursday:
        return 'Пү';
      case DateTime.friday:
        return 'Ба';
      case DateTime.saturday:
        return 'Бя';
      default:
        return 'Ня';
    }
  }
}

class _DayTile extends StatelessWidget {
  final DateTime date;
  final bool done;
  const _DayTile({required this.date, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: done ? AppColors.streakOrange : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: done ? AppColors.streakOrange : Theme.of(context).colorScheme.onSurface.withOpacity(0.08)),
      ),
      child: Center(
        child: Text(
          '${date.day}',
          style: TextStyle(color: done ? Colors.white : Theme.of(context).textTheme.bodySmall?.color),
        ),
      ),
    );
  }
}

String _monthName(DateTime d) {
  const names = [
    '1-р сар','2-р сар','3-р сар','4-р сар','5-р сар','6-р сар','7-р сар','8-р сар','9-р сар','10-р сар','11-р сар','12-р сар'
  ];
  return names[d.month - 1];
}
