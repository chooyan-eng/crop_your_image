import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;

final FormatDetector imageFormatDetector = (Uint8List data) {
  final format = img.findFormatForData(data);

  return switch (format) {
    img.ImageFormat.png => ImageFormat.png,
    img.ImageFormat.jpg => ImageFormat.jpeg,
    img.ImageFormat.webp => ImageFormat.webp,
    img.ImageFormat.bmp => ImageFormat.bmp,
    img.ImageFormat.ico => ImageFormat.ico,
    _ => ImageFormat.png,
  };
};
