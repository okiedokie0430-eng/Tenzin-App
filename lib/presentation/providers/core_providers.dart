import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/remote/appwrite_client.dart';
import '../../data/local/database_helper.dart';
import '../../core/platform/network_info.dart';
import '../../core/platform/secure_storage.dart';

// Core services
final appwriteClientProvider = Provider<AppwriteClient>((ref) {
  return AppwriteClient();
});

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfo();
});

/// Live online/offline state based on connectivity.
/// Note: This checks network *availability* (wifi/mobile) not actual internet reachability.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final networkInfo = ref.watch(networkInfoProvider);
  yield await networkInfo.isConnected;
  yield* networkInfo.onConnectivityChanged.map(
    (results) => results.isNotEmpty && !results.contains(ConnectivityResult.none),
  );
});

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});
