import 'flutter_card_scanner_platform_interface.dart';

class FlutterCardScanner {
  Future<int?> startCamera() {
    return FlutterCardScannerPlatform.instance.startCamera();
  }

  Future<dynamic> getPreviewWidth() {
    return FlutterCardScannerPlatform.instance.getPreviewWidth();
  }

  Future<dynamic> getPreviewHeight() {
    return FlutterCardScannerPlatform.instance.getPreviewHeight();
  }

  Future<void> startScanning() {
    return FlutterCardScannerPlatform.instance.startScanning();
  }

  Future<void> stopScanning() {
    return FlutterCardScannerPlatform.instance.stopScanning();
  }

  Future<void> stopCamera() {
    return FlutterCardScannerPlatform.instance.stopCamera();
  }
}
