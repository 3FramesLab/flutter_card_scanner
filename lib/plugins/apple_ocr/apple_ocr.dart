import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart';

class AppleOcr {
  static const channel = MethodChannel('com.3frames/ocr');
  static const _getTextFromImage = 'getTextFromImage';

  static Future<Map<String, String>> getTextFromImage(
    String data,
  ) async {
    try {
      final result =
          await channel.invokeMethod<Map<String, String>>(_getTextFromImage, {
        "image_data": data
      });

      print('debug-print result = $result');

      if (result == null) {
        return {};
      }
      return result;
    } on PlatformException catch (e) {
      print('debug-print Failed to get text from image: ${e.message}');
      return {};
    }
  }

  static String getCardNumber(Map<String, String> ocrResult) {
    return ocrResult['number'] ?? '';
  }

  static String getExpiryDate(Map<String, String> ocrResult) {
    return ocrResult['expiry'] ?? '';
  }
}
