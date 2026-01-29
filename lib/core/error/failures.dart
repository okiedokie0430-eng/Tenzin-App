import '../constants/strings.dart';

enum FailureType {
  auth,
  network,
  database,
  sync,
  validation,
  storage,
  permission,
  heart,
  lesson,
  unknown,
}

class Failure {
  final String message;
  final FailureType type;
  final String? code;

  const Failure({
    required this.message,
    required this.type,
    this.code,
  });

  factory Failure.auth([String? message]) => Failure(
        message: message ?? AppStrings.errorAuth,
        type: FailureType.auth,
      );

  factory Failure.network([String? message]) => Failure(
        message: message ?? AppStrings.errorNetwork,
        type: FailureType.network,
      );

  factory Failure.database([String? message]) => Failure(
        message: message ?? AppStrings.errorLoadingData,
        type: FailureType.database,
      );

  factory Failure.sync([String? message]) => Failure(
        message: message ?? 'Синк хийхэд алдаа гарлаа',
        type: FailureType.sync,
      );

  factory Failure.validation([String? message]) => Failure(
        message: message ?? 'Буруу мэдээлэл',
        type: FailureType.validation,
      );

  factory Failure.storage([String? message]) => Failure(
        message: message ?? AppStrings.errorSaving,
        type: FailureType.storage,
      );

  factory Failure.permission([String? message]) => Failure(
        message: message ?? AppStrings.permissionRequired,
        type: FailureType.permission,
      );

  factory Failure.heart([String? message]) => Failure(
        message: message ?? AppStrings.heartsEmpty,
        type: FailureType.heart,
      );

  factory Failure.lesson([String? message]) => Failure(
        message: message ?? 'Хичээл ачаалахад алдаа гарлаа',
        type: FailureType.lesson,
      );

  factory Failure.unknown([String? message]) => Failure(
        message: message ?? AppStrings.errorGeneric,
        type: FailureType.unknown,
      );

  @override
  String toString() => 'Failure: $message (type: ${type.name})';
}
