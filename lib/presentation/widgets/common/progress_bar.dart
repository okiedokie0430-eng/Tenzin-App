import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final BorderRadius? borderRadius;
  final bool showPercentage;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.progressColor,
    this.borderRadius,
    this.showPercentage = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final radius = borderRadius ?? BorderRadius.circular(height / 2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Container(
            height: height,
            color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: clampedProgress),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: progressColor ?? Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(height: 4),
          Text(
            '${(clampedProgress * 100).toInt()}%',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ],
    );
  }
}

class GradientProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final List<Color> gradientColors;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const GradientProgressBar({
    super.key,
    required this.progress,
    required this.gradientColors,
    this.height = 8,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final radius = borderRadius ?? BorderRadius.circular(height / 2);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: clampedProgress),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, value, _) {
            return Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: value,
                alignment: Alignment.centerLeft,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class CircularProgressWidget extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final Widget? child;

  const CircularProgressWidget({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.progressColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: strokeWidth,
              backgroundColor: Colors.transparent,
              color: backgroundColor ??
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: clampedProgress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              builder: (context, value, _) {
                return CircularProgressIndicator(
                  value: value,
                  strokeWidth: strokeWidth,
                  backgroundColor: Colors.transparent,
                  color: progressColor ?? Theme.of(context).colorScheme.primary,
                  strokeCap: StrokeCap.round,
                );
              },
            ),
          ),
          if (child != null) Center(child: child),
        ],
      ),
    );
  }
}

class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? activeColor;
  final Color? inactiveColor;
  final double size;

  const StepProgress({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.activeColor,
    this.inactiveColor,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalSteps,
        (index) {
          final isActive = index < currentStep;
          final isCurrent = index == currentStep;
          return Container(
            width: isCurrent ? size * 2 : size,
            height: size,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive || isCurrent
                  ? (activeColor ?? Theme.of(context).colorScheme.primary)
                  : (inactiveColor ??
                      Theme.of(context).colorScheme.surfaceContainerHighest),
              borderRadius: BorderRadius.circular(size / 2),
            ),
          );
        },
      ),
    );
  }
}

class LevelProgress extends StatelessWidget {
  final int currentXp;
  final int xpForNextLevel;
  final int level;
  final Color? progressColor;

  const LevelProgress({
    super.key,
    required this.currentXp,
    required this.xpForNextLevel,
    required this.level,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentXp / xpForNextLevel;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Түвшин $level',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '$currentXp / $xpForNextLevel XP',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ProgressBar(
          progress: progress,
          height: 10,
          progressColor: progressColor,
        ),
      ],
    );
  }
}
