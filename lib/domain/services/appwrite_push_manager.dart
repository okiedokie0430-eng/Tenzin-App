import 'dart:convert';
import 'dart:developer' as developer;
// import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/remote/appwrite_client.dart';
import 'package:appwrite/appwrite.dart' hide Permission;
import 'package:http/http.dart' as http;

/// AppwritePushManager
///
/// Automates: request permission, get FCM token, create Appwrite push target,
/// store pushTargetId locally, and subscribe to topic "global-updates".
/// Uses placeholders for Appwrite credentials.
class AppwritePushManager {
  AppwritePushManager._();
  static final AppwritePushManager instance = AppwritePushManager._();

  // Replace these placeholders with real values or inject via runtime config
  static const String appwriteEndpoint = 'https://sgp.cloud.appwrite.io/v1';
  static const String projectId = '69536e3f003c0ac930bd';
  static const String apiKey = 'standard_8f459dac146c7636ee92a3610600a5c695ad1a722e3e6476a935391b26ece18b0ce20cbf023116e33bca8a27ebb5ad1829f76c9567203a30206024ece07fb41d91b420a329e001d7392149c281d57574449fa8f633eca6216d7644c97113372dfa00d2d0133af154e73e0962c6e9c910025fdbdac574a631bcf172e73b0ac539';
  static const String topicId = 'global-updates';
  static const String pushTargetsCollection = 'push_targets';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _storageKeyPushTargetId = 'appwrite_push_target_id';
  static const String _storageKeyFcmToken = 'fcm_token_store';
  static const String _storageKeyPushSupported = 'appwrite_push_supported';
  bool _tokenRefreshListenerAttached = false;
  bool _pushSupported = true;
  String? _lastCreateResponse;
  String? _lastFindResponse;
  String? _lastSubscribeResponse;
  String? _lastFallbackSubscribeResponse;
  String? _lastStoreResponse;

  Future<void> ensurePushTargetAndSubscribe() async {
    try {
      final permissionGranted = await _requestNotificationPermission();
      developer.log('Permission status: $permissionGranted', name: 'AppwritePush');

      if (!permissionGranted) {
        developer.log('Notifications permission not granted. Aborting push setup.', name: 'AppwritePush');
        return;
      }

      final fcmToken = await _getFcmToken();
      developer.log('FCM token: $fcmToken', name: 'AppwritePush');
      if (fcmToken == null || fcmToken.isEmpty) {
        developer.log('FCM token unavailable.', name: 'AppwritePush');
        return;
      }

      // Save token locally for potential reconciliation
      await _secureStorage.write(key: _storageKeyFcmToken, value: fcmToken);

      // If we previously detected push API is unsupported, skip API attempts and use DB fallback
      final storedSupported = await _secureStorage.read(key: _storageKeyPushSupported);
      if (storedSupported == 'false') {
        developer.log('Appwrite Push previously detected as unsupported - using DB fallback.', name: 'AppwritePush');
        await _storeTokenInAppwriteDb(fcmToken);
        return;
      }

      // Attach token refresh listener once so we can handle token rotation
      if (!_tokenRefreshListenerAttached) {
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          developer.log('FCM token refreshed: $newToken', name: 'AppwritePush');
          await _handleTokenRefresh(newToken);
        });
        _tokenRefreshListenerAttached = true;
      }

      // Idempotency: check if we already have pushTargetId stored
      var pushTargetId = await _secureStorage.read(key: _storageKeyPushTargetId);
      if (pushTargetId != null && pushTargetId.isNotEmpty) {
        developer.log('Found existing pushTargetId: $pushTargetId', name: 'AppwritePush');

        // Try subscribe to topic (in case not subscribed yet)
        final subscribed = await _subscribePushTargetToTopic(pushTargetId);
        if (subscribed) {
          developer.log('Successfully ensured subscription for existing target.', name: 'AppwritePush');
          return;
        }

        developer.log('Existing push target subscription failed, attempting to recreate target.', name: 'AppwritePush');
        // If subscription failed, continue to create a fresh target
      }

