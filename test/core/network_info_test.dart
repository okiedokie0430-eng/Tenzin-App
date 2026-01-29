import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:tenzin/core/platform/network_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const connectivityChannel = MethodChannel('dev.fluttercommunity.plus/connectivity');

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, (call) async {
      // connectivity_plus expects a list of connectivity types.
      // Return WiFi by default for deterministic tests.
      return <String>['wifi'];
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(connectivityChannel, null);
  });

  group('NetworkInfo', () {
    late NetworkInfo networkInfo;

    setUp(() {
      networkInfo = NetworkInfo();
    });

    test('should be a singleton', () {
      final instance1 = NetworkInfo();
      final instance2 = NetworkInfo();

      expect(identical(instance1, instance2), true);
    });

    test('isConnected should return a boolean', () async {
      final result = await networkInfo.isConnected;
      expect(result, isA<bool>());
    });

    test('isWifi should return a boolean', () async {
      final result = await networkInfo.isWifi;
      expect(result, isA<bool>());
    });

    test('isMobile should return a boolean', () async {
      final result = await networkInfo.isMobile;
      expect(result, isA<bool>());
    });

    test('canSync should return a boolean', () async {
      final result = await networkInfo.canSync();
      expect(result, isA<bool>());
    });

    test('canSync with wifiOnly should return a boolean', () async {
      final result = await networkInfo.canSync(wifiOnly: true);
      expect(result, isA<bool>());
    });
  });
}
