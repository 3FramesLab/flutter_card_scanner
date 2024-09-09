// import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_card_scanner_platform_interface.dart';

/// An implementation of [FlutterCardScannerPlatform] that uses method channels.
class MethodChannelFlutterCardScanner extends FlutterCardScannerPlatform {
  /// The method channel used to interact with the native platform.
  // @visibleForTesting
  static const methodChannel = MethodChannel('com.3frames/ocr');

  @override
  Future<int?> startCamera() async {
    final textureId = await methodChannel.invokeMethod<int>('startCamera');
    return textureId;
  }

  @override
  Future<dynamic> getPreviewWidth() async {
    final previewWidth =
        await methodChannel.invokeMethod<dynamic>('getPreviewWidth');
    return previewWidth;
  }

  @override
  Future<dynamic> getPreviewHeight() async {
    final previewHeight =
        await methodChannel.invokeMethod<dynamic>('getPreviewHeight');
    return previewHeight;
  }

  @override
  Future<void> startScanning() async {
    await methodChannel.invokeMethod('startScanning');
  }

  @override
  Future<void> stopScanning() async {
    await methodChannel.invokeMethod('stopScanning');
  }
}
