import 'package:appleocr/common_components/camera_scanner_overlay.dart';
import 'package:appleocr/plugins/ml_card_scanner/ml_card_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScanCardPage extends StatefulWidget {
  const ScanCardPage({super.key});

  @override
  State<ScanCardPage> createState() => _ScanCardPageState();
}

class _ScanCardPageState extends State<ScanCardPage> {
  final platform = const MethodChannel('com.3frames/ocr');
  final _scannerController = ScannerWidgetController();
  final _overlayOrientation = CardOrientation.landscape;

  @override
  void initState() {
    super.initState();
    _scannerController
      ..setCardListener(_onListenCard)
      ..setErrorListener(_onError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ScannerWidget(
              controller: _scannerController,
              overlayOrientation: _overlayOrientation,
              cameraResolution: CameraResolution.max,
              overlayBuilder: _overlayBuilder,
            ),
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
      onPrimaryButtonPressed: () => {},
    );
  }

  Widget get _cameraOverlay => CameraOverlayWidget(
        cardOrientation: _overlayOrientation,
        overlayColorFilter: const Color.fromRGBO(0, 0, 0, 80),
        overlayBorderRadius: 0,
      );

  @override
  void dispose() {
    _scannerController
      ..removeCardListeners(_onListenCard)
      ..removeErrorListener(_onError)
      ..dispose();
    super.dispose();
  }

  Future<void> _onListenCard(CardInfo? value) async {
    if (value != null) {
      _scannerController.disableCameraPreview();
      print('debug-print card number = ${value.number}');
      print('debug-print card expiry = ${value.expiry}');
    } else {}
  }

  void _onError(ScannerException exception) {
    debugPrint('debug-print: error = ${exception.message}');
  }
}
