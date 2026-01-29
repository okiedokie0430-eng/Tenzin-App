import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';

class StreakScreen extends StatefulWidget {
  final int streakDays;
  const StreakScreen({super.key, required this.streakDays});

  @override
  State<StreakScreen> createState() => _StreakScreenState();
}

class _StreakScreenState extends State<StreakScreen> with TickerProviderStateMixin {
  late AnimationController _flameController;
  late AnimationController _popController;
  late AnimationController _exitController;
  late Animation<double> _flameScale;
  late Animation<double> _popScale;
  late Animation<double> _popFade;

  @override
  void initState() {
    super.initState();
    // Slightly slower, smoother flame
    _flameController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _flameScale = Tween<double>(begin: 0.75, end: 1.08).animate(CurvedAnimation(parent: _flameController, curve: Curves.easeInOut));
    _flameController.repeat(reverse: true);

    // Pop animation - elastic but a touch faster
    _popController = AnimationController(vsync: this, duration: const Duration(milliseconds: 580));
    _popScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _popController, curve: Curves.elasticOut));
    _popFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _popController, curve: Curves.easeIn));

    // Exit fade controller (used when closing)
    _exitController = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));

    // Start pop after a short delay so flame animates first
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _popController.forward();
    });
  }

  @override
  void dispose() {
    _flameController.dispose();
    _popController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Widget _buildWeekRow() {
    final days = ['Ня','Да','Мя','Лх','Пү','Ба','Бя'];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: days.map((d) => Expanded(
            child: Center(child: Text(d, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12))),
          )).toList(),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 14, width: w, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(10))),
              Container(height: 14, width: w * (math.min(widget.streakDays,7)/7), decoration: BoxDecoration(color: AppColors.streakOrange, borderRadius: BorderRadius.circular(10))),
              // glowing indicator at progress end
              Positioned(left: (w * (math.min(widget.streakDays,7)/7)) - 12, child: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: AppColors.streakOrange.withOpacity(0.6), blurRadius: 12)])))
            ],
          );
        })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn)),
      child: Material(
        color: Colors.black.withOpacity(0.45),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 12,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated flame inside a softened circular surface
                      ScaleTransition(
                        scale: _flameScale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(colors: [AppColors.streakOrange.withOpacity(0.95), AppColors.streakOrange.withOpacity(0.6)]),
                            boxShadow: [BoxShadow(color: AppColors.streakOrange.withOpacity(0.18), blurRadius: 18, spreadRadius: 4)],
                          ),
                          child: Center(child: Icon(Icons.local_fire_department_rounded, size: 46, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Pop-in streak number
                      FadeTransition(
                        opacity: _popFade,
                        child: ScaleTransition(
                          scale: _popScale,
                          child: Column(
                            children: [
                              Text('${widget.streakDays}', style: theme.textTheme.displayLarge?.copyWith(color: AppColors.streakOrange, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              Text('Хоног', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildWeekRow(),
                      const SizedBox(height: 18),
                      Text('Та гайхалтай байна! Streak-ээ хадгалахын тулд өдөр бүр хичээлээ хийж байгаарай.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            final navigator = Navigator.of(context);
                            try {
                              await _popController.reverse();
                            } catch (_) {}
                            if (mounted) await _exitController.forward();
                            if (mounted) navigator.pop();
                          },
                          style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: const Text('Би чадна аа!', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
