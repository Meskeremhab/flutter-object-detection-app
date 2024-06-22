import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  File? _image;
  List<dynamic>? _recognitions;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  _loadModel() async {
    setState(() {
      _busy = true;
    });

    try {
      print('Loading model...');
      String? res = await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
      );
      print('Model loaded: $res');
    } catch (e) {
      print('Failed to load model: $e');
    }

    setState(() {
      _busy = false;
    });
  }

  _predictImage(File image) async {
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 5,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _recognitions = recognitions;
      _busy = false;
    });
  }

  _getImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _predictImage(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('TFLite Object Detection'),
        ),
        body: _busy
            ? Center(child: CircularProgressIndicator())
            : Column(
          children: <Widget>[
            _image == null
                ? Container()
                : Image.file(_image!, height: 300),
            SizedBox(height: 20),
            _recognitions == null
                ? Text('No results yet.')
                : Text('Detected objects:'),
            _recognitions == null
                ? Container()
                : Expanded(
              child: ListView.builder(
                itemCount: _recognitions!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      "${_recognitions![index]["label"]}: ${(_recognitions![index]["confidence"] * 100).toStringAsFixed(0)}%",
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Select Image from Gallery'),
              onPressed: _getImageFromGallery,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}
