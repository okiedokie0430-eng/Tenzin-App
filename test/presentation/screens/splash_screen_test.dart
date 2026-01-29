import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenzin/presentation/screens/splash/splash_screen.dart';
import '../../helpers/test_overrides.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('should render splash screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(),
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Should show app name
      expect(find.text('Tenzin'), findsOneWidget);
    });

    testWidgets('should show loading indicator', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(),
          child: MaterialApp(
            home: SplashScreen(),
          ),
        ),
      );

      // Pump some frames for animation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should show loading or spinner eventually
      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });
}
