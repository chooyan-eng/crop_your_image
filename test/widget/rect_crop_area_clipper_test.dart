import 'package:crop_your_image/src/widget/rect_crop_area_clipper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shouldReclip is always true', () {
    final oldClipper = CropAreaClipper(Rect.fromLTWH(50, 50, 100, 100), 0);
    final clipper = CropAreaClipper(Rect.fromLTWH(50, 50, 100, 100), 0);

    expect(clipper.shouldReclip(oldClipper), true);
  });

  group('when viewport is 200 x 200', () {
    final viewportSize = 200.0;
    testWidgets(
      'CropAreaClipper clips center with 100x100 size of rectangular shape'
      'if passing Rect.fromLTWH(50, 50, 100, 100)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _ViewportWidget(
            size: viewportSize,
            targetWidget: RepaintBoundary(
              child: ClipPath(
                clipper: CropAreaClipper(Rect.fromLTWH(50, 50, 100, 100), 0),
                child: ColoredBox(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );

        await expectLater(
          find.byType(RepaintBoundary),
          matchesGoldenFile(
            'rect_crop_area_clipper.viewportSize200x200.crop_center.png',
          ),
        );
      },
    );

    testWidgets(
      'CropAreaClipper clips center with 100x100 size of rectangular shape with rounded corners'
      'if passing Rect.fromLTWH(50, 50, 100, 100) and radius: 20',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _ViewportWidget(
            size: viewportSize,
            targetWidget: RepaintBoundary(
              child: ClipPath(
                clipper: CropAreaClipper(Rect.fromLTWH(50, 50, 100, 100), 20),
                child: ColoredBox(
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        );

        await expectLater(
          find.byType(RepaintBoundary),
          matchesGoldenFile(
            'rect_crop_area_clipper.viewportSize200x200.crop_center_radius20.png',
          ),
        );
      },
    );
  });
}

class _ViewportWidget extends StatelessWidget {
  const _ViewportWidget({
    required this.size,
    required this.targetWidget,
  });

  final double size;
  final RepaintBoundary targetWidget;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: targetWidget,
      ),
    );
  }
}
