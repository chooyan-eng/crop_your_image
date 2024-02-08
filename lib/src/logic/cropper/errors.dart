import 'dart:ui';

class NegativeSizeError extends Error {
  final Offset topLeft;
  final Offset bottomRight;

  NegativeSizeError({
    required this.topLeft,
    required this.bottomRight,
  });
}

class InvalidRectError extends Error {
  final Offset topLeft;
  final Offset bottomRight;

  InvalidRectError({
    required this.topLeft,
    required this.bottomRight,
  });
}
