import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../providers/auth_provider.dart';
// sound service removed from splash to disable app sounds
import 'package:lottie/lottie.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _fallbackTimer;
  bool _navigated = false;
  bool _authListenerRegistered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // After the first frame, start initialization. Auth listener is registered
    // during build to avoid Riverpod `ref.listen` assertion errors.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeStartup();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // splash auto-navigates; no manual continue

  Future<void> _initializeStartup() async {
    try {
      // Precache app icon for instant display (don't await to avoid context across async gap)
      precacheImage(const AssetImage('assets/icons/icon.png'), context);

    // Sound initialization removed
    // Defer heavy backend refresh (e.g. auth refresh) to avoid startup work.
    // If you need to trigger a refresh, call `authProvider.notifier.refreshUser()`
    // from a later lifecycle point.

      // Fallback: if auth doesn't resolve in a short time, navigate based on current state
      _fallbackTimer?.cancel();
      _fallbackTimer = Timer(const Duration(seconds: 5), () {
        if (_navigated) return;
        final state = ref.read(authProvider);
        _navigated = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (state.isAuthenticated && state.user != null) {
            Navigator.of(context).pushReplacementNamed('/home');
          } else {
            Navigator.of(context).pushReplacementNamed('/auth');
          }
        });
      });

      // Additional app-level initialization hooks could go here if needed
      // e.g., prefetch images, warm up providers, start sync, etc.
    } catch (_) {
      // Ignore non-fatal startup errors; navigation will still proceed when auth finishes
    }
  }

  @override
  Widget build(BuildContext context) {
    // Register auth listener once during build to safely use ref.listen
    if (!_authListenerRegistered) {
      _authListenerRegistered = true;
      ref.listen<AuthState>(authProvider, (previous, next) {
        if (!next.isLoading) {
          if (_navigated) return;
          _navigated = true;
          _fallbackTimer?.cancel();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (next.isAuthenticated && next.user != null) {
              Navigator.of(context).pushReplacementNamed('/home');
            } else {
              Navigator.of(context).pushReplacementNamed('/auth');
            }
          });
        }
      });
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFA726), // orange
              Color(0xFFFFEB3B), // yellow
            ],
          ),
        ),
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  alignment: Alignment.center,
                  scale: _scaleAnimation,
                  child: SizedBox.expand(child: child),
                ),
              );
            },
            child: Stack(
              children: [
                // Use the same illustration as the auth screen, centered
                Center(
                  child: SizedBox(
                    width: 260,
                    height: 260,
                    child: Image.asset('assets/images/auth.png', fit: BoxFit.contain),
                  ),
                ),

                // Loader placed below center; smaller and tinted white
                Align(
                  alignment: const Alignment(0, 0.65),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ColorFiltered(
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                        child: Lottie.asset(
                          'assets/images/icons8-spinning-circle.json',
                          width: 56,
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ачаалж байна...',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
