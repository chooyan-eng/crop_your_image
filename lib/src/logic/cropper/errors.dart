import 'dart:ui';

class NegativeSizeError implements Exception {
  final Offset topLeft;
  final Offset bottomRight;

  NegativeSizeError({
    required this.topLeft,
    required this.bottomRight,
  });
}

class InvalidRectError implements Exception {
  final Offset topLeft;
  final Offset bottomRight;

  InvalidRectError({
    required this.topLeft,
    required this.bottomRight,
  });
}
