import 'dart:io';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'appwrite_client.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

class StorageRemote {
  final AppwriteClient _appwriteClient;

  StorageRemote(this._appwriteClient);

  Storage get _storage => _appwriteClient.storage;

  Future<String> uploadProfileImage(
    String userId,
    File imageFile,
  ) async {
    try {
      final fileName = 'profile_$userId.jpg';
      
      final response = await _storage.createFile(
        bucketId: AppwriteClient.profileImagesBucket,
        fileId: userId,
        file: InputFile.fromPath(
          path: imageFile.path,
          filename: fileName,
        ),
      );

      return getFilePreviewUrl(
        AppwriteClient.profileImagesBucket,
        response.$id,
      );
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // File exists, update it
        await _storage.deleteFile(
          bucketId: AppwriteClient.profileImagesBucket,
          fileId: userId,
        );
        return uploadProfileImage(userId, imageFile);
      }
      AppLogger.logError('StorageRemote', 'uploadProfileImage', e);
      throw ServerException(e.message ?? 'Failed to upload profile image');
    }
  }

  Future<String> uploadProfileImageBytes(
    String userId,
    Uint8List imageBytes,
  ) async {
    try {
      final fileName = 'profile_$userId.jpg';
      
      final response = await _storage.createFile(
        bucketId: AppwriteClient.profileImagesBucket,
        fileId: userId,
        file: InputFile.fromBytes(
          bytes: imageBytes,
          filename: fileName,
        ),
      );

      return getFilePreviewUrl(
        AppwriteClient.profileImagesBucket,
        response.$id,
      );
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        await _storage.deleteFile(
          bucketId: AppwriteClient.profileImagesBucket,
          fileId: userId,
        );
        return uploadProfileImageBytes(userId, imageBytes);
      }
      AppLogger.logError('StorageRemote', 'uploadProfileImageBytes', e);
      throw ServerException(e.message ?? 'Failed to upload profile image');
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      await _storage.deleteFile(
        bucketId: AppwriteClient.profileImagesBucket,
        fileId: userId,
      );
    } on AppwriteException catch (e) {
      if (e.code == 404) return; // Already deleted
      AppLogger.logError('StorageRemote', 'deleteProfileImage', e);
      throw ServerException(e.message ?? 'Failed to delete profile image');
    }
  }

  Future<Uint8List> downloadFile(
    String bucketId,
    String fileId,
  ) async {
    try {
      return await _storage.getFileDownload(
        bucketId: bucketId,
        fileId: fileId,
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('StorageRemote', 'downloadFile', e);
      throw ServerException(e.message ?? 'Failed to download file');
    }
  }

  Future<Uint8List> getFilePreview(
    String bucketId,
    String fileId, {
    int? width,
    int? height,
    int? quality,
  }) async {
    try {
      return await _storage.getFilePreview(
        bucketId: bucketId,
        fileId: fileId,
        width: width,
        height: height,
        quality: quality ?? 80,
      );
    } on AppwriteException catch (e) {
      AppLogger.logError('StorageRemote', 'getFilePreview', e);
      throw ServerException(e.message ?? 'Failed to get file preview');
    }
  }

  String getFilePreviewUrl(
    String bucketId,
    String fileId, {
    int? width,
    int? height,
    int? quality,
  }) {
    final endpoint = _appwriteClient.client.endPoint;
    final projectId = _appwriteClient.client.config['project'];
    
    var url = '$endpoint/storage/buckets/$bucketId/files/$fileId/preview?project=$projectId';
    
    if (width != null) url += '&width=$width';
    if (height != null) url += '&height=$height';
    if (quality != null) url += '&quality=$quality';
    
    return url;
  }

  String getFileViewUrl(String bucketId, String fileId) {
    final endpoint = _appwriteClient.client.endPoint;
    final projectId = _appwriteClient.client.config['project'];
    
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/view?project=$projectId';
  }

  String getFileDownloadUrl(String bucketId, String fileId) {
    final endpoint = _appwriteClient.client.endPoint;
    final projectId = _appwriteClient.client.config['project'];
    
    return '$endpoint/storage/buckets/$bucketId/files/$fileId/download?project=$projectId';
  }

  Future<bool> fileExists(String bucketId, String fileId) async {
    try {
      await _storage.getFile(
        bucketId: bucketId,
        fileId: fileId,
      );
      return true;
    } on AppwriteException catch (e) {
      if (e.code == 404) return false;
      rethrow;
    }
  }

  Future<String> uploadAudioFile(
    String lessonId,
    String wordId,
    File audioFile,
  ) async {
    try {
      final fileId = '${lessonId}_$wordId';
      final fileName = 'audio_${lessonId}_$wordId.mp3';
      
      final response = await _storage.createFile(
        bucketId: AppwriteClient.audioBucket,
        fileId: fileId,
        file: InputFile.fromPath(
          path: audioFile.path,
          filename: fileName,
        ),
      );

      return getFileViewUrl(
        AppwriteClient.audioBucket,
        response.$id,
      );
    } on AppwriteException catch (e) {
      if (e.code == 409) {
        // File exists, update it
        await _storage.deleteFile(
          bucketId: AppwriteClient.audioBucket,
          fileId: '${lessonId}_$wordId',
        );
        return uploadAudioFile(lessonId, wordId, audioFile);
      }
      AppLogger.logError('StorageRemote', 'uploadAudioFile', e);
      throw ServerException(e.message ?? 'Failed to upload audio file');
    }
  }
}
