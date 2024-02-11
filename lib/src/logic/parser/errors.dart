import 'package:crop_your_image/src/logic/format_detector/format.dart';

class InvalidInputFormatError extends Error {
  final ImageFormat? inputFormat;

  InvalidInputFormatError(this.inputFormat);
}
