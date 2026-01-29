import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkInfo {
  static NetworkInfo? _instance;
  final Connectivity _connectivity;

  NetworkInfo._() : _connectivity = Connectivity();

  factory NetworkInfo() {
    _instance ??= NetworkInfo._();
    return _instance!;
  }

  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  Future<bool> get isWifi async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.wifi);
  }

  Future<bool> get isMobile async {
    final results = await _connectivity.checkConnectivity();
    return results.contains(ConnectivityResult.mobile);
  }

  Future<List<ConnectivityResult>> get connectivityResult async {
    return await _connectivity.checkConnectivity();
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }

  Future<bool> canSync({bool wifiOnly = false}) async {
    final connected = await isConnected;
    if (!connected) return false;
    
    if (wifiOnly) {
      return await isWifi;
    }
    
    return true;
  }
}
