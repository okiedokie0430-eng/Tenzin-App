import 'package:flutter_test/flutter_test.dart';
import 'package:tenzin/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('should have correct app name', () {
      expect(AppConstants.appName, 'Tenzin');
    });

    test('should have correct max hearts', () {
      expect(AppConstants.maxHearts, 5);
    });

    test('should have correct heart regeneration time', () {
      expect(AppConstants.heartRegenerationMinutes, 20);
    });

    test('should have correct XP per correct answer', () {
      expect(AppConstants.xpPerCorrectAnswer, isPositive);
    });

    test('should have correct XP bonus values', () {
      expect(AppConstants.xpBonusShortLesson, 10);
      expect(AppConstants.xpBonusMediumLesson, 15);
      expect(AppConstants.xpBonusLongLesson, 20);
    });
  });

  group('ApiEndpoints', () {
    test('should have correct Appwrite endpoint', () {
      expect(AppConstants.appwriteEndpoint, isNotEmpty);
    });

    test('should have correct Appwrite project ID', () {
      expect(AppConstants.appwriteProjectId, isNotEmpty);
    });
  });

  group('Storage Keys', () {
    test('should have auth token key', () {
      expect(AppConstants.keyAuthToken, isNotEmpty);
    });

    test('should have user id key', () {
      expect(AppConstants.keyUserId, isNotEmpty);
    });

    test('should have session id key', () {
      expect(AppConstants.keySessionId, isNotEmpty);
    });
  });
}
