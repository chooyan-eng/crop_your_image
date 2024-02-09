import 'dart:ui';

import 'package:crop_your_image/src/widget/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Calculator calculator;

  group('when image is landscape with the size of 300x200', () {
    late Rect imageRect;

    setUpAll(() {
      calculator = HorizontalCalculator();
      imageRect = Rect.fromLTWH(0, 0, 300, 200);
    });

    group('starts with Rect(10, 20, 160, 140)', () {
      late Rect original;
      setUpAll(() {
        original = Rect.fromLTRB(10, 20, 160, 140);
      });
      test(
          'moving topLeft dot by dx:10, dy:10'
          'result in Rect(20, 30, 160, 140)', () {
        final actual = calculator.moveTopLeft(
          original,
          10,
          10,
          imageRect,
          null,
        );

        expect(actual, Rect.fromLTRB(20, 30, 160, 140));
      });

      test(
          'moving topLeft dot by dx:150, dy: 150'
          'result in Rect(120, 100, 160, 140)', () {
        final actual = calculator.moveTopLeft(
          original,
          150,
          150,
          imageRect,
          null,
        );

        // considering DotControl's size, topLeft can't be greater than
        // Offset(dx: bottomRight.left - 40, dy: bottomRight.top - 40)
        expect(actual, Rect.fromLTRB(120, 100, 160, 140));
      });
    });
  });
}
