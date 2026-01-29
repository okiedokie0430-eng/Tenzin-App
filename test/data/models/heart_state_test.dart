import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/data/models/heart_state.dart';

void main() {
  group('HeartStateModel', () {
    test('should create initial state with max hearts', () {
      final heartState = HeartStateModel.initial('user_123');

      expect(heartState.userId, 'user_123');
      expect(heartState.currentHearts, HeartStateModel.maxHearts);
      expect(heartState.isFull, true);
      expect(heartState.isEmpty, false);
    });

    test('should lose heart correctly', () {
      final heartState = HeartStateModel.initial('user_123');
      final afterLoss = heartState.loseHeart();

      expect(afterLoss.currentHearts, HeartStateModel.maxHearts - 1);
      expect(afterLoss.lastHeartLossAt, isNotNull);
      expect(afterLoss.isFull, false);
    });

    test('should not lose heart when empty', () {
      final heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 0,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );
      final afterLoss = heartState.loseHeart();

      expect(afterLoss.currentHearts, 0);
      expect(afterLoss.isEmpty, true);
    });

    test('should refill hearts to max', () {
      final heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 2,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );
      final afterRefill = heartState.refillHearts();

      expect(afterRefill.currentHearts, HeartStateModel.maxHearts);
      expect(afterRefill.isFull, true);
    });

    test('should calculate time until next heart', () {
      final now = DateTime.now();
      final heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 3,
        lastHeartLossAt: now,
        lastRegenerationAt: now,
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      final timeUntilNext = heartState.timeUntilNextHeart;

      expect(timeUntilNext.inMinutes, lessThanOrEqualTo(HeartStateModel.regenerationMinutes));
      expect(timeUntilNext.inMinutes, greaterThan(0));
    });

    test('should have zero time until next heart when full', () {
      final heartState = HeartStateModel.initial('user_123');

      expect(heartState.timeUntilNextHeart, Duration.zero);
    });

    test('should convert to Map and back', () {
      final heartState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 3,
        lastHeartLossAt: DateTime(2024, 1, 1),
        lastRegenerationAt: DateTime(2024, 1, 1),
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final map = heartState.toMap();
      final fromMap = HeartStateModel.fromMap(map);

      expect(fromMap.userId, heartState.userId);
      expect(fromMap.currentHearts, heartState.currentHearts);
    });

    test('maxHearts should be 5', () {
      expect(HeartStateModel.maxHearts, 5);
    });

    test('regenerationMinutes should be 20', () {
      expect(HeartStateModel.regenerationMinutes, 20);
    });
  });
}
