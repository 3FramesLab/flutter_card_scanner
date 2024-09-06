import 'package:flutter/material.dart';

class CameraScannerOverlay extends StatelessWidget {
  final Widget cameraOverlayLayout;
  final String scannerMessage;
  final String primaryButtonText;
  final VoidCallback onPrimaryButtonPressed;

  const CameraScannerOverlay({
    required this.cameraOverlayLayout,
    required this.scannerMessage,
    required this.primaryButtonText,
    required this.onPrimaryButtonPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        cameraOverlayLayout,
        // _backButton(context),
        _scannerMessageText(context),
        _addCardNumberManuallyButton,
      ],
    );
  }

  // Widget _backButton(BuildContext context) {
  //   return Padding(
  //     padding: _backButtonPadding(context),
  //     child: const DrivenBackButton(color: DrivenColors.white),
  //   );
  // }

  // EdgeInsetsGeometry _backButtonPadding(BuildContext context) {
  //   return EdgeInsets.only(
  //     left: 16,
  //     top: MediaQuery.paddingOf(context).top,
  //   );
  // }

  Widget _scannerMessageText(BuildContext context) {
    return Positioned(
      bottom: (MediaQuery.sizeOf(context).height / 5),
      left: 16,
      right: 16,
      child: Text(
        scannerMessage,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.w600,
          shadows: [
            BoxShadow(
              color: Color(0xff000000),
              offset: Offset(0, 1),
              blurRadius: 4,
              spreadRadius: 0,
            )
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget get _addCardNumberManuallyButton => Positioned(
        bottom: 16,
        left: 16,
        right: 16,
        child: ElevatedButton(
          style: ButtonStyle(
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
            backgroundColor: WidgetStateProperty.all<Color>(
              const Color.fromRGBO(1, 97, 121, 1),
            ),
            // shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            //   const RoundedRectangleBorder(
            //     borderRadius: BorderRadius.zero,
            //     side: BorderSide(color: Color.fromRGBO(1, 97, 121, 1)),
            //   ),
            // ),
          ),
          onPressed: onPrimaryButtonPressed,
          child: Text(primaryButtonText),
        ),
      );
}
