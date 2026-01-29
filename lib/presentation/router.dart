import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/lesson/lesson_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/achievements/achievements_screen.dart';
import 'screens/support/support_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/friends/friends_screen.dart';
import 'screens/dictionary/dictionary_screen.dart';
import 'screens/gallery/gallery_screen.dart';
import 'screens/credits/credits_screen.dart';
import '../core/animations/page_transitions.dart';

/// Application router
class AppRouter {
  // Route names
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/home';
  static const String lesson = '/lesson';
  static const String settings = '/settings';
  static const String achievements = '/achievements';
  static const String leaderboard = '/leaderboard';
  static const String support = '/support';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  // notifications route removed
  static const String friends = '/friends';
  static const String dictionary = '/dictionary';
  static const String gallery = '/gallery';
  static const String credits = '/credits';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
        );
      case onboarding:
        return FadeScalePageRoute(
          page: const OnboardingScreen(),
          settings: settings,
        );
      case auth:
        return FadeScalePageRoute(
          page: const AuthScreen(),
          settings: settings,
        );
      case home:
        return FadeScalePageRoute(
          page: const HomeScreen(),
          settings: settings,
        );
      case lesson:
        final lessonId = settings.arguments as String;
        return IOSPageRoute(
          page: LessonScreen(lessonId: lessonId),
          settings: settings,
        );
      case AppRouter.settings:
        return IOSPageRoute(
          page: const SettingsScreen(),
          settings: settings,
        );
      case achievements:
        return IOSPageRoute(
          page: const AchievementsScreen(),
          settings: settings,
        );
      case AppRouter.leaderboard:
        return IOSPageRoute(
          page: const HomeScreen(initialTab: 2),
          settings: settings,
        );
      case AppRouter.support:
        return IOSPageRoute(
          page: const SupportScreen(),
          settings: settings,
        );
      case AppRouter.profile:
        final userId = settings.arguments as String?;
        return IOSPageRoute(
          page: ProfileScreen(userId: userId),
          settings: settings,
        );
      case editProfile:
        return IOSPageRoute(
          page: const EditProfileScreen(),
          settings: settings,
        );
      // notifications route removed
      case AppRouter.friends:
        return IOSPageRoute(
          page: const FriendsScreen(),
          settings: settings,
        );
      case AppRouter.dictionary:
        return IOSPageRoute(
          page: const DictionaryScreen(),
          settings: settings,
        );
      case AppRouter.gallery:
        return IOSPageRoute(
          page: const GalleryScreen(),
          settings: settings,
        );
      case AppRouter.credits:
        return IOSPageRoute(
          page: const CreditsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}
