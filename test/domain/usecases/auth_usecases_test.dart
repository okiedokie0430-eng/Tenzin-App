import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tenzin/domain/usecases/auth_usecases.dart';
import 'package:tenzin/data/repositories/auth_repository.dart';
import 'package:tenzin/data/models/user.dart';
import 'package:tenzin/core/error/failures.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SignInWithEmailUseCase', () {
    late MockAuthRepository mockRepository;
    late SignInWithEmailUseCase useCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignInWithEmailUseCase(mockRepository);
    });

    test('should return user when login is successful', () async {
      final expectedUser = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => (user: expectedUser, failure: null));

      final result = await useCase.call(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result.user, expectedUser);
      expect(result.failure, isNull);
      verify(() => mockRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          )).called(1);
    });

    test('should return failure when login fails', () async {
      when(() => mockRepository.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => (user: null, failure: Failure.auth('Invalid credentials')));

      final result = await useCase.call(
        email: 'test@example.com',
        password: 'wrongpassword',
      );

      expect(result.user, isNull);
      expect(result.failure, isNotNull);
    });
  });

  group('SignOutUseCase', () {
    late MockAuthRepository mockRepository;
    late SignOutUseCase useCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignOutUseCase(mockRepository);
    });

    test('should call signOut on repository', () async {
      when(() => mockRepository.signOut()).thenAnswer((_) async => null);

      final result = await useCase.call();

      expect(result, isNull);
      verify(() => mockRepository.signOut()).called(1);
    });
  });

  group('SignUpWithEmailUseCase', () {
    late MockAuthRepository mockRepository;
    late SignUpWithEmailUseCase useCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = SignUpWithEmailUseCase(mockRepository);
    });

    test('should return user when registration is successful', () async {
      final expectedUser = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => (user: expectedUser, failure: null));

      final result = await useCase.call(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );

      expect(result.user, expectedUser);
      expect(result.failure, isNull);
      expect(result.user?.email, 'test@example.com');
      expect(result.user?.displayName, 'Test User');
    });

    test('should return failure when email already exists', () async {
      when(() => mockRepository.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          )).thenAnswer((_) async => (user: null, failure: Failure.auth('Email already exists')));

      final result = await useCase.call(
        email: 'existing@example.com',
        password: 'password123',
        name: 'Test User',
      );

      expect(result.user, isNull);
      expect(result.failure, isNotNull);
    });
  });

  group('GetCurrentUserUseCase', () {
    late MockAuthRepository mockRepository;
    late GetCurrentUserUseCase useCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = GetCurrentUserUseCase(mockRepository);
    });

    test('should return user when logged in', () async {
      final expectedUser = UserModel(
        id: 'user_123',
        email: 'test@example.com',
        displayName: 'Test User',
        lastModifiedAt: DateTime.now().millisecondsSinceEpoch,
      );

      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => expectedUser);

      final result = await useCase.call();

      expect(result, expectedUser);
    });

    test('should return null when not logged in', () async {
      when(() => mockRepository.getCurrentUser())
          .thenAnswer((_) async => null);

      final result = await useCase.call();

      expect(result, isNull);
    });
  });

  group('IsLoggedInUseCase', () {
    late MockAuthRepository mockRepository;
    late IsLoggedInUseCase useCase;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = IsLoggedInUseCase(mockRepository);
    });

    test('should return true when logged in', () async {
      when(() => mockRepository.isLoggedIn())
          .thenAnswer((_) async => true);

      final result = await useCase.call();

      expect(result, true);
    });

    test('should return false when not logged in', () async {
      when(() => mockRepository.isLoggedIn())
          .thenAnswer((_) async => false);

      final result = await useCase.call();

      expect(result, false);
    });
  });
}
