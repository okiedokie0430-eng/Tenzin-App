import 'dart:io';
import 'dart:typed_data';
import '../remote/storage_remote.dart';
import '../../core/platform/network_info.dart';
import '../../core/error/failures.dart';
import '../../core/utils/logger.dart';

class StorageRepository {
  final StorageRemote _storageRemote;
  final NetworkInfo _networkInfo;

  StorageRepository(this._storageRemote, this._networkInfo);

  Future<({String? url, Failure? failure})> uploadProfileImage(
    String userId,
    File imageFile,
  ) async {
    try {
      if (!await _networkInfo.isConnected) {
        return (url: null, failure: Failure.network());
      }

      final url = await _storageRemote.uploadProfileImage(userId, imageFile);
      return (url: url, failure: null);
    } catch (e) {
      AppLogger.logError('StorageRepository', 'uploadProfileImage', e);
      return (url: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({String? url, Failure? failure})> uploadProfileImageBytes(
    String userId,
    Uint8List imageBytes,
  ) async {
    try {
      if (!await _networkInfo.isConnected) {
        return (url: null, failure: Failure.network());
      }

      final url = await _storageRemote.uploadProfileImageBytes(userId, imageBytes);
      return (url: url, failure: null);
    } catch (e) {
      AppLogger.logError('StorageRepository', 'uploadProfileImageBytes', e);
      return (url: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<Failure?> deleteProfileImage(String userId) async {
    try {
      if (!await _networkInfo.isConnected) {
        return Failure.network();
      }

      await _storageRemote.deleteProfileImage(userId);
      return null;
    } catch (e) {
      AppLogger.logError('StorageRepository', 'deleteProfileImage', e);
      return Failure.unknown(e.toString());
    }
  }

  Future<({Uint8List? data, Failure? failure})> downloadFile(
    String bucketId,
    String fileId,
  ) async {
    try {
      if (!await _networkInfo.isConnected) {
        return (data: null, failure: Failure.network());
      }

      final data = await _storageRemote.downloadFile(bucketId, fileId);
      return (data: data, failure: null);
    } catch (e) {
      AppLogger.logError('StorageRepository', 'downloadFile', e);
      return (data: null, failure: Failure.unknown(e.toString()));
    }
  }

  Future<({Uint8List? data, Failure? failure})> getFilePreview(
    String bucketId,
    String fileId, {
    int? width,
    int? height,
    int? quality,
  }) async {
    try {
      if (!await _networkInfo.isConnected) {
        return (data: null, failure: Failure.network());
      }

      final data = await _storageRemote.getFilePreview(
        bucketId,
        fileId,
        width: width,
        height: height,
        quality: quality,
      );
      return (data: data, failure: null);
    } catch (e) {
      AppLogger.logError('StorageRepository', 'getFilePreview', e);
      return (data: null, failure: Failure.unknown(e.toString()));
    }
  }

  String getFilePreviewUrl(
    String bucketId,
    String fileId, {
    int? width,
    int? height,
    int? quality,
  }) {
    return _storageRemote.getFilePreviewUrl(
      bucketId,
      fileId,
      width: width,
      height: height,
      quality: quality,
    );
  }

  Future<({String? url, Failure? failure})> uploadAudioFile(
    String lessonId,
    String wordId,
    File audioFile,
  ) async {
    try {
      if (!await _networkInfo.isConnected) {
        return (url: null, failure: Failure.network());
      }

      final url = await _storageRemote.uploadAudioFile(lessonId, wordId, audioFile);
      return (url: url, failure: null);
    } catch (e) {
      AppLogger.logError('StorageRepository', 'uploadAudioFile', e);
      return (url: null, failure: Failure.unknown(e.toString()));
    }
  }
}
