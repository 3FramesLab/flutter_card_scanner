import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_scanner/flutter_card_scanner.dart';
import 'package:flutter_card_scanner/flutter_card_scanner_method_channel.dart';
import 'package:get/route_manager.dart';

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  FlutterCardScanner flutterCardScanner = FlutterCardScanner();

  int? _textureId;
  double _previewWidth = 0.0;
  double _previewHeight = 0.0;
  bool isPortrait = false;
  // final _overlayOrientation = CardOrientation.landscape;

  @override
  void initState() {
    super.initState();
    // platform.setMethodCallHandler(_handleMethod);
    MethodChannelFlutterCardScanner.methodChannel
        .setMethodCallHandler(_handleMethod);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      print('debug-print: initializing camera');
      await startCamera();
      var previewWidth = await flutterCardScanner.getPreviewWidth();
      var previewHeight = await flutterCardScanner.getPreviewHeight();

      setState(() {
        print('setting attributes');
        print(previewWidth);
        print(previewHeight);

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
                // Container(
                //   child: _overlayBuilder(context),
                // ),
              ],
            ),
    );
  }

  // Widget _overlayBuilder(BuildContext context) {
  //   return CameraScannerOverlay(
  //     cameraOverlayLayout: _cameraOverlay,
  //     scannerMessage:
  //         'Hold card inside the frame.\nIt will scan automatically.',
  //     primaryButtonText: 'Add Card Number Manually',
  //     onPrimaryButtonPressed: () {
  //       print('click on button');
  //     },
  //   );
  // }

  // Widget get _cameraOverlay => CameraOverlayWidget(
  //       cardOrientation: _overlayOrientation,
  //       overlayColorFilter: const Color.fromRGBO(0, 0, 0, 80),
  //       overlayBorderRadius: 0,
  //     );

  Future<dynamic> _handleMethod(MethodCall call) async {
    if (call.method == "onCardDetected") {
      flutterCardScanner.stopScanning();
      print('debug-print: card details: ${call.arguments}');

      Get.dialog(
        AlertDialog(
          title: const Text('Card Details'),
          content: Text('Card Number: ${call.arguments['number']}'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Get.back();
                Get.back(result: call.arguments);
              },
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                flutterCardScanner.startScanning();
                // startCamera();
              },
              child: const Text('Re-Scan'),
            ),
          ],
        ),
      );

      // print(call.arguments);
      // Navigator.pop(context, call.arguments);
    }
  }

  Future<void> startCamera() async {
    final textureId = await flutterCardScanner.startCamera();
    setState(() {
      _textureId = textureId as int;
    });
  }
}
