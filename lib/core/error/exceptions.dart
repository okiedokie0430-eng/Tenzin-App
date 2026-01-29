class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message${code != null ? ' (code: $code)' : ''}';
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class SyncException extends AppException {
  const SyncException(super.message, {super.code, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

class StorageException extends AppException {
  const StorageException(super.message, {super.code, super.originalError});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}

class HeartException extends AppException {
  const HeartException(super.message, {super.code, super.originalError});
}

class LessonException extends AppException {
  const LessonException(super.message, {super.code, super.originalError});
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.originalError});
}
