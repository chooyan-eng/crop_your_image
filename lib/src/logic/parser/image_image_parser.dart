import 'dart:typed_data';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/parser/errors.dart';
import 'package:crop_your_image/src/logic/parser/image_detail.dart';
import 'package:image/image.dart' as image;

import 'image_parser.dart';

/// Implementation of [ImageParser] using image package
/// Parsed image is represented as [image.Image]
final ImageParser<image.Image> imageImageParser = (data, {inputFormat}) {
  late final image.Image? tempImage;
  try {
    tempImage = _decodeWith(data, format: inputFormat);
  } on InvalidInputFormatError {
    rethrow;
  }

  assert(tempImage != null);

  // check orientation
  final parsed = switch (tempImage?.exif.exifIfd.orientation ?? -1) {
    3 => image.copyRotate(tempImage!, angle: 180),
    6 => image.copyRotate(tempImage!, angle: 90),
    8 => image.copyRotate(tempImage!, angle: -90),
    _ => tempImage!,
  };

  return ImageDetail(
    image: parsed,
    width: parsed.width.toDouble(),
    height: parsed.height.toDouble(),
  );
};

image.Image? _decodeWith(Uint8List data, {ImageFormat? format}) {
  try {
    return switch (format) {
      ImageFormat.jpeg => image.decodeJpg(data),
      ImageFormat.png => image.decodePng(data),
      ImageFormat.bmp => image.decodeBmp(data),
      ImageFormat.ico => image.decodeIco(data),
      ImageFormat.webp => image.decodeWebP(data),
      _ => image.decodeImage(data),
    };
  } on image.ImageException {
    throw InvalidInputFormatError(format);
  }
}
