import 'dart:ui';

class NegativeSizeException implements Exception {
  final Offset topLeft;
  final Offset bottomRight;

  NegativeSizeException({
    required this.topLeft,
    required this.bottomRight,
  });
}

class InvalidRectException implements Exception {
  final Offset topLeft;
  final Offset bottomRight;

  InvalidRectException({
    required this.topLeft,
    required this.bottomRight,
  });
}
