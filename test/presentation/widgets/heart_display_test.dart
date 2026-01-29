import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/presentation/widgets/common/heart_display.dart';

void main() {
  group('HeartDisplay', () {
    testWidgets('should show correct number of filled hearts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeartDisplay(
              currentHearts: 3,
              maxHearts: 5,
            ),
          ),
        ),
      );

      // Should find heart icons
      expect(find.byIcon(Icons.favorite), findsWidgets);
    });

    testWidgets('should show countdown when not full', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeartDisplay(
              currentHearts: 3,
              maxHearts: 5,
              timeToNextHeart: Duration(minutes: 15, seconds: 30),
            ),
          ),
        ),
      );

      // Should show time
      expect(find.textContaining('15'), findsOneWidget);
    });

    testWidgets('should not show countdown when full', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeartDisplay(
              currentHearts: 5,
              maxHearts: 5,
            ),
          ),
        ),
      );

      // All hearts should be full - find the heart icon
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('HeartRow', () {
    testWidgets('should render correct hearts based on count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeartRow(
              currentHearts: 3,
              maxHearts: 5,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsNWidgets(3));
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(2));
    });

    testWidgets('should show all empty hearts when count is 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HeartRow(
              currentHearts: 0,
              maxHearts: 5,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.favorite), findsNothing);
      expect(find.byIcon(Icons.favorite_border), findsNWidgets(5));
    });
  });
}
