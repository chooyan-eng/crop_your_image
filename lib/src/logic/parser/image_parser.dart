import 'dart:typed_data';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/parser/image_detail.dart';

/// Interface for parsing image and build [ImageDetail] from given [data].
typedef ImageParser<T> = ImageDetail<T> Function(
  Uint8List data, {
  ImageFormat? inputFormat,
});
