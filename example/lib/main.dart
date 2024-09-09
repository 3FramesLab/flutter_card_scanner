import 'package:flutter/material.dart';
import 'package:flutter_card_scanner_example/CameraPreviewScreen.dart';
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
    final result = await Get.to(() => const CameraPreviewScreen());
    print(result);
    if (result is Map) {
      result.forEach((key, value) {
        final keyString = key.toString();
        if (keyString == 'number') {
          // cardNumber = 'Card number: $value';
          print('Card number: $value');
        }

        if (keyString == 'expiry') {
          // expiryDate = 'Expiry date: $value';
          print('Expiry date: $value');
        }
      });
    }
  }
}
