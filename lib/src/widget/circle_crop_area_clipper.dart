import 'package:flutter/material.dart';

class CircleCropAreaClipper extends CustomClipper<Path> {
  final Rect rect;

  CircleCropAreaClipper(this.rect);

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(center: rect.center, radius: rect.width / 2))
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
