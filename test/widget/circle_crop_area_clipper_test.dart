import 'package:crop_your_image/src/widget/circle_crop_area_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shouldReclip is always true', () {
    final oldClipper = CircleCropAreaClipper(Rect.fromLTWH(50, 50, 100, 100));
    final clipper = CircleCropAreaClipper(Rect.fromLTWH(50, 50, 100, 100));

    expect(clipper.shouldReclip(oldClipper), true);
  });

  group('when viewport is 200 x 200', () {
    final viewportSize = 200.0;
    testWidgets(
      'CircleCropAreaClipper clips center with 100x100 size of circle shape'
      'if passing Rect.fromLTWH(50, 50, 100, 100)',
      (WidgetTester tester) async {
        Widget actual = Center(
          child: SizedBox(
            width: viewportSize,
            height: viewportSize,
            child: RepaintBoundary(
              child: ClipPath(
                clipper: CircleCropAreaClipper(Rect.fromLTWH(50, 50, 100, 100)),
                child: ColoredBox(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );
        await tester.pumpWidget(actual);
        await expectLater(
          find.byType(RepaintBoundary),
          matchesGoldenFile(
              'circle_crop_area_clipper.viewportSize200x200.crop_center.png'),
        );
      },
    );
  });
}
