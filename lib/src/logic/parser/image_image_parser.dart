import 'package:crop_your_image/src/logic/parser/image_detail.dart';
import 'package:image/image.dart' as image;

import 'image_parser.dart';

/// Implementation of [ImageParser] using image package
/// Parsed image is represented as [image.Image]
final ImageParser<image.Image> imageImageParser = (data) {
  final tempImage = image.decodeImage(data);
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
