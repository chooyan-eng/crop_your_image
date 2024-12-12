import 'package:crop_your_image/src/logic/format_detector/format.dart';

class InvalidInputFormatException implements Exception {
  final ImageFormat? inputFormat;

  InvalidInputFormatException(this.inputFormat);
}
