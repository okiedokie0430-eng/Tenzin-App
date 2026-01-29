import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'presentation/theme/app_theme.dart';
import 'presentation/router.dart';
import 'presentation/providers/settings_provider.dart';

/// Main application widget
class TenzinApp extends ConsumerWidget {
  const TenzinApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsState = ref.watch(settingsProvider);
    final theme = settingsState.settings?.theme ?? 'system';
    
    // Determine ThemeMode based on settings
    ThemeMode themeMode;
    switch (theme) {
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'light':
        themeMode = ThemeMode.light;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp(
      title: 'Tenzin - Төвөд хэл сурах',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        // Ensure status bar icons match current brightness (light/dark)
        final platformBrightness = MediaQuery.of(context).platformBrightness;
        final effectiveBrightness = themeMode == ThemeMode.system ? platformBrightness : (themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light);
        final overlay = effectiveBrightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
        // Apply overlay for each route build
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay.copyWith(statusBarColor: Colors.transparent),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
