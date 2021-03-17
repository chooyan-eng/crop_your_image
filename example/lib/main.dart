import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('crop_your_image Sample'),
        ),
        body: CropSample(),
      ),
    );
  }
}

class CropSample extends StatefulWidget {
  @override
  _CropSampleState createState() => _CropSampleState();
}

class _CropSampleState extends State<CropSample> {
  final _cropController = CropController();

  Uint8List? _image;
  Uint8List? _croppedImage;

  bool _isCropping = false;
  bool _isCircle = false;
  double? _selectedAspectRatio;

  static const _aspectRatioSelection = <double?>[
    9 / 16,
    3 / 4,
    1 / 1,
    4 / 3,
    16 / 9,
    null
  ];

  @override
  void initState() {
    rootBundle.load('assets/images/big_pic.png').then((assetData) {
      final image = assetData.buffer.asUint8List();
      setState(() => _image = image);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Visibility(
          visible: _croppedImage == null,
          child: _isCropping
              ? CircularProgressIndicator()
              : Column(
                  children: [
                    Expanded(
                      child: _image != null
                          ? Crop(
                              image: _image!,
                              onCropped: (croppedImage) {
                                setState(() {
                                  _croppedImage = croppedImage;
                                  _isCropping = false;
                                });
                              },
                              withCircleUi: _isCircle,
                              aspectRatio: _selectedAspectRatio,
                              initialSize: 0.5,
                              controller: _cropController,
                            )
                          : const SizedBox(),
                    ),
                    const SizedBox(height: 32),
                    ToggleButtons(
                      isSelected: _aspectRatioSelection
                          .map((value) => value == _selectedAspectRatio)
                          .toList(),
                      onPressed: (index) {
                        _cropController.aspectRatio =
                            _aspectRatioSelection[index];
                        setState(() {
                          _selectedAspectRatio = _aspectRatioSelection[index];
                        });
                      },
                      children: _aspectRatioSelection
                          .map<Widget>((value) => Text(value == null
                              ? 'null'
                              : '${(value * 10).toInt() / 10}'))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text('Change shape'),
                      ),
                      onPressed: () {
                        _isCircle = !_isCircle;
                        _cropController.withCircleUi = _isCircle;
                      },
                    ),
                    const SizedBox(height: 60),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('Crop square!'),
                          ),
                          onPressed: () {
                            setState(() => _isCropping = true);
                            _cropController.crop();
                          },
                        ),
                        const SizedBox(width: 32),
                        ElevatedButton(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: Text('Crop circle!'),
                          ),
                          onPressed: () {
                            setState(() => _isCropping = true);
                            _cropController.cropCircle();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
          replacement: _croppedImage == null
              ? SizedBox.shrink()
              : Image.memory(_croppedImage!),
        ),
      ),
    );
  }
}
