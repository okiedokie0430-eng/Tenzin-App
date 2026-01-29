import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/data/models/user.dart';

void main() {
  group('UserModel', () {
    test('should create UserModel with required fields', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(user.id, 'user_123');
      expect(user.email, 'test@example.com');
      expect(user.displayName, 'Test User');
    });

    test('should convert UserModel to Map and back', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        totalXp: 4500, // This gives level 5 (4500/1000 + 1 = 5)
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final map = user.toMap();
      final fromMap = UserModel.fromMap(map);

      expect(fromMap.id, user.id);
      expect(fromMap.email, user.email);
      expect(fromMap.displayName, user.displayName);
      expect(fromMap.level, user.level);
      expect(fromMap.totalXp, user.totalXp);
    });

    test('should handle null optional fields', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(user.avatarUrl, isNull);
      expect(user.username, isNull);
      expect(user.bio, isNull);
    });

    test('copyWith should update specified fields only', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        totalXp: 0, // level 1
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final updatedUser = user.copyWith(
        displayName: 'Updated Name',
        totalXp: 4500, // level 5
      );

      expect(updatedUser.id, user.id);
      expect(updatedUser.email, user.email);
      expect(updatedUser.displayName, 'Updated Name');
      expect(updatedUser.level, 5);
    });

    test('level should be computed from totalXp', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        totalXp: 2500,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      // level = totalXp / 1000 + 1 = 2500/1000 + 1 = 3
      expect(user.level, 3);
    });

    test('streak should be alias for currentStreakDays', () {
      final user = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        currentStreakDays: 7,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      expect(user.streak, 7);
      expect(user.streak, user.currentStreakDays);
    });
  });

  group('SyncStatus', () {
    test('should have correct enum values', () {
      expect(SyncStatus.values.length, 4);
      expect(SyncStatus.synced.name, 'synced');
      expect(SyncStatus.pending.name, 'pending');
      expect(SyncStatus.failed.name, 'failed');
      expect(SyncStatus.pendingDelete.name, 'pendingDelete');
    });
  });
}
