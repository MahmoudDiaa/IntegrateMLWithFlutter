import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pytorch_lite/pigeon.dart';
import 'package:pytorch_lite/pytorch_lite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ModelObjectDetection _objectModel;
  String? _imagePrediction;
  File? _image;

  bool objectDetection = false;
  List<ResultObjectDetection?> objDetect = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Image with Detections....
              Expanded(
                child: Container(
                  child: objDetect.isNotEmpty
                      ? _image == null
                          ? const Text('No image selected.')
                          : _objectModel.renderBoxesOnImage(_image!, objDetect)
                      : _image == null
                          ? const Text('No image selected.')
                          : Image.file(_image!),
                ),
              ),
              Center(
                child: Visibility(
                  visible: _imagePrediction != null,
                  child: Text("$_imagePrediction"),
                ),
              ),
              //Button to click pic
              ElevatedButton(
                onPressed: () {
                  runObjectDetection();
                },
                child: const Icon(Icons.camera),
              )
            ],
          )),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {
    String pathObjectDetectionModel = "assets/torch/best.torchscript";
    try {
      _objectModel = await PytorchLite.loadObjectDetectionModel(
          //Remember here 80 value represents number of classes for custom model it will be different don't forget to change this.
          pathObjectDetectionModel,
          11,
          640,
          640,
          labelPath: "assets/torch/labels.txt");
    } catch (e) {
      if (e is PlatformException) {
        debugPrint("only supported for android, Error is $e");
      } else {
        debugPrint("Error is $e");
      }
    }
  }

  Future runObjectDetection() async {
    //pick an image

    File image = await getImageFileFromAssets('test3.jpg');
    objDetect = await _objectModel.getImagePrediction(await image.readAsBytes(),
        minimumScore: 0.2, iOUThreshold: 0.5);
    for (var element in objDetect) {
      debugPrint('${{
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      }}');
    }
    setState(() {
      _image = File(image.path);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('assets/$path');

    final file = File('${(await getTemporaryDirectory()).path}/$path');
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

    return file;
  }
}
