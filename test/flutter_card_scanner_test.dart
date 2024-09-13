import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_card_scanner/flutter_card_scanner.dart';
import 'package:flutter_card_scanner/flutter_card_scanner_platform_interface.dart';
import 'package:flutter_card_scanner/flutter_card_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterCardScannerPlatform
    with MockPlatformInterfaceMixin
    implements FlutterCardScannerPlatform {
  @override
  Future getPreviewHeight() async {
    return 1080;
  }

  @override
  Future getPreviewWidth() async {
    return 1920;
  }

  @override
  Future<int?> startCamera() async {
    return 1;
  }

  @override
  Future<void> startScanning() async {}

  @override
  Future<void> stopScanning() async {}

  @override
  Future<void> stopCamera() async {}

  @override
  Future<void> resetCamera() async {}
}

void main() {
  final FlutterCardScannerPlatform initialPlatform =
      FlutterCardScannerPlatform.instance;

  test('$MethodChannelFlutterCardScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterCardScanner>());
  });

  test('getPlatformVersion', () async {
    FlutterCardScanner flutterCardScannerPlugin = FlutterCardScanner();
    MockFlutterCardScannerPlatform fakePlatform =
        MockFlutterCardScannerPlatform();
    FlutterCardScannerPlatform.instance = fakePlatform;

    expect(await flutterCardScannerPlugin.startCamera(), 1);
  });
}
