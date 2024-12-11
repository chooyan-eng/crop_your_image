import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:crop_your_image/src/logic/cropper/errors.dart';
import 'package:image/image.dart';

/// default implementation of [RectValidator]
/// this checks if the rect is inside the image, not negative, and not negative size
final RectValidator<Image> defaultRectValidator =
    (Image original, Offset topLeft, Offset bottomRight) {
  if (topLeft.dx.toInt().isNegative ||
      topLeft.dy.toInt().isNegative ||
      bottomRight.dx.toInt().isNegative ||
      bottomRight.dy.toInt().isNegative ||
      topLeft.dx.toInt() > original.width ||
      topLeft.dy.toInt() > original.height ||
      bottomRight.dx.toInt() > original.width ||
      bottomRight.dy.toInt() > original.height) {
    return InvalidRectError(topLeft: topLeft, bottomRight: bottomRight);
  }
  if (topLeft.dx > bottomRight.dx || topLeft.dy > bottomRight.dy) {
    return NegativeSizeError(topLeft: topLeft, bottomRight: bottomRight);
  }
  return null;
};
