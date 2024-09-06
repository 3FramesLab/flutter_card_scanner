import 'package:appleocr/CameraPreviewScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // static const platform = MethodChannel('com.3frames/ocr');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _captureImage,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _captureImage() async {
    Get.to(() => const CameraPreviewScreen());
    // Get.to(() => const ScanCardPage());
    return;
    // try {
    //   final ocrResult = await platform.invokeMethod('startCamera',); // getTextFromImage
    // } on PlatformException catch (e) {
    //   print('debug-print in PlatformException $e');
    // }
  }
  /*
    Get.to(() => const ScanCardPage());
    return;
    final captureImageFile =
        await ImagePicker().pickImage(source: ImageSource.camera);

    print('debug-print capture image path = ${captureImageFile?.path}');

    if (captureImageFile == null) {
      print('debug-print captureImageFile is null');
      return;
    }

    final Uint8List bytes = await captureImageFile.readAsBytes();

    try {
      print('bytes $bytes');
      final ocrResult = await platform.invokeMethod('getTextFromImage', {
        "image_data": bytes,
      });

      if (ocrResult == null) {
        print('debug-print ocrResult is null');
        return;
      }
      if (ocrResult is Map) {
        print('debug-print ocrResult as below');
        ocrResult.forEach((key, value) {
          print('debug-print key = $key, value = $value');
        });
      }
    } on PlatformException catch (e) {
      print('debug-print in PlatformException $e');
    }
  }
  */
}
