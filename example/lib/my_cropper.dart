import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as image hide ImageFormat;

class MyImageCropper extends ImageCropper<image.Image> {
  const MyImageCropper();
  @override
  RectValidator<image.Image> get rectValidator => defaultRectValidator;

  @override
  RectCropper<image.Image> get rectCropper => _rectCropper;

  @override
  CircleCropper<image.Image> get circleCropper => _circleCropper;
}

final RectCropper<image.Image> _rectCropper = (
  image.Image original, {
  required Offset topLeft,
  required Size size,
  required ImageFormat? outputFormat,
}) {
  /// crop image with low quality
  return image.encodeJpg(
    quality: 10,
    image.copyCrop(
      original,
      x: topLeft.dx.toInt(),
      y: topLeft.dy.toInt(),
      width: size.width.toInt(),
      height: size.height.toInt(),
    ),
  );
};

final CircleCropper<image.Image> _circleCropper = (
  image.Image original, {
  required Offset center,
  required double radius,
  required ImageFormat? outputFormat,
}) {
  /// crop image with low quality
  /// note: jpg can't cropped circle
  return image.encodeJpg(
    quality: 10,
    image.copyCropCircle(
      original,
      centerX: center.dx.toInt(),
      centerY: center.dy.toInt(),
      radius: radius.toInt(),
    ),
  );
};
