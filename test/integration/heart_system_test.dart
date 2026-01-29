import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/data/models/heart_state.dart';

void main() {
  group('Heart System Integration', () {
    test('should regenerate hearts over time', () async {
      final now = DateTime.now();

      // Start with 3 hearts, lost one 25 minutes ago
      final heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 3,
        lastHeartLossAt: now.subtract(const Duration(minutes: 25)),
        lastRegenerationAt: now.subtract(const Duration(minutes: 25)),
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      // After 25 minutes, one heart is eligible for regeneration.
      expect(heartState.heartsToRegenerate, greaterThanOrEqualTo(1));

      final regenerated = heartState.regenerate();
      expect(regenerated.currentHearts, 4);

      // After regenerating, verify we have a reasonable time until next heart
      // The calculation depends on when regeneration happened relative to the cycle
      expect(regenerated.timeUntilNextHeart.inMinutes, lessThanOrEqualTo(20));
      expect(regenerated.timeUntilNextHeart.inMinutes, greaterThanOrEqualTo(0));
    });

    test('should handle heart loss and regeneration cycle', () {
      // Full hearts
      var heartState = HeartStateModel.initial('user_123');
      expect(heartState.currentHearts, 5);
      expect(heartState.isFull, true);

      // Lose a heart
      heartState = heartState.loseHeart();
      expect(heartState.currentHearts, 4);
      expect(heartState.isFull, false);
      expect(heartState.lastHeartLossAt, isNotNull);

      // Lose more hearts
      heartState = heartState.loseHeart();
      heartState = heartState.loseHeart();
      heartState = heartState.loseHeart();
      expect(heartState.currentHearts, 1);

      // Lose last heart
      heartState = heartState.loseHeart();
      expect(heartState.currentHearts, 0);
      expect(heartState.isEmpty, true);

      // Can't lose more
      heartState = heartState.loseHeart();
      expect(heartState.currentHearts, 0);

      // Refill
      heartState = heartState.refillHearts();
      expect(heartState.currentHearts, 5);
      expect(heartState.isFull, true);
    });

    test('should calculate regeneration time correctly', () {
      final now = DateTime.now();

      // Lost heart 10 minutes ago
      final heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 4,
        lastHeartLossAt: now.subtract(const Duration(minutes: 10)),
        lastRegenerationAt: now.subtract(const Duration(minutes: 10)),
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      final timeUntilNext = heartState.timeUntilNextHeart;

      // Should be about 10 minutes remaining (20 - 10 = 10)
      expect(timeUntilNext.inMinutes, lessThanOrEqualTo(10));
      expect(timeUntilNext.inMinutes, greaterThanOrEqualTo(9));
    });

    test('should handle bonus hearts', () {
      var heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 3,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Add 2 bonus hearts
      heartState = heartState.copyWith(
        currentHearts: heartState.currentHearts + 2,
      );

      // Should be full
      expect(heartState.currentHearts, 5);
      expect(heartState.isFull, true);

      // Can't exceed max
      heartState = heartState.copyWith(
        currentHearts:
            heartState.currentHearts > HeartStateModel.maxHearts
                ? HeartStateModel.maxHearts
                : heartState.currentHearts,
      );

      expect(heartState.currentHearts, HeartStateModel.maxHearts);
    });
  });

  group('Heart Display Format', () {
    test('should format time correctly', () {
      String formatTime(Duration duration) {
        final minutes = duration.inMinutes;
        final seconds = duration.inSeconds % 60;
        return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }

      expect(formatTime(const Duration(minutes: 15, seconds: 30)), '15:30');
      expect(formatTime(const Duration(minutes: 5, seconds: 5)), '05:05');
      expect(formatTime(const Duration(minutes: 0, seconds: 30)), '00:30');
      expect(formatTime(const Duration(minutes: 19, seconds: 59)), '19:59');
    });

    test('should show correct icon state', () {
      // 3 out of 5 hearts
      final heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 3,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final filledHearts = heartState.currentHearts;
      final emptyHearts = HeartStateModel.maxHearts - heartState.currentHearts;

      expect(filledHearts, 3);
      expect(emptyHearts, 2);
    });
  });
}
