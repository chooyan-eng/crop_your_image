import 'package:crop_your_image/src/logic/format_detector/format.dart';

class InvalidInputFormatException implements Exception {
  final ImageFormat? inputFormat;

  InvalidInputFormatException(this.inputFormat);

  @override
  String toString() {
    return 'InvalidInputFormatException: Unsupported or invalid image format${inputFormat != null ? ": $inputFormat" : ""}';
  }
}

class UnsupportedImageFormatException implements Exception {
  final String message;

  UnsupportedImageFormatException(this.message);

  @override
  String toString() => 'UnsupportedImageFormatException: $message';
}
