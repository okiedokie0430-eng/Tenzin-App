import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// iOS-style page route with smooth transitions
class IOSPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  @override
  // ignore: overridden_fields
  final bool fullscreenDialog;

  IOSPageRoute({
    required this.page,
    this.fullscreenDialog = false,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (fullscreenDialog) {
              // Modal presentation (slide up) - no secondary animation
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            }
            
            // Standard iOS push transition (slide from right)
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );

            final offsetAnimation = animation.drive(tween);

            // Secondary animation for the page being covered
            final secondaryTween = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: offsetAnimation,
              child: SlideTransition(
                position: secondaryAnimation.drive(secondaryTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        );
  
  @override
  bool get opaque => !fullscreenDialog;
}

/// Modal page route that slides up from bottom WITHOUT shifting previous page
/// Use this for image viewers, full-screen dialogs, etc.
class ModalPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  ModalPageRoute({
    required this.page,
    super.settings,
  }) : super(
          opaque: false,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}

/// Fade scale transition for modals and dialogs
class FadeScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeScalePageRoute({
    required this.page,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );

            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.85,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 200),
        );
}

/// Shared axis transition for navigation within same level
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final SharedAxisTransitionType transitionType;

  SharedAxisPageRoute({
    required this.page,
    this.transitionType = SharedAxisTransitionType.horizontal,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: transitionType,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        );
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

class _SharedAxisTransition extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final SharedAxisTransitionType transitionType;
  final Widget child;

  const _SharedAxisTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.transitionType,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );

    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      case SharedAxisTransitionType.vertical:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
      case SharedAxisTransitionType.scaled:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.9,
            end: 1.0,
          ).animate(curvedAnimation),
          child: FadeTransition(
            opacity: curvedAnimation,
            child: child,
          ),
        );
    }
  }
}

/// Spring animation curve for bouncy effects
class SpringCurve extends Curve {
  final double a;
  final double w;

  const SpringCurve({this.a = 0.15, this.w = 19.4});

  @override
  double transformInternal(double t) {
    return (-(2.71828 * (-a * t * w)) * (-1 + 2.71828 * (a * t * w))) +
        (2.71828 * (-a * t * w) * t * w);
  }
}

/// Animated container with spring physics
class AnimatedSpringContainer extends StatefulWidget {
  final Widget child;
  final bool isVisible;
  final Duration duration;
  final Offset slideOffset;

  const AnimatedSpringContainer({
    super.key,
    required this.child,
    this.isVisible = true,
    this.duration = const Duration(milliseconds: 400),
    this.slideOffset = const Offset(0, 0.1),
  });

  @override
  State<AnimatedSpringContainer> createState() => _AnimatedSpringContainerState();
}

class _AnimatedSpringContainerState extends State<AnimatedSpringContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    if (widget.isVisible) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedSpringContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Staggered animation for lists
class StaggeredListAnimation extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration delayBase;
  final Duration delayPerItem;
  final Duration animationDuration;

  const StaggeredListAnimation({
    super.key,
    required this.index,
    required this.child,
    this.delayBase = const Duration(milliseconds: 100),
    this.delayPerItem = const Duration(milliseconds: 50),
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  State<StaggeredListAnimation> createState() => _StaggeredListAnimationState();
}

class _StaggeredListAnimationState extends State<StaggeredListAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Stagger the animation based on index
    final delay = widget.delayBase + (widget.delayPerItem * widget.index);
    Future.delayed(delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Scale animation on tap for buttons
class TapScaleAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;

  const TapScaleAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
  });

  @override
  State<TapScaleAnimation> createState() => _TapScaleAnimationState();
}

class _TapScaleAnimationState extends State<TapScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
