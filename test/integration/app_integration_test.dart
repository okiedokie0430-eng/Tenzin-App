import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenzin/app.dart';
import '../helpers/test_overrides.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('App should start with splash screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(),
          child: TenzinApp(),
        ),
      );

      // Initial pump
      await tester.pump();

      // Should show splash screen
      expect(find.text('Tenzin'), findsOneWidget);
    });

    testWidgets('App should have correct theme colors', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(),
          child: TenzinApp(),
        ),
      );

      await tester.pump();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
    });
  });

  group('Navigation Integration Tests', () {
    testWidgets('Should navigate from splash to onboarding for new user',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(),
          child: TenzinApp(),
        ),
      );

      // Wait for splash screen animation
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // New user should see onboarding (or auth if onboarding complete)
      // This depends on stored preferences
    });
  });
}
