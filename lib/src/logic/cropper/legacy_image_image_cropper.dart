import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';

import 'package:image/image.dart' hide ImageFormat;

/// an implementation of [ImageCropper] using image package
/// this implementation is legacy that behaves the same as the version 1.1.0 or earlier
/// meaning that it doesn't respect the outputFormat and always encode result as png
class LegacyImageImageCropper extends ImageCropper<Image> {
  const LegacyImageImageCropper();

  @override
  RectCropper<Image> get rectCropper => legacyRectCropper;

  @override
  CircleCropper<Image> get circleCropper => legacyCircleCropper;

  @override
  RectValidator<Image> get rectValidator => defaultRectValidator;
}

/// process cropping image.
/// this method is supposed to be called only via compute()
final RectCropper<Image> legacyRectCropper = (
  Image original, {
  required Offset topLeft,
  required Size size,
  required ImageFormat? outputFormat,
}) {
  return encodePng(
    copyCrop(
      original,
      x: topLeft.dx.toInt(),
      y: topLeft.dy.toInt(),
      width: size.width.toInt(),
      height: size.height.toInt(),
    ),
  );
};

/// process cropping image with circle shape.
/// this method is supposed to be called only via compute()
final CircleCropper<Image> legacyCircleCropper = (
  Image original, {
  required Offset center,
  required double radius,
  required ImageFormat? outputFormat,
}) {
  // convert to rgba if necessary
  final target =
      original.numChannels == 4 ? original : original.convert(numChannels: 4);

  return encodePng(
    copyCropCircle(
      target,
      centerX: center.dx.toInt(),
      centerY: center.dy.toInt(),
      radius: radius.toInt(),
    ),
  );
};
