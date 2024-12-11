import 'dart:async';

import 'dart:typed_data';

import 'package:crop_your_image/src/logic/cropper/image_cropper.dart';
import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/shape.dart';
import 'package:flutter/material.dart';

Widget withMaterial(Widget widget) {
  return MaterialApp(
    home: Scaffold(
      // TODO(chooyan-eng): fix error on cropping if image is not large enough comparing to viewport
      // body: SizedBox.expand(child: widget),
      body: SizedBox(width: 300, height: 300, child: widget),
    ),
  );
}

/// [ImageCropper] that always fails
class FailureCropper extends ImageCropper {
  @override
  Future<Uint8List> call({
    required dynamic original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormat outputFormat = ImageFormat.jpeg,
    ImageShape shape = ImageShape.rectangle,
  }) async {
    throw Error();
  }
}