import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_card_scanner_method_channel.dart';

abstract class FlutterCardScannerPlatform extends PlatformInterface {
  /// Constructs a FlutterCardScannerPlatform.
  FlutterCardScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterCardScannerPlatform _instance =
      MethodChannelFlutterCardScanner();

  /// The default instance of [FlutterCardScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterCardScanner].
  static FlutterCardScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterCardScannerPlatform] when
  /// they register themselves.
  static set instance(FlutterCardScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<int?> startCamera() {
    throw UnimplementedError('startCamera() has not been implemented.');
  }

  Future<void> stopCamera() {
    throw UnimplementedError('stopCamera() has not been implemented.');
  }

  Future<void> startScanning() {
    throw UnimplementedError('startScanning() has not been implemented.');
  }

  Future<void> stopScanning() {
    throw UnimplementedError('stopScanning() has not been implemented.');
  }

  Future<dynamic> getPreviewWidth() {
    throw UnimplementedError('getPreviewWidth() has not been implemented.');
  }

  Future<dynamic> getPreviewHeight() {
    throw UnimplementedError('getPreviewHeight() has not been implemented.');
  }
}
