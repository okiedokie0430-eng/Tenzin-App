import 'dart:io';
import 'dart:typed_data';
import '../../data/repositories/storage_repository.dart';
import '../../core/error/failures.dart';

class UploadProfileImageUseCase {
  final StorageRepository _repository;

  UploadProfileImageUseCase(this._repository);

  Future<({String? url, Failure? failure})> call(
    String userId,
    File imageFile,
  ) {
    return _repository.uploadProfileImage(userId, imageFile);
  }
}

class UploadProfileImageBytesUseCase {
  final StorageRepository _repository;

  UploadProfileImageBytesUseCase(this._repository);

  Future<({String? url, Failure? failure})> call(
    String userId,
    Uint8List imageBytes,
  ) {
    return _repository.uploadProfileImageBytes(userId, imageBytes);
  }
}

class DeleteProfileImageUseCase {
  final StorageRepository _repository;

  DeleteProfileImageUseCase(this._repository);

  Future<Failure?> call(String userId) {
    return _repository.deleteProfileImage(userId);
  }
}

class DownloadFileUseCase {
  final StorageRepository _repository;

  DownloadFileUseCase(this._repository);

  Future<({Uint8List? data, Failure? failure})> call(
    String bucketId,
    String fileId,
  ) {
    return _repository.downloadFile(bucketId, fileId);
  }
}

class GetFilePreviewUseCase {
  final StorageRepository _repository;

  GetFilePreviewUseCase(this._repository);

  Future<({Uint8List? data, Failure? failure})> call(
    String bucketId,
    String fileId, {
    int? width,
    int? height,
    int? quality,
  }) {
    return _repository.getFilePreview(
      bucketId,
      fileId,
      width: width,
      height: height,
      quality: quality,
    );
  }
}

class GetFilePreviewUrlUseCase {
  final StorageRepository _repository;

  GetFilePreviewUrlUseCase(this._repository);

  String call(
    String bucketId,
    String fileId, {
    int? width,
    int? height,
    int? quality,
  }) {
    return _repository.getFilePreviewUrl(
      bucketId,
      fileId,
      width: width,
      height: height,
      quality: quality,
    );
  }
}
