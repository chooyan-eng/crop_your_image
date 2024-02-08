import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/format_detector/format_detector.dart';
import 'package:crop_your_image/src/logic/shape.dart';

/// Interface for cropping logic
abstract class ImageCropper<T> {
  final FormatDetector? formatDetector;

  const ImageCropper({required this.formatDetector});

  FutureOr<Uint8List> call({
    required T original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormat format = ImageFormat.jpeg,
    ImageShape shape = ImageShape.rectangle,
  });
}
