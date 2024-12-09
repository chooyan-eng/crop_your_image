import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helper.dart';

void main() {
  late Uint8List testImage;

  group('when png image with the size of 656 x 453 is given', () {
    setUpAll(() {
      // read a test image file with the size of 656 x 453
      testImage = File('test_resources/snow_landscape.png').readAsBytesSync();
    });

    testWidgets(
      'pump Crop with minimum arguments works without errors',
      (tester) async {
        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
          ),
        );

        await tester.pumpWidget(widget);
      },
    );

    testWidgets(
      'onCropped is called after calling CropController.crop()',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) => completer.complete(),
            controller: controller,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));

          controller.crop();
          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(completer.isCompleted, isTrue);
      },
    );

    testWidgets(
      'status is changing with null -> .ready -> .cropping -> .ready',
      (tester) async {
        // to ensure status is changing
        CropStatus? lastStatus;

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            controller: controller,
            onStatusChanged: (status) => lastStatus = status,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          expect(lastStatus, isNull);

          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));
          expect(lastStatus, CropStatus.ready);

          controller.crop();
          expect(lastStatus, CropStatus.cropping);

          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(lastStatus, CropStatus.ready);
      },
    );

    testWidgets(
      'initialRectBuilder is called right after pumpWidget',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            initialRectBuilder: (viewportRect, imageRect) {
              completer.complete();
              return imageRect;
            },
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(completer.isCompleted, isTrue);
      },
    );

    testWidgets(
      'initialRectBuilder is called even if initialArea is also given',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            initialRectBuilder: (viewportRect, imageRect) {
              completer.complete();
              return imageRect;
            },
            // initialArea is ignored because initialRectBuilder is priored
            initialArea: Rect.zero,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(completer.isCompleted, isTrue);
      },
    );

    testWidgets(
      'onMoved is called when dragging DotControl',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            onMoved: (_, __) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);

          // wait for parsing image
          await Future.delayed(const Duration(seconds: 4));

          await tester.pumpAndSettle();
          final dotControl = find.byType(DotControl);
          expect(dotControl, findsNWidgets(4));

          await tester.drag(dotControl.first, Offset(10, 10));
        });

        expect(completer.isCompleted, isTrue);
      },
    );

    testWidgets(
      'customized dot controls from cornerDotBuilder is visible and available',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            onMoved: (_, __) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            cornerDotBuilder: (size, edgeAlignment) {
              return const Icon(Icons.circle);
            },
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);

          // wait for parsing image
          await Future.delayed(const Duration(seconds: 4));

          await tester.pumpAndSettle();
          final customDotControl = find.byType(Icon);
          expect(customDotControl, findsNWidgets(4));

          await tester.drag(customDotControl.first, Offset(10, 10));
        });

        expect(completer.isCompleted, isTrue);
      },
    );

    testWidgets(
      'dot control is still visible and available when only fixArea is set true',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            onMoved: (_, __) {
              if (!completer.isCompleted) {
                completer.complete();
              }
            },
            fixCropRect: true,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);

          // wait for parsing image
          await Future.delayed(const Duration(seconds: 4));

          await tester.pumpAndSettle();
          final dotControl = find.byType(DotControl);
          expect(dotControl, findsNWidgets(4));

          await tester.drag(dotControl.first, Offset(10, 10));
        });

        expect(completer.isCompleted, isTrue);
      },
    );

    testWidgets(
      'dot control is not movable if fixArea and interactive are both set true',
      (tester) async {
        // to ensure callback is only called when initialized
        var calledCount = 0;

        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            onMoved: (_, __) {
              calledCount++;
            },
            fixCropRect: true,
            interactive: true,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);

          // wait for parsing image
          await Future.delayed(const Duration(seconds: 4));

          await tester.pumpAndSettle();

          // dot control is still visible
          final dotControl = find.byType(DotControl);
          expect(dotControl, findsNWidgets(4));

          await tester.drag(dotControl.first, Offset(10, 10));
        });

        expect(calledCount, 1);
      },
    );

    testWidgets(
      'custom FormatDetector is called if given to Crop constructor',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final widget = withMaterial(
          Crop(
            image: testImage,
            onCropped: (value) {},
            formatDetector: (data) {
              completer.complete();
              return ImageFormat.png;
            },
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);

          // wait for parsing image
          await Future.delayed(const Duration(seconds: 4));
        });

        expect(completer.isCompleted, isTrue);
      },
    );
  });
}
