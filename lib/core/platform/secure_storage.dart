import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  static SecureStorageService? _instance;
  late final FlutterSecureStorage _storage;

  SecureStorageService._() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
  }

  factory SecureStorageService() {
    _instance ??= SecureStorageService._();
    return _instance!;
  }

  // Auth Token
  Future<void> setAuthToken(String token) async {
    await _storage.write(key: AppConstants.keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: AppConstants.keyAuthToken);
  }

  Future<void> deleteAuthToken() async {
    await _storage.delete(key: AppConstants.keyAuthToken);
  }

  // User ID
  Future<void> setUserId(String userId) async {
    await _storage.write(key: AppConstants.keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: AppConstants.keyUserId);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: AppConstants.keyUserId);
  }

  // Session ID
  Future<void> setSessionId(String sessionId) async {
    await _storage.write(key: AppConstants.keySessionId, value: sessionId);
  }

  Future<String?> getSessionId() async {
    return await _storage.read(key: AppConstants.keySessionId);
  }

  Future<void> deleteSessionId() async {
    await _storage.delete(key: AppConstants.keySessionId);
  }

  // Last Sync At
  Future<void> setLastSyncAt(DateTime dateTime) async {
    await _storage.write(
      key: AppConstants.keyLastSyncAt,
      value: dateTime.toIso8601String(),
    );
  }

  Future<DateTime?> getLastSyncAt() async {
    final value = await _storage.read(key: AppConstants.keyLastSyncAt);
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  // Generic methods
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  // Clear all auth data
  Future<void> clearAuthData() async {
    await deleteAuthToken();
    await deleteUserId();
    await deleteSessionId();
  }
}
