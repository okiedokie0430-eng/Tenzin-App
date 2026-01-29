// =============================================================================
// ACHIEVEMENT UNLOCK PRESENTATION
// =============================================================================
// FIXES:
// - Crash on multiple achievements: Added _isDisposed guard, proper cleanup
// - Centering: Using Center + MainAxisSize.min for proper alignment
// - Semi-transparent background: 75% opacity to show underlying screen
// - Performance: Reduced animation durations and particle count
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../data/models/achievement.dart';
import '../../../core/constants/app_colors.dart';

/// iOS-inspired achievement unlock presentation with fancy animations
/// Shows centered celebration when user unlocks an achievement
class AchievementUnlockPresentation extends StatefulWidget {
  final AchievementWithStatus achievement;
  final VoidCallback? onDismiss;

  const AchievementUnlockPresentation({
    super.key,
    required this.achievement,
    this.onDismiss,
  });

  @override
  State<AchievementUnlockPresentation> createState() =>
      _AchievementUnlockPresentationState();
}

class _AchievementUnlockPresentationState
    extends State<AchievementUnlockPresentation> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _confettiController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _confettiAnimation;
  late Animation<double> _shimmerAnimation;

  final List<_Confetti> _confettiParticles = [];
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();

    // Scale animation for the badge - reduced duration
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Rotation animation for the badge
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: -0.08, end: 0.0).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.easeOut),
    );

    // Fade animation for text
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Confetti animation - reduced duration for performance
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );
    _confettiAnimation = CurvedAnimation(
      parent: _confettiController,
      curve: Curves.easeOut,
    );

    // Shimmer animation for gold shine effect
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _shimmerAnimation = CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    );

    // Generate confetti particles - reduced count for low-end devices
    _generateConfetti();

    // Start animations with delays - guarded for disposal
    _startAnimations();
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_isDisposed && mounted) {
        _scaleController.forward();
        _rotateController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_isDisposed && mounted) {
        _fadeController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!_isDisposed && mounted) {
        _confettiController.forward();
      }
    });
  }

  void _generateConfetti() {
    final random = math.Random();
    // Reduced particle count (30 instead of 50) for better performance
    for (int i = 0; i < 30; i++) {
      _confettiParticles.add(_Confetti(
        x: random.nextDouble(),
        y: -0.1 - random.nextDouble() * 0.2,
        color: _getRandomConfettiColor(random),
        size: 4.0 + random.nextDouble() * 6.0,
        rotation: random.nextDouble() * math.pi * 2,
        velocityY: 0.3 + random.nextDouble() * 0.4,
        velocityX: -0.1 + random.nextDouble() * 0.2,
      ));
    }
  }

  Color _getRandomConfettiColor(math.Random random) {
    final colors = [
      AppColors.gold,
      AppColors.primary,
      AppColors.accent,
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.pink,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scaleController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleDismiss() {
    if (_isDisposed) return;
    // Ensure the dialog is dismissed by this widget so callers don't need to pop.
    if (mounted) {
      try {
        Navigator.of(context).pop();
      } catch (_) {}
    }
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Material(
      // SEMI-TRANSPARENT BACKGROUND - shows underlying screen
      color: Colors.black.withOpacity(0.75),
      child: Stack(
        children: [
          // Tap to dismiss anywhere
          GestureDetector(
            onTap: _handleDismiss,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),

          // Confetti particles
          AnimatedBuilder(
            animation: _confettiAnimation,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _ConfettiPainter(
                  particles: _confettiParticles,
                  progress: _confettiAnimation.value,
                ),
              );
            },
          ),

          // Main content - CENTERED
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Achievement badge with animations
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: RotationTransition(
                        turns: _rotateAnimation,
                        child: AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.gold,
                                    AppColors.gold.withOpacity(0.8),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Shimmer effect
                                  Positioned.fill(
                                    child: ClipOval(
                                      child: CustomPaint(
                                        painter: _ShimmerPainter(
                                          progress: _shimmerAnimation.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Icon
                                  Center(
                                    child: Icon(
                                      _getAchievementIcon(),
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Achievement unlocked text
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            'ШАГНАЛ АВЛАА!',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.achievement.achievement.name,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.achievement.achievement.description,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Tap to continue button
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: TextButton(
                        onPressed: _handleDismiss,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Text(
                          'Үргэлжлүүлэх',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAchievementIcon() {
    switch (widget.achievement.achievement.type) {
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'lessons':
        return Icons.school_rounded;
      case 'xp':
        return Icons.stars_rounded;
      case 'perfect':
        return Icons.diamond_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'time':
        return Icons.access_time_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

// Confetti particle data class
class _Confetti {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double rotation;
  final double velocityY;
  final double velocityX;

  _Confetti({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.rotation,
    required this.velocityY,
    required this.velocityX,
  });
}

// Custom painter for confetti
class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(1.0 - progress * 0.5)
        ..style = PaintingStyle.fill;

      final x =
          particle.x * size.width + particle.velocityX * progress * size.width;
      final y = particle.y * size.height +
          particle.velocityY * progress * size.height;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(particle.rotation + progress * math.pi * 2);

      // Draw confetti as small rectangles
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: particle.size,
            height: particle.size * 1.5,
          ),
          const Radius.circular(2),
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}

// Custom painter for shimmer effect
class _ShimmerPainter extends CustomPainter {
  final double progress;

  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(_ShimmerPainter oldDelegate) => true;
}
