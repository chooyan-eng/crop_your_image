import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:image/image.dart' as img;

final FormatDetector imageFormatDetector = (Uint8List data) {
  // Check for HEIF/HEIC format first (image package doesn't support it)
  if (_isHeifFormat(data)) {
    return ImageFormat.heif;
  }
  if (_isHeicFormat(data)) {
    return ImageFormat.heic;
  }

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

/// Check if the data is in HEIF format by examining the file signature
bool _isHeifFormat(Uint8List data) {
  if (data.length < 12) return false;
  // HEIF files start with 'ftyp' at bytes 4-7 and contain 'heif' or 'mif1'
  return data[4] == 0x66 && // 'f'
      data[5] == 0x74 && // 't'
      data[6] == 0x79 && // 'y'
      data[7] == 0x70 && // 'p'
      data.length >= 12 &&
      ((data[8] == 0x68 && data[9] == 0x65 && data[10] == 0x69 && data[11] == 0x66) || // 'heif'
          (data[8] == 0x6D && data[9] == 0x69 && data[10] == 0x66 && data[11] == 0x31)); // 'mif1'
}

/// Check if the data is in HEIC format by examining the file signature
bool _isHeicFormat(Uint8List data) {
  if (data.length < 12) return false;
  // HEIC files start with 'ftyp' at bytes 4-7 and contain 'heic'
  return data[4] == 0x66 && // 'f'
      data[5] == 0x74 && // 't'
      data[6] == 0x79 && // 'y'
      data[7] == 0x70 && // 'p'
      data.length >= 12 &&
      data[8] == 0x68 && // 'h'
      data[9] == 0x65 && // 'e'
      data[10] == 0x69 && // 'i'
      data[11] == 0x63; // 'c'
}
