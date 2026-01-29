import '../../data/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/error/failures.dart';

class SignInWithEmailUseCase {
  final AuthRepository _repository;

  SignInWithEmailUseCase(this._repository);

  Future<({UserModel? user, Failure? failure})> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithEmail(email: email, password: password);
  }
}

class SignUpWithEmailUseCase {
  final AuthRepository _repository;

  SignUpWithEmailUseCase(this._repository);

  Future<({UserModel? user, Failure? failure})> call({
    required String email,
    required String password,
    required String name,
  }) {
    return _repository.signUpWithEmail(
      email: email,
      password: password,
      name: name,
    );
  }
}

class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  Future<({UserModel? user, Failure? failure})> call() {
    return _repository.signInWithGoogle();
  }
}

class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<Failure?> call() {
    return _repository.signOut();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  Future<UserModel?> call() {
    return _repository.getCurrentUser();
  }
}

class IsLoggedInUseCase {
  final AuthRepository _repository;

  IsLoggedInUseCase(this._repository);

  Future<bool> call() {
    return _repository.isLoggedIn();
  }
}

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<({UserModel? user, Failure? failure})> call(UserModel user) {
    return _repository.updateProfile(user);
  }
}

class SendPasswordResetEmailUseCase {
  final AuthRepository _repository;

  SendPasswordResetEmailUseCase(this._repository);

  Future<Failure?> call(String email) {
    return _repository.sendPasswordResetEmail(email);
  }
}

class UpdatePasswordUseCase {
  final AuthRepository _repository;

  UpdatePasswordUseCase(this._repository);

  Future<Failure?> call({
    required String oldPassword,
    required String newPassword,
  }) {
    return _repository.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}

class DeleteAccountUseCase {
  final AuthRepository _repository;

  DeleteAccountUseCase(this._repository);

  Future<Failure?> call() {
    return _repository.deleteAccount();
  }
}
