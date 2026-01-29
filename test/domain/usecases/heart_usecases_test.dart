import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tenzin/domain/usecases/heart_usecases.dart';
import 'package:tenzin/data/repositories/heart_repository.dart';
import 'package:tenzin/data/models/heart_state.dart';

class MockHeartRepository extends Mock implements HeartRepository {}

void main() {
  group('UseHeartUseCase', () {
    late MockHeartRepository mockRepository;
    late UseHeartUseCase useCase;

    setUp(() {
      mockRepository = MockHeartRepository();
      useCase = UseHeartUseCase(mockRepository);
    });

    test('should use heart and return updated state', () async {
      final initialState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 5,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      final expectedState = initialState.loseHeart();

      when(() => mockRepository.useHeart(any()))
          .thenAnswer((_) async => (heartState: expectedState, failure: null));

      final result = await useCase.call('user_123');

      expect(result.heartState?.currentHearts, 4);
      verify(() => mockRepository.useHeart('user_123')).called(1);
    });

    test('should not use heart when empty', () async {
      final emptyState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 0,
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.useHeart(any()))
          .thenAnswer((_) async => (heartState: emptyState, failure: null));

      final result = await useCase.call('user_123');

      expect(result.heartState?.currentHearts, 0);
      expect(result.heartState?.isEmpty, true);
    });
  });

  group('RefillHeartsUseCase', () {
    late MockHeartRepository mockRepository;
    late RefillHeartsUseCase useCase;

    setUp(() {
      mockRepository = MockHeartRepository();
      useCase = RefillHeartsUseCase(mockRepository);
    });

    test('should refill hearts to max', () async {
      final expectedState = HeartStateModel.initial('user_123');

      when(() => mockRepository.refillHearts(any()))
          .thenAnswer((_) async => (heartState: expectedState, failure: null));

      final result = await useCase.call('user_123');

      expect(result.heartState?.currentHearts, HeartStateModel.maxHearts);
      expect(result.heartState?.isFull, true);
      verify(() => mockRepository.refillHearts('user_123')).called(1);
    });
  });

  group('GetHeartStateUseCase', () {
    late MockHeartRepository mockRepository;
    late GetHeartStateUseCase useCase;

    setUp(() {
      mockRepository = MockHeartRepository();
      useCase = GetHeartStateUseCase(mockRepository);
    });

    test('should return current heart state', () async {
      final now = DateTime.now();
      final expectedState = HeartStateModel(
        userId: 'user_123',
        currentHearts: 3,
        lastHeartLossAt: now.subtract(const Duration(minutes: 10)),
        lastRegenerationAt: now.subtract(const Duration(minutes: 10)),
        lastModifiedAt: now.millisecondsSinceEpoch,
      );

      when(() => mockRepository.getHeartState(any()))
          .thenAnswer((_) async => (heartState: expectedState, failure: null));

      final result = await useCase.call('user_123');

      expect(result.heartState?.userId, 'user_123');
      expect(result.heartState?.currentHearts, 3);
      expect(result.heartState?.isFull, false);
    });

    test('should create initial state if none exists', () async {
      final expectedState = HeartStateModel.initial('new_user');

      when(() => mockRepository.getHeartState(any()))
          .thenAnswer((_) async => (heartState: expectedState, failure: null));

      final result = await useCase.call('new_user');

      expect(result.heartState?.currentHearts, HeartStateModel.maxHearts);
      expect(result.heartState?.isFull, true);
    });
  });

  group('GetCurrentHeartsUseCase', () {
    late MockHeartRepository mockRepository;
    late GetCurrentHeartsUseCase useCase;

    setUp(() {
      mockRepository = MockHeartRepository();
      useCase = GetCurrentHeartsUseCase(mockRepository);
    });

    test('should return current heart count', () async {
      when(() => mockRepository.getCurrentHearts(any()))
          .thenAnswer((_) async => 3);

      final result = await useCase.call('user_123');

      expect(result, 3);
    });
  });

  group('HasHeartsUseCase', () {
    late MockHeartRepository mockRepository;
    late HasHeartsUseCase useCase;

    setUp(() {
      mockRepository = MockHeartRepository();
      useCase = HasHeartsUseCase(mockRepository);
    });

    test('should return true when user has hearts', () async {
      when(() => mockRepository.hasHearts(any()))
          .thenAnswer((_) async => true);

      final result = await useCase.call('user_123');

      expect(result, true);
    });

    test('should return false when user has no hearts', () async {
      when(() => mockRepository.hasHearts(any()))
          .thenAnswer((_) async => false);

      final result = await useCase.call('user_123');

      expect(result, false);
    });
  });
}
