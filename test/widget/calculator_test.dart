import 'dart:ui';

import 'package:crop_your_image/src/logic/parser/image_detail.dart';
import 'package:crop_your_image/src/widget/calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Calculator calculator;

  group(
    'when image of original size (600, 400) fits horizontally'
    'at screen size (300, 600)',
    () {
      late Size originalImageSize;
      late Size viewportSize;

      setUpAll(() {
        calculator = HorizontalCalculator();
        originalImageSize = Size(600, 400);
        viewportSize = Size(300, 600);
      });

      test('Rect of image is Rect.fromLTRB(0, 200, 300, 400)', () {
        final actual = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        expect(actual, Rect.fromLTRB(0, 200, 300, 400));
      });

      test(
          'Rect of crop area is Rect.fromLTRB(50, 200, 250, 400)'
          'when aspectRatio: 1, sizeRatio: 1', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 1, 1);

        expect(actual, Rect.fromLTRB(50, 200, 250, 400));
      });

      test(
          'Rect of crop area is Rect.fromLTRB(100, 250, 200, 350)'
          'when aspectRatio: 1, sizeRatio: 0.5', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 1, 0.5);

        expect(actual, Rect.fromLTRB(100, 250, 200, 350));
      });

      test(
          'Rect of crop area is Rect.fromLTRB(100, 250, 200, 350)'
          'when aspectRatio: 3 / 4, sizeRatio: 1', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 3 / 4, 1);

        expect(actual, Rect.fromLTRB(75, 200, 225, 400));
      });

      test(
          'Rect of crop area is Rect.fromLTRB(100, 250, 200, 350)'
          'when aspectRatio: 3 / 4, sizeRatio: 0.5', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 3 / 4, 0.5);

        expect(actual, Rect.fromLTRB(112.5, 250, 187.5, 350));
      });

      test('Scale is 3.0 to cover viewport', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual = calculator.scaleToCover(viewportSize, imageRect);

        // scale Size(300, 200) to Size(900, 600) fits in Size(300, 600) of viewport
        expect(actual, 3.0);
      });

      test('screenSizeRatio is 2.0', () {
        final actual = calculator.screenSizeRatio(
          ImageDetail<void>(
            height: originalImageSize.height,
            width: originalImageSize.width,
            image: null,
          ),
          viewportSize,
        );

        // viewport Size(300, 600) to original image Size(600, 400)
        // comparing width, 600 / 300 = 2.0
        expect(actual, 2.0);
      });
    },
  );

  group(
    'when image of original size (400, 600) fits vertically'
    'at screen size (400, 300)',
    () {
      late Size originalImageSize;
      late Size viewportSize;

      setUpAll(() {
        calculator = VerticalCalculator();
        originalImageSize = Size(400, 600);
        viewportSize = Size(400, 300);
      });

      test('Rect of image is Rect.fromLTRB(100, 0, 300, 300)', () {
        final actual = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        expect(actual, Rect.fromLTRB(100, 0, 300, 300));
      });

      test(
          'Rect of crop area is Rect.fromLTRB(100, 50, 300, 250)'
          'when aspectRatio: 1, sizeRatio: 1', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 1, 1);

        expect(actual, Rect.fromLTRB(100, 50, 300, 250));
      });

      test(
          'Rect of crop area is Rect.fromLTRB(150, 100, 250, 200)'
          'when aspectRatio: 1, sizeRatio: 0.5', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 1, 0.5);

        expect(actual, Rect.fromLTRB(150, 100, 250, 200));
      });

      test(
          'Rect of crop area is about Rect.fromLTRB(100.0, 16, 300.0, 283)'
          'when aspectRatio: 3 / 4, sizeRatio: 1', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 3 / 4, 1);

        expect(actual.left, 100.0);
        expect(actual.top.floor(), 16);
        expect(actual.right, 300.0);
        expect(actual.bottom.floor(), 283);
      });

      test(
          'Rect of crop area is Rect.fromLTRB(150, 83, 250, 216)'
          'when aspectRatio: 3 / 4, sizeRatio: 0.5', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual =
            calculator.initialCropRect(viewportSize, imageRect, 3 / 4, 0.5);

        expect(actual.left, 150.0);
        expect(actual.top.floor(), 83);
        expect(actual.right, 250.0);
        expect(actual.bottom.floor(), 216);
      });

      test('Scale is 2.0 to cover viewport', () {
        final imageRect = calculator.imageRect(
            viewportSize, originalImageSize.width / originalImageSize.height);

        final actual = calculator.scaleToCover(viewportSize, imageRect);

        // scale Size(300, 200) to Size(600, 400) fits in Size(300, 400) of viewport
        expect(actual, 2.0);
      });

      test('screenSizeRatio is 2.0', () {
        final actual = calculator.screenSizeRatio(
          ImageDetail<void>(
            height: originalImageSize.height,
            width: originalImageSize.width,
            image: null,
          ),
          viewportSize,
        );

        // viewport Size(400, 300) to original image Size(400, 600)
        // comparing width, 600 / 300 = 2.0
        expect(actual, 2.0);
      });
    },
  );
  group(
      'when image fits crop editor horizontally'
      'with Rect.fromLTWH(0, 50, 300, 250)', () {
    late Rect imageRect;

    setUpAll(() {
      calculator = HorizontalCalculator();
      imageRect = Rect.fromLTRB(0, 50, 300, 300);
    });

    group('starts with crop rect of ViewportBasedRect(50, 80, 150, 200)', () {
      late Rect original;

      setUpAll(() {
        original = Rect.fromLTRB(50, 80, 150, 200);
      });

      test(
          'moving crop rect by dx:10, dy:10'
          'result in Rect(60, 90, 160, 210)', () {
        final actual = calculator.moveRect(original, 10, 10, imageRect);

        expect(actual, Rect.fromLTRB(60, 90, 160, 210));
      });

      test(
          'moving crop rect by dx:150, dy:150'
          'result in Rect(200, 180, 300, 300)', () {
        final actual = calculator.moveRect(original, 150, 150, imageRect);

        // considering image size, dy of crop rect
        // can't be greater than imageRect.bottom
        expect(actual, Rect.fromLTRB(200, 180, 300, 300));
      });

      test(
          'moving crop rect by dx:-50, dy:-50'
          'result in Rect(0, 50, 100, 170)', () {
        final actual = calculator.moveRect(original, -50, -50, imageRect);

        // considering image size, dx, dy of crop rect
        // can't be smaller than imageRect.left, imageRect.top
        expect(actual, Rect.fromLTRB(0, 50, 100, 170));
      });

      test(
          'moving crop rect by dx:200, dy:50'
          'result in Rect(200, 130, 300, 250)', () {
        final actual = calculator.moveRect(original, 200, 50, imageRect);

        // considering image size, dy of crop rect
        // can't be greater than imageRect.bottom
        expect(actual, Rect.fromLTRB(200, 130, 300, 250));
      });

      test(
          'moving topLeft dot by dx:10, dy:10'
          'result in Rect(60, 90, 150, 200)', () {
        final actual =
            calculator.moveTopLeft(original, 10, 10, imageRect, null);

        expect(actual, Rect.fromLTRB(60, 90, 150, 200));
      });

      test(
          'moving topLeft dot by dx:150, dy:150'
          'result in Rect(110, 160, 150, 200)', () {
        final actual =
            calculator.moveTopLeft(original, 150, 150, imageRect, null);

        // considering DotControl's size, topLeft can't be greater than
        // Offset(dx: bottomRight.left - 40, dy: bottomRight.top - 40)
        expect(actual, Rect.fromLTRB(110, 160, 150, 200));
      });

      test(
          'moving topRight dot by dx:10, dy:10'
          'result in Rect(50, 90, 160, 200)', () {
        final actual =
            calculator.moveTopRight(original, 10, 10, imageRect, null);

        expect(actual, Rect.fromLTRB(50, 90, 160, 200));
      });

      test(
          'moving topRight dot by dx:150, dy:150'
          'result in Rect(50, 160, 300, 200)', () {
        final actual =
            calculator.moveTopRight(original, 150, 150, imageRect, null);

        // considering DotControl's size,
        // dy of topRight can't be greater than bottomRight.top - 40
        expect(actual, Rect.fromLTRB(50, 160, 300, 200));
      });

      test(
          'moving bottomLeft dot by dx:10, dy:10'
          'result in Rect(60, 80, 150, 210)', () {
        final actual =
            calculator.moveBottomLeft(original, 10, 10, imageRect, null);

        expect(actual, Rect.fromLTRB(60, 80, 150, 210));
      });

      test(
          'moving bottomLeft dot by dx:150, dy:150'
          'result in Rect(50, 160, 300, 200)', () {
        final actual =
            calculator.moveBottomLeft(original, 150, 150, imageRect, null);

        // considering Image size,
        // bottom of bottomLeft can't be greater than imageRect.bottom
        expect(actual, Rect.fromLTRB(110, 80, 150, 300));
      });

      test(
          'moving bottomRight dot by dx:10, dy:10'
          'result in Rect(50, 80, 160, 210)', () {
        final actual =
            calculator.moveBottomRight(original, 10, 10, imageRect, null);

        expect(actual, Rect.fromLTRB(50, 80, 160, 210));
      });

      test(
          'moving bottomRight dot by dx:150, dy:150'
          'result in Rect(50, 80, 300, 300)', () {
        final actual =
            calculator.moveBottomRight(original, 150, 150, imageRect, null);

        // considering Image size,
        // bottom of bottomRight can't be greater than imageRect.bottom
        expect(actual, Rect.fromLTRB(50, 80, 300, 300));
      });
    });
    group(
        'when image rect is Rect.fromLTWH(0, 50, 300, 250)'
        'regardless of fits horizontal or vertical', () {
      late Rect imageRect;

      setUpAll(() {
        calculator = HorizontalCalculator();
        imageRect = Rect.fromLTRB(0, 50, 300, 300);
      });

      group('starts with crop rect of ViewportBasedRect(50, 80, 150, 200)', () {
        late Rect original;

        setUpAll(() {
          original = Rect.fromLTRB(50, 80, 150, 200);
        });

        test(
            'moving crop rect by dx:10, dy:10'
            'result in Rect(60, 90, 160, 210)', () {
          final actual = calculator.moveRect(original, 10, 10, imageRect);

          expect(actual, Rect.fromLTRB(60, 90, 160, 210));
        });

        test(
            'moving crop rect by dx:150, dy:150'
            'result in Rect(200, 180, 300, 300)', () {
          final actual = calculator.moveRect(original, 150, 150, imageRect);

          // considering image size, dy of crop rect
          // can't be greater than imageRect.bottom
          expect(actual, Rect.fromLTRB(200, 180, 300, 300));
        });

        test(
            'moving topLeft dot by dx:10, dy:10'
            'result in Rect(60, 90, 150, 200)', () {
          final actual =
              calculator.moveTopLeft(original, 10, 10, imageRect, null);

          expect(actual, Rect.fromLTRB(60, 90, 150, 200));
        });

        test(
            'moving topLeft dot by dx:150, dy:150'
            'result in Rect(110, 160, 150, 200)', () {
          final actual =
              calculator.moveTopLeft(original, 150, 150, imageRect, null);

          // considering DotControl's size, topLeft can't be greater than
          // Offset(dx: bottomRight.left - 40, dy: bottomRight.top - 40)
          expect(actual, Rect.fromLTRB(110, 160, 150, 200));
        });

        test(
            'moving topRight dot by dx:10, dy:10'
            'result in Rect(50, 90, 160, 200)', () {
          final actual =
              calculator.moveTopRight(original, 10, 10, imageRect, null);

          expect(actual, Rect.fromLTRB(50, 90, 160, 200));
        });

        test(
            'moving topRight dot by dx:150, dy:150'
            'result in Rect(50, 160, 300, 200)', () {
          final actual =
              calculator.moveTopRight(original, 150, 150, imageRect, null);

          // considering DotControl's size,
          // dy of topRight can't be greater than bottomRight.top - 40
          expect(actual, Rect.fromLTRB(50, 160, 300, 200));
        });

        test(
            'moving bottomLeft dot by dx:10, dy:10'
            'result in Rect(60, 80, 150, 210)', () {
          final actual =
              calculator.moveBottomLeft(original, 10, 10, imageRect, null);

          expect(actual, Rect.fromLTRB(60, 80, 150, 210));
        });

        test(
            'moving bottomLeft dot by dx:150, dy:150'
            'result in Rect(50, 160, 300, 200)', () {
          final actual =
              calculator.moveBottomLeft(original, 150, 150, imageRect, null);

          // considering Image size,
          // bottom of bottomLeft can't be greater than imageRect.bottom
          expect(actual, Rect.fromLTRB(110, 80, 150, 300));
        });

        test(
            'moving bottomRight dot by dx:10, dy:10'
            'result in Rect(50, 80, 160, 210)', () {
          final actual =
              calculator.moveBottomRight(original, 10, 10, imageRect, null);

          expect(actual, Rect.fromLTRB(50, 80, 160, 210));
        });

        test(
            'moving bottomRight dot by dx:150, dy:150'
            'result in Rect(50, 80, 300, 300)', () {
          final actual =
              calculator.moveBottomRight(original, 150, 150, imageRect, null);

          // considering Image size,
          // bottom of bottomRight can't be greater than imageRect.bottom
          expect(actual, Rect.fromLTRB(50, 80, 300, 300));
        });
      });
    });
  });
}
