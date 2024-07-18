import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_your_image/src/widget/controller.dart';
import 'package:crop_your_image/src/widget/crop.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helper.dart';

void main() {
  late Uint8List testLandscapeImage;
  late Uint8List testPortraitImage;

  group('when png image with the size of 656 x 453 is given', () {
    setUpAll(() {
      // read a test image file with the size of 656 x 453
      testLandscapeImage =
          File('test_resources/snow_landscape.png').readAsBytesSync();
      testPortraitImage =
          File('test_resources/snow_portrait.png').readAsBytesSync();
    });

    testWidgets(
      'onCropped is called after calling CropController.crop()',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testLandscapeImage,
            controller: controller,
            onCropped: (value) => completer.complete(),
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
      'onCropped is called after calling CropController.cropCircle()',
      (tester) async {
        // to ensure callback is called
        final completer = Completer<void>();

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testLandscapeImage,
            controller: controller,
            onCropped: (value) => completer.complete(),
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));

          controller.cropCircle();
          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(completer.isCompleted, isTrue);
      },
    );

    testWidgets(
      'Rect of cropping area changes after setting another image',
      (tester) async {
        Rect? initialRect;
        Rect? lastRect;

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testLandscapeImage,
            controller: controller,
            onCropped: (value) {},
            onMoved: (rect, _) {
              initialRect ??= rect;
              lastRect = rect;
            },
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));

          controller.image = testPortraitImage;
          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(initialRect != lastRect, isTrue);
      },
    );

    testWidgets(
      'aspect ratio of Rect of cropping area is 4:6 if aspectRatio is set to 4/6',
      (tester) async {
        Rect? initialRect;
        Rect? lastRect;

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testLandscapeImage,
            controller: controller,
            aspectRatio: 1,
            onCropped: (value) {},
            onMoved: (rect, _) {
              initialRect ??= rect;
              lastRect = rect;
            },
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));

          controller.aspectRatio = 4 / 6;
          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(initialRect != lastRect, isTrue);
        expect(initialRect!.width / initialRect!.height, 1);
        expect(lastRect!.width / lastRect!.height, 4 / 6);
      },
    );

    testWidgets(
      'Rect of cropping area is Rect(10, 50, 50, 100) after setting via controller.rect',
      (tester) async {
        Rect? lastRect;

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testLandscapeImage,
            controller: controller,
            aspectRatio: 1,
            onCropped: (value) {},
            onMoved: (rect, _) => lastRect = rect,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));

          controller.cropRect = Rect.fromLTRB(10, 50, 50, 100);
          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(lastRect!.left, 10);
        expect(lastRect!.top, 50);
        expect(lastRect!.right, 50);
        expect(lastRect!.bottom, 100);
      },
    );

    testWidgets(
      'Rect of cropping area is Rect(10, 46.4, 50, 100)'
      'after setting Rect(10, 10, 50, 100) via controller.rect',
      (tester) async {
        Rect? lastRect;

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testLandscapeImage,
            controller: controller,
            aspectRatio: 1,
            onCropped: (value) {},
            onMoved: (rect, _) => lastRect = rect,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));

          controller.cropRect = Rect.fromLTRB(10, 10, 50, 100);
          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        expect(lastRect!.left, 10);

        // Because top: 10 is out of the image,
        // it is corrected to 46.4, which is top bound of the image.
        expect(lastRect!.top.floor(), 46);

        expect(lastRect!.right, 50);
        expect(lastRect!.bottom, 100);
      },
    );

    testWidgets(
      'Rect of cropping area is Rect(4, 50, 22, 92)'
      'after setting Rect(10, 10, 50, 100) via controller.area',
      (tester) async {
        Rect? lastRect;

        final controller = CropController();
        final widget = withMaterial(
          Crop(
            image: testLandscapeImage,
            controller: controller,
            aspectRatio: 1,
            onCropped: (value) {},
            onMoved: (rect, _) => lastRect = rect,
          ),
        );

        await tester.runAsync(() async {
          await tester.pumpWidget(widget);
          // wait for parsing image
          await Future.delayed(const Duration(seconds: 2));

          // set Rect based on original image size
          controller.area = Rect.fromLTRB(10, 10, 50, 100);

          // wait for cropping image
          await Future.delayed(const Duration(seconds: 2));
        });

        // expected Rect is based on viewport
        expect(lastRect!.left.floor(), 4);
        expect(lastRect!.top.floor(), 50);
        expect(lastRect!.right.floor(), 22);
        expect(lastRect!.bottom.floor(), 92);
      },
    );
  });
}