      // Optionally try to find existing target by identifier
      final foundId = await _findPushTargetIdByIdentifier(fcmToken);
      if (foundId != null) {
        developer.log('Found push target by identifier: $foundId', name: 'AppwritePush');
        await _secureStorage.write(key: _storageKeyPushTargetId, value: foundId);
        final subscribed = await _subscribePushTargetToTopic(foundId);
        if (subscribed) {
          developer.log('Subscribed found target to topic.', name: 'AppwritePush');
          return;
        }
      }

      // Create push target
      final createdId = await _createPushTarget(fcmToken);
      if (createdId != null) {
        developer.log('Created push target id: $createdId', name: 'AppwritePush');
        await _secureStorage.write(key: _storageKeyPushTargetId, value: createdId);

        final subscribed = await _subscribePushTargetToTopic(createdId);
        if (subscribed) {
          developer.log('Successfully subscribed new push target to topic.', name: 'AppwritePush');
          return;
        }

        developer.log('Failed to subscribe new push target to topic.', name: 'AppwritePush');
      } else {
        developer.log('Failed to create push target.', name: 'AppwritePush');
        // Fallback: store token in Appwrite database so a local worker can send notifications
        await _storeTokenInAppwriteDb(fcmToken);
      }
    } catch (e, st) {
      developer.log('Unexpected error in ensurePushTargetAndSubscribe: $e', name: 'AppwritePush', error: e, stackTrace: st);
    }
  }

  // Handle FCM token refresh by ensuring a push target exists for the new token
  Future<void> _handleTokenRefresh(String newToken) async {
    try {
      if (newToken.isEmpty) return;

      await _secureStorage.write(key: _storageKeyFcmToken, value: newToken);

      // Try to find existing push target by identifier
      final foundId = await _findPushTargetIdByIdentifier(newToken);
      if (foundId != null) {
        developer.log('Found push target for refreshed token: $foundId', name: 'AppwritePush');
        await _secureStorage.write(key: _storageKeyPushTargetId, value: foundId);
        await _subscribePushTargetToTopic(foundId);
        // ensure DB record updated with latest mapping
        await _upsertPushTargetRecordInDb(newToken, pushTargetId: foundId);
        return;
      }

      // Create new push target for refreshed token
      final createdId = await _createPushTarget(newToken);
      if (createdId != null) {
        developer.log('Created push target for refreshed token: $createdId', name: 'AppwritePush');
        await _secureStorage.write(key: _storageKeyPushTargetId, value: createdId);
        await _subscribePushTargetToTopic(createdId);
        await _upsertPushTargetRecordInDb(newToken, pushTargetId: createdId);
      }
      else {
        await _storeTokenInAppwriteDb(newToken);
      }
    } catch (e, st) {
      developer.log('Error handling token refresh: $e', name: 'AppwritePush', error: e, stackTrace: st);
    }
  }

  // Fallback: save token in Appwrite Databases collection 'push_tokens'
  Future<void> _storeTokenInAppwriteDb(String token) async {
    try {
      final appwrite = AppwriteClient();
      final user = await appwrite.getCurrentUser();
      final userId = user?.$id ?? '';

      final data = {
        'user_id': userId,
        'token': token,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };

      await appwrite.databases.createDocument(
        databaseId: AppwriteClient.databaseId,
        collectionId: 'push_tokens', // create this collection in your Appwrite console
        documentId: ID.unique(),
        data: data,
      );
      _lastStoreResponse = '201 stored';
      developer.log('Stored FCM token in Appwrite DB push_tokens', name: 'AppwritePush');
      // Also upsert a push_targets record for integrity/reference
      await _upsertPushTargetRecordInDb(token, pushTargetId: null);
    } catch (e) {
      _lastStoreResponse = 'error: $e';
      developer.log('Failed to store FCM token in Appwrite DB: $e', name: 'AppwritePush');
    }
  }

  // Store authoritative push-target metadata in Appwrite Databases for integrity.
  // Uses documentId = userId so each user has at most one record.
  Future<void> _upsertPushTargetRecordInDb(String fcmToken, {String? pushTargetId}) async {
    try {
      final appwrite = AppwriteClient();
      final user = await appwrite.getCurrentUser();
      final userId = user?.$id ?? '';
      final data = {
        'user_id': userId,
        'fcm_token': fcmToken,
        'push_target_id': pushTargetId ?? '',
        'provider': 'fcm',
        'topics': [topicId],
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (userId.isNotEmpty) {
        try {
          // Try update existing document with documentId = userId
          await appwrite.databases.updateDocument(
            databaseId: AppwriteClient.databaseId,
            collectionId: pushTargetsCollection,
            documentId: userId,
            data: data,
          );
          developer.log('Updated push_targets record for user $userId', name: 'AppwritePush');
        } catch (e) {
          // If update fails (e.g., document not found), create it with userId
          try {
            await appwrite.databases.createDocument(
              databaseId: AppwriteClient.databaseId,
              collectionId: pushTargetsCollection,
              documentId: userId,
              data: data,
            );
            developer.log('Created push_targets record for user $userId', name: 'AppwritePush');
          } catch (ce) {
            developer.log('Failed to create push_targets record: $ce', name: 'AppwritePush');
          }
        }
      } else {
        // If no logged-in user, create an anonymous record (use unique id)
        try {
          await appwrite.databases.createDocument(
            databaseId: AppwriteClient.databaseId,
            collectionId: pushTargetsCollection,
            documentId: ID.unique(),
            data: data,
          );
          developer.log('Created anonymous push_targets record', name: 'AppwritePush');
        } catch (e) {
          developer.log('Failed to create anonymous push_targets record: $e', name: 'AppwritePush');
        }
      }
    } catch (e) {
      developer.log('Error upserting push target record in DB: $e', name: 'AppwritePush');
    }
  }

  Future<void> _markPushUnsupported() async {
    try {
      _pushSupported = false;
      await _secureStorage.write(key: _storageKeyPushSupported, value: 'false');
      developer.log('Marked Appwrite Push as unsupported (will use DB fallback).', name: 'AppwritePush');
    } catch (e) {
      developer.log('Failed to persist push unsupported flag: $e', name: 'AppwritePush');
    }
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      // On iOS and Android (13+) we should request permission explicitly
      // Request via Firebase for iOS (sound/badge/alert)
      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        return true;
      }

      // Additionally, request the runtime permission on Android (POST_NOTIFICATIONS)
      try {
        final status = await Permission.notification.request();
        return status == PermissionStatus.granted;
      } catch (e) {
        // If permission_handler isn't available on the platform, fallback to Firebase result
        developer.log('permission_handler request failed: $e', name: 'AppwritePush');
        return false;
      }
    } on PlatformException catch (e) {
      developer.log('PlatformException while requesting permission: $e', name: 'AppwritePush');
      return false;
    } catch (e) {
      developer.log('Error requesting notifications permission: $e', name: 'AppwritePush');
      return false;
    }
  }

  Future<String?> _getFcmToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      return token;
    } catch (e) {
      developer.log('Failed to get FCM token: $e', name: 'AppwritePush');
      return null;
    }
  }

  Future<String?> _createPushTarget(String fcmToken) async {
    // Strategy: try Appwrite SDK Account endpoint via internal client (keeps session/cookies),
    // then try account HTTP endpoint, then fall back to project endpoint (older server versions).
    final bodyMap = {'providerId': 'fcm', 'identifier': fcmToken};
    final body = jsonEncode(bodyMap);

    try {
      final appwrite = AppwriteClient();
      // Try using the internal Appwrite SDK client.call if available (dynamic to avoid compile issues)
      try {
        final client = appwrite.client as dynamic;
        final res = await client.call('post', '/v1/account/targets', headers: {'content-type': 'application/json'}, params: body);
        _lastCreateResponse = 'sdk ${res?.toString() ?? '<no-response>'}';
        developer.log('SDK create push target response: $_lastCreateResponse', name: 'AppwritePush');
        try {
          final decoded = res is String ? jsonDecode(res) : (res as Object?);
          if (decoded is Map<String, dynamic>) {
            final id = decoded['\$id'] ?? decoded['id'];
            return id?.toString();
          }
        } catch (_) {}
      } catch (e) {
        developer.log('SDK account create attempt failed: $e', name: 'AppwritePush');
      }

      // Try HTTP account endpoint (may require session cookies, but attempt anyway)
      try {
        final accountUri = Uri.parse('$appwriteEndpoint/v1/account/targets');
        final resp = await http.post(
          accountUri,
          headers: {
            'Content-Type': 'application/json',
            'X-Appwrite-Project': projectId,
            'X-Appwrite-Key': apiKey,
          },
          body: body,
        );
        _lastCreateResponse = '${resp.statusCode} ${resp.body}';
        developer.log('Account create push target response: $_lastCreateResponse', name: 'AppwritePush');
        if (resp.statusCode == 404) {
          await _markPushUnsupported();
          return null;
        }
        if (resp.statusCode == 200 || resp.statusCode == 201) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final id = data['\$id'] ?? data['id'];
          return id?.toString();
        }
      } catch (e) {
        developer.log('HTTP account create attempt failed: $e', name: 'AppwritePush');
      }

      // Fallback: try project-scoped endpoint (older/server admin style)
      final uri = Uri.parse('$appwriteEndpoint/v1/projects/$projectId/push/targets');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        },
        body: body,
      );

      _lastCreateResponse = '${response.statusCode} ${response.body}';
      developer.log('Create push target response (projects fallback): $_lastCreateResponse', name: 'AppwritePush');

      if (response.statusCode == 404) {
        await _markPushUnsupported();
        return null;
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final id = data['\$id'] ?? data['id'];
        return id?.toString();
      }

      return null;
    } catch (e) {
      developer.log('Error creating push target: $e', name: 'AppwritePush');
      return null;
    }
  }

  Future<bool> _subscribePushTargetToTopic(String pushTargetId) async {
    try {
      final appwrite = AppwriteClient();
      // Try SDK account route first
      try {
        final client = appwrite.client as dynamic;
        final res = await client.call('put', '/v1/account/targets/$pushTargetId/topics/$topicId', headers: {'content-type': 'application/json'});
        _lastSubscribeResponse = 'sdk ${res?.toString() ?? '<no-response>'}';
        developer.log('SDK subscribe response: $_lastSubscribeResponse', name: 'AppwritePush');
        return true;
      } catch (e) {
        developer.log('SDK account subscribe attempt failed: $e', name: 'AppwritePush');
      }

      // Try HTTP account endpoint
      try {
        final accountUri = Uri.parse('$appwriteEndpoint/v1/account/targets/$pushTargetId/topics/$topicId');
        final resp = await http.put(
          accountUri,
          headers: {
            'Content-Type': 'application/json',
            'X-Appwrite-Project': projectId,
            'X-Appwrite-Key': apiKey,
          },
        );
        _lastSubscribeResponse = '${resp.statusCode} ${resp.body}';
        developer.log('Account subscribe response: $_lastSubscribeResponse', name: 'AppwritePush');
        if (resp.statusCode == 404) {
          await _markPushUnsupported();
          return false;
        }
        if (resp.statusCode == 200 || resp.statusCode == 201 || resp.statusCode == 204) return true;
      } catch (e) {
        developer.log('HTTP account subscribe failed: $e', name: 'AppwritePush');
      }

      // Fallback to project endpoints (older/server admin)
      final uri = Uri.parse('$appwriteEndpoint/v1/projects/$projectId/push/targets/$pushTargetId/topics/$topicId');
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        },
      );
      _lastSubscribeResponse = '${response.statusCode} ${response.body}';
      developer.log('Subscribe response (projects fallback): $_lastSubscribeResponse', name: 'AppwritePush');
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) return true;

      // Try POST subscriptions endpoint as last resort
      try {
        final fallbackUri = Uri.parse('$appwriteEndpoint/v1/projects/$projectId/push/targets/$pushTargetId/subscriptions');
        final postResp = await http.post(
          fallbackUri,
          headers: {
            'Content-Type': 'application/json',
            'X-Appwrite-Project': projectId,
            'X-Appwrite-Key': apiKey,
          },
          body: jsonEncode({'topicId': topicId}),
        );
        _lastFallbackSubscribeResponse = '${postResp.statusCode} ${postResp.body}';
        developer.log('Fallback subscribe response: $_lastFallbackSubscribeResponse', name: 'AppwritePush');
        return (postResp.statusCode == 200 || postResp.statusCode == 201 || postResp.statusCode == 204);
      } catch (e) {
        developer.log('Fallback post subscribe failed: $e', name: 'AppwritePush');
      }

      return false;
    } catch (e) {
      developer.log('Error subscribing push target: $e', name: 'AppwritePush');
      return false;
    }
  }

  Future<String?> _findPushTargetIdByIdentifier(String identifier) async {
    try {
      final appwrite = AppwriteClient();
      // Try SDK account search
      try {
        final client = appwrite.client as dynamic;
        final res = await client.call('get', '/v1/account/targets?search=$identifier', headers: {'content-type': 'application/json'});
        _lastFindResponse = 'sdk ${res?.toString() ?? '<no-response>'}';
        developer.log('SDK find push target response: $_lastFindResponse', name: 'AppwritePush');
        try {
          final decoded = res is String ? jsonDecode(res) : (res as Object?);
          if (decoded is Map<String, dynamic>) {
            final items = decoded['targets'] ?? decoded['data'] ?? decoded['items'];
            if (items is List && items.isNotEmpty) {
              final first = items.first as Map<String, dynamic>;
              final id = first['\$id'] ?? first['id'];
              return id?.toString();
            }
          }
        } catch (_) {}
      } catch (e) {
        developer.log('SDK account find attempt failed: $e', name: 'AppwritePush');
      }

      // Try HTTP account endpoint
      try {
        final accountUri = Uri.parse('$appwriteEndpoint/v1/account/targets?search=$identifier');
        final resp = await http.get(
          accountUri,
          headers: {
            'Content-Type': 'application/json',
            'X-Appwrite-Project': projectId,
            'X-Appwrite-Key': apiKey,
          },
        );
        developer.log('Find push target response: ${resp.statusCode} ${resp.body}', name: 'AppwritePush');
        _lastFindResponse = '${resp.statusCode} ${resp.body}';
        if (resp.statusCode == 404) {
          await _markPushUnsupported();
          return null;
        }
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final items = data['targets'] ?? data['data'] ?? data['items'];
          if (items is List && items.isNotEmpty) {
            final first = items.first as Map<String, dynamic>;
            final id = first['\$id'] ?? first['id'];
            return id?.toString();
          }
        }
      } catch (e) {
        developer.log('HTTP account find attempt failed: $e', name: 'AppwritePush');
      }

      // Fallback to project endpoint
      final uri = Uri.parse('$appwriteEndpoint/v1/projects/$projectId/push/targets?search=$identifier');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        },
      );

      developer.log('Find push target response (projects fallback): ${response.statusCode} ${response.body}', name: 'AppwritePush');
      _lastFindResponse = '${response.statusCode} ${response.body}';
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['targets'] ?? data['data'] ?? data['items'];
        if (items is List && items.isNotEmpty) {
          final first = items.first as Map<String, dynamic>;
          final id = first['\$id'] ?? first['id'];
          return id?.toString();
        }
      }

      return null;
    } catch (e) {
      developer.log('Error finding push target: $e', name: 'AppwritePush');
      return null;
    }
  }

  /// Debug helper: return stored pushTargetId and FCM token (may be null)
  Future<Map<String, String?>> getPushSetupInfo() async {
    try {
      final pushTargetId = await _secureStorage.read(key: _storageKeyPushTargetId);
      final fcmToken = await _secureStorage.read(key: _storageKeyFcmToken);
      final storedSupported = await _secureStorage.read(key: _storageKeyPushSupported);
      final pushSupportedStr = (storedSupported == null) ? (_pushSupported ? 'true' : 'false') : storedSupported;
      developer.log('getPushSetupInfo -> pushTargetId: $pushTargetId, fcmToken: ${fcmToken != null ? "${fcmToken.substring(0, 8)}..." : null}, pushSupported: $pushSupportedStr', name: 'AppwritePush');
      return {
        'pushTargetId': pushTargetId,
        'fcmToken': fcmToken,
      };
    } catch (e) {
      developer.log('Error reading push setup info: $e', name: 'AppwritePush');
      return {'pushTargetId': null, 'fcmToken': null};
    }
  }

  /// Debug helper: return last HTTP responses for quick inspection
  Future<Map<String, String?>> getDebugInfo() async {
    return {
      'pushSupported': (_pushSupported ? 'true' : (await _secureStorage.read(key: _storageKeyPushSupported)) ?? 'unknown'),
      'lastFind': _lastFindResponse,
      'lastCreate': _lastCreateResponse,
      'lastSubscribe': _lastSubscribeResponse,
      'lastFallbackSubscribe': _lastFallbackSubscribeResponse,
      'lastStore': _lastStoreResponse,
    };
  }
}
