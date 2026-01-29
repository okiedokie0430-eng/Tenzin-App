import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8B4513),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFFFDCC2),
        onPrimaryContainer: Color(0xFF2E1500),
        secondary: Color(0xFFD4A574),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFFFE8D6),
        onSecondaryContainer: Color(0xFF2B1700),
        tertiary: Color(0xFFFFB347),
        onTertiary: Colors.white,
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        surface: Color(0xFFFFFBFF),
        onSurface: Color(0xFF1F1B16),
        surfaceContainerHighest: Color(0xFFEDE0D4),
        onSurfaceVariant: Color(0xFF51453A),
        outline: Color(0xFF837468),
      ),
      scaffoldBackgroundColor: const Color(0xFFFFFBFF),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFFFFFBFF),
        foregroundColor: Color(0xFF1F1B16),
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F1B16),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMongolian',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMongolian',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMongolian',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F0EB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8B4513), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFBA1A1A), width: 1),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'NotoSansMongolian',
          color: Color(0xFF837468),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'NotoSansMongolian',
          color: Color(0xFF51453A),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 32,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 28,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
        titleMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),
        labelLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFF8B4513),
        unselectedItemColor: Color(0xFF837468),
        selectedLabelStyle: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFEDE0D4),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFFFE8D6),
        labelStyle: const TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          color: Color(0xFF2B1700),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFF8B4513),
        linearTrackColor: Color(0xFFEDE0D4),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFB77C),
        onPrimary: Color(0xFF4A2800),
        primaryContainer: Color(0xFF6A3C00),
        onPrimaryContainer: Color(0xFFFFDCC2),
        secondary: Color(0xFFE7C4A8),
        onSecondary: Color(0xFF432C1A),
        secondaryContainer: Color(0xFF5C422E),
        onSecondaryContainer: Color(0xFFFFDCC2),
        tertiary: Color(0xFFFFB347),
        onTertiary: Color(0xFF462A00),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        surface: Color(0xFF1F1B16),
        onSurface: Color(0xFFEAE1D9),
        surfaceContainerHighest: Color(0xFF3D3832),
        onSurfaceVariant: Color(0xFFD5C4B5),
        outline: Color(0xFF9D8E81),
      ),
      scaffoldBackgroundColor: const Color(0xFF1F1B16),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF1F1B16),
        foregroundColor: Color(0xFFEAE1D9),
        titleTextStyle: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Color(0xFFEAE1D9),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF2D2822),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMongolian',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMongolian',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'NotoSansMongolian',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2822),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB77C), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFB4AB), width: 1),
        ),
        hintStyle: const TextStyle(
          fontFamily: 'NotoSansMongolian',
          color: Color(0xFF9D8E81),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'NotoSansMongolian',
          color: Color(0xFFD5C4B5),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: Color(0xFFEAE1D9),
        ),
        displayMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 45,
          fontWeight: FontWeight.w400,
          color: Color(0xFFEAE1D9),
        ),
        displaySmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 36,
          fontWeight: FontWeight.w400,
          color: Color(0xFFEAE1D9),
        ),
        headlineLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFFEAE1D9),
        ),
        headlineMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFFEAE1D9),
        ),
        headlineSmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Color(0xFFEAE1D9),
        ),
        titleLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFFEAE1D9),
        ),
        titleMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: Color(0xFFEAE1D9),
        ),
        titleSmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFFEAE1D9),
        ),
        bodyLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: Color(0xFFEAE1D9),
        ),
        bodyMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: Color(0xFFEAE1D9),
        ),
        bodySmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Color(0xFFEAE1D9),
        ),
        labelLarge: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFFEAE1D9),
        ),
        labelMedium: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFFEAE1D9),
        ),
        labelSmall: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFFEAE1D9),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Color(0xFF2D2822),
        selectedItemColor: Color(0xFFFFB77C),
        unselectedItemColor: Color(0xFF9D8E81),
        selectedLabelStyle: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFFFB77C),
        foregroundColor: Color(0xFF4A2800),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF3D3832),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF5C422E),
        labelStyle: const TextStyle(
          fontFamily: 'NotoSansMongolian',
          fontSize: 14,
          color: Color(0xFFFFDCC2),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Color(0xFFFFB77C),
        linearTrackColor: Color(0xFF3D3832),
      ),
    );
  }
}
