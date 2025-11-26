import 'dart:typed_data';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/parser/errors.dart';
import 'package:crop_your_image/src/logic/parser/image_detail.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:heic_to_png_jpg/heic_to_png_jpg.dart' hide ImageFormat;
import 'package:image/image.dart' as image;

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
  final normalizedImage = tempImage;
  final parsed = switch (normalizedImage.exif.exifIfd.orientation ?? -1) {
    3 => image.copyRotate(normalizedImage, angle: 180),
    6 => image.copyRotate(normalizedImage, angle: 90),
    8 => image.copyRotate(normalizedImage, angle: -90),
    _ => normalizedImage,
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
        final convertedData = await _convertHeifToJpeg(data);
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

/// Converts HEIF bytes into JPEG data using the most suitable platform helper.
/// Returns null if the current platform cannot perform the conversion.
Future<Uint8List?> _convertHeifToJpeg(Uint8List data) async {
  if (kIsWeb) {
    return HeicConverter.convertToJPG(heicData: data, quality: 100);
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
    case TargetPlatform.android:
      return HeicConverter.convertToJPG(heicData: data, quality: 100);
    case TargetPlatform.macOS:
      final converted = await FlutterImageCompress.compressWithList(
        data,
        format: CompressFormat.jpeg,
        quality: 100,
      );
      return converted.isEmpty ? null : converted;
    case TargetPlatform.fuchsia:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return null;
  }
}
