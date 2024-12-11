import 'package:crop_your_image/src/logic/cropper/image_cropper.dart';
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
  CircleCropper get circleCropper => throw UnimplementedError();

  @override
  RectCropper get rectCropper => throw UnimplementedError();

  @override
  RectValidator get rectValidator => throw Exception();
}
