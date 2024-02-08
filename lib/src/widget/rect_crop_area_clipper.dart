import 'package:flutter/material.dart';

class CropAreaClipper extends CustomClipper<Path> {
  CropAreaClipper(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()
      ..addPath(
        Path()
          ..moveTo(rect.left, rect.top + radius)
          ..arcToPoint(Offset(rect.left + radius, rect.top),
              radius: Radius.circular(radius))
          ..lineTo(rect.right - radius, rect.top)
          ..arcToPoint(Offset(rect.right, rect.top + radius),
              radius: Radius.circular(radius))
          ..lineTo(rect.right, rect.bottom - radius)
          ..arcToPoint(Offset(rect.right - radius, rect.bottom),
              radius: Radius.circular(radius))
          ..lineTo(rect.left + radius, rect.bottom)
          ..arcToPoint(Offset(rect.left, rect.bottom - radius),
              radius: Radius.circular(radius))
          ..close(),
        Offset.zero,
      )
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
