import 'dart:typed_data';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/parser/errors.dart';
import 'package:crop_your_image/src/logic/parser/image_detail.dart';
import 'package:image/image.dart' as image;
import 'package:heif_converter/heif_converter.dart';

import 'image_parser.dart';

/// Implementation of [ImageParser] using image package
/// Parsed image is represented as [image.Image]
final ImageParser<image.Image> imageImageParser = (data, {inputFormat}) async {
  late final image.Image? tempImage;
  try {
    tempImage = await _decodeWith(data, format: inputFormat);
  } on InvalidInputFormatException {
    rethrow;
  } on UnsupportedImageFormatException {
    rethrow;
  }

  if (tempImage == null) {
    throw UnsupportedImageFormatException(
      'Failed to decode image. The image format may not be supported. '
      'Supported formats: JPEG, PNG, BMP, ICO, WebP, HEIF, HEIC.',
    );
  }

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

Future<image.Image?> _decodeWith(Uint8List data, {ImageFormat? format}) async {
  try {
    // Handle HEIF/HEIC formats by converting to JPEG first
    if (format == ImageFormat.heif || format == ImageFormat.heic) {
      try {
        final convertedData = await HeifConverter.convert(data, format: 'jpeg');
        if (convertedData != null) {
          return image.decodeJpg(convertedData);
        }
      } catch (e) {
        throw UnsupportedImageFormatException(
          'Failed to convert HEIF/HEIC image: $e. '
          'Make sure your platform supports HEIF conversion.',
        );
      }
    }

    return switch (format) {
      ImageFormat.jpeg => image.decodeJpg(data),
      ImageFormat.png => image.decodePng(data),
      ImageFormat.bmp => image.decodeBmp(data),
      ImageFormat.ico => image.decodeIco(data),
      ImageFormat.webp => image.decodeWebP(data),
      _ => image.decodeImage(data),
    };
  } on image.ImageException {
    throw InvalidInputFormatException(format);
  }
}
