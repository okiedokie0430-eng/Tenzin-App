import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/presentation/widgets/common/app_button.dart';

void main() {
  group('AppButton', () {
    testWidgets('should render with text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Click me',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Click me'), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Click me',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Click me'));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('should be disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('should show loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('AppButton Variants', () {
    testWidgets('should render primary variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Primary',
              onPressed: () {},
              variant: ButtonVariant.primary,
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should render outline variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Outlined',
              onPressed: () {},
              variant: ButtonVariant.outline,
            ),
          ),
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should render text variant', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Text',
              onPressed: () {},
              variant: ButtonVariant.text,
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  group('AppButton Sizes', () {
    testWidgets('should render small size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Small',
              onPressed: () {},
              size: ButtonSize.small,
            ),
          ),
        ),
      );

      expect(find.text('Small'), findsOneWidget);
    });

    testWidgets('should render large size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Large',
              onPressed: () {},
              size: ButtonSize.large,
            ),
          ),
        ),
      );

      expect(find.text('Large'), findsOneWidget);
    });
  });
}
