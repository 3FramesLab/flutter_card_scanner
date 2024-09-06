import 'dart:io';

import 'package:appleocr/common_components/camera_scanner_overlay.dart';
import 'package:appleocr/plugins/ml_card_scanner/ml_card_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  static const platform = MethodChannel('com.3frames/ocr');
  int? _textureId;
  double _previewWidth = 0.0;
  double _previewHeight = 0.0;
  bool isPortrait = false;
  final _overlayOrientation = CardOrientation.landscape;

  @override
  void initState() {
    super.initState();
    platform.setMethodCallHandler(_handleMethod);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      var textureId = await platform.invokeMethod('startCamera');
      var previewWidth = await platform.invokeMethod('getPreviewWidth');
      var previewHeight = await platform.invokeMethod('getPreviewHeight');

      setState(() {
        print('setting attributes');
        print(previewWidth);
        print(previewHeight);
        _textureId = textureId as int;
        _previewWidth = previewWidth.toDouble();
        _previewHeight = previewHeight.toDouble();
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    var orientation = MediaQuery.of(context).orientation;
    isPortrait = orientation == Orientation.portrait;
    return Scaffold(
      body: _textureId == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                SizedBox(
                  width: screenWidth,
                  height: screenHeight,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: isPortrait ? _previewHeight : _previewWidth,
                      height: isPortrait ? _previewWidth : _previewHeight,
                      child: Texture(textureId: _textureId!),
                    ),
                  ),
                ),
                Container(
                  child: _overlayBuilder(context),
                ),
              ],
            ),
    );
  }

  Widget _overlayBuilder(BuildContext context) {
    return CameraScannerOverlay(
      cameraOverlayLayout: _cameraOverlay,
      scannerMessage:
          'Hold card inside the frame.\nIt will scan automatically.',
      primaryButtonText: 'Add Card Number Manually',
      onPrimaryButtonPressed: () {
        print('click on button');
      },
    );
  }

  Widget get _cameraOverlay => CameraOverlayWidget(
        cardOrientation: _overlayOrientation,
        overlayColorFilter: const Color.fromRGBO(0, 0, 0, 80),
        overlayBorderRadius: 0,
      );

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == "onCardDetected") {
      // method.parameters is a Map of <String: String>
      // keys are 'number' & 'expiry'
      print(call.arguments);
      Navigator.pop(context, call.arguments);
      // Get.back(result: call.arguments);
    }
  }
}
