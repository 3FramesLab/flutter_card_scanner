part of '../../ml_card_scanner.dart';

class CameraWidget extends StatefulWidget {
  final CameraController cameraController;
  final CameraDescription cameraDescription;
  final int scannerDelay;
  final CameraPreviewBuilder? cameraPreviewBuilder;
  final void Function(String data) onImage;

  const CameraWidget({
    required this.cameraController,
    required this.cameraDescription,
    required this.onImage,
    required this.scannerDelay,
    this.cameraPreviewBuilder,
    super.key,
  });

  @override
  CameraViewState createState() => CameraViewState();
}

class CameraViewState extends State<CameraWidget> {
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };
  int _lastFrameDecode = 0;
  final convertNative = ConvertNativeImgStream();

  Future<void> stopCameraStream() async {
    if (!widget.cameraController.value.isStreamingImages) {
      return;
    }
    return widget.cameraController.stopImageStream();
  }

  Future<void> startCameraStream() async {
    if (widget.cameraController.value.isStreamingImages) {
      return;
    }
    return widget.cameraController.startImageStream(_processCameraImage);
  }

  @override
  void initState() {
    super.initState();
    startCameraStream();
  }

  @override
  void dispose() {
    widget.cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final scale =
        1 / (widget.cameraController.value.aspectRatio * mediaSize.aspectRatio);

    return ClipRect(
      clipper: _MediaSizeClipper(mediaSize),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: CameraPreview(widget.cameraController),
      ),
    );
  }

  Future _processCameraImage(CameraImage image) async {
    if ((DateTime.now().millisecondsSinceEpoch - _lastFrameDecode) <
        widget.scannerDelay) {
      return;
    }
    _lastFrameDecode = DateTime.now().millisecondsSinceEpoch;
    final imageBytes = image.planes.first.bytes;
    String img64 = base64Encode(imageBytes);
    widget.onImage(img64);
  }

// static Future<List<int>> convertCameraImageToImage(
//       CameraImage cameraImage) async {
//     imglib.Image? img;
//     img = imglib.Image.fromBytes(
//         //cameraImage.planes[0].bytesPerRow,
//         width: cameraImage.width,
//         height: cameraImage.height,
//         bytes: cameraImage.planes.first.bytes.buffer, //ranulfo 20230615
//       );
//     var imgJpg = imglib.encodeJpg(img, quality: 100);
//     return imgJpg;
//   }

}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}
