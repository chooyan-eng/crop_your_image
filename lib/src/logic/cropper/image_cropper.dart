import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/shape.dart';

/// Interface for cropping logic
abstract class ImageCropper<T> {
  const ImageCropper();

  FutureOr<Uint8List> call({
    required T original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormat? outputFormat,
    ImageShape shape = ImageShape.rectangle,
  }) async {
    final error = rectValidator(original, topLeft, bottomRight);
    if (error != null) {
      throw error;
    }

    final size = Size(
      bottomRight.dx - topLeft.dx,
      bottomRight.dy - topLeft.dy,
    );

    return switch (shape) {
      ImageShape.rectangle => rectCropper(
          original,
          topLeft: topLeft,
          size: size,
          outputFormat: outputFormat,
        ),
      ImageShape.circle => circleCropper(
          original,
          center: Offset(
            topLeft.dx + size.width / 2,
            topLeft.dy + size.height / 2,
          ),
          radius: min(size.width, size.height) / 2,
          outputFormat: outputFormat,
        ),
    };
  }

  RectValidator<T> get rectValidator;
  RectCropper<T> get rectCropper;
  CircleCropper<T> get circleCropper;
}

typedef RectValidator<T> = Exception? Function(
    T original, Offset topLeft, Offset bottomRight);
typedef RectCropper<T> = Uint8List Function(
  T original, {
  required Offset topLeft,
  required Size size,
  required ImageFormat? outputFormat,
});

typedef CircleCropper<T> = Uint8List Function(
  T original, {
  required Offset center,
  required double radius,
  required ImageFormat? outputFormat,
});
