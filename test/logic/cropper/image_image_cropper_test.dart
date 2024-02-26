import 'dart:io';

import 'package:crop_your_image/src/logic/cropper/errors.dart';
import 'package:crop_your_image/src/logic/cropper/image_image_cropper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart';

void main() {
  late ImageImageCropper cropper;

  setUp(() {
    cropper = ImageImageCropper();
  });

  group('when png image with the size of 656 x 453 is given', () {
    late Image testImage;

    setUpAll(() {
      // read a test image file with the size of 656 x 453
      final data = File('test_resources/snow_landscape.png').readAsBytesSync();
      testImage = decodeImage(data)!;
    });

    test(
      'crop from Offset(100, 50) to Offset(200, 150)'
      'generates the image sized 100 x 100',
      () async {
        final croppedImage = await cropper.call(
          original: testImage,
          topLeft: Offset(100, 50),
          bottomRight: Offset(200, 150),
        );

        final imageDetail = decodeImage(croppedImage);

        expect(imageDetail, isNotNull);
        expect(imageDetail!.width, 100);
        expect(imageDetail.height, 100);
      },
    );

    test('the format of the cropped image is always png, not jpeg', () async {
      final croppedImage = await cropper.call(
        original: testImage,
        topLeft: Offset(100, 50),
        bottomRight: Offset(200, 150),
      );

      expect(PngDecoder().isValidFile(croppedImage), isTrue);
      expect(JpegDecoder().isValidFile(croppedImage), isFalse);
    });

    test(
      'InvalidRangeError is thrown if given Offset has negative value',
      () async {
        expect(
          () async => await cropper.call(
            original: testImage,
            topLeft: Offset(-100, -50),
            bottomRight: Offset(200, 150),
          ),
          throwsA(const TypeMatcher<InvalidRectError>()),
        );

        expect(
          () async => await cropper.call(
            original: testImage,
            topLeft: Offset(0, 0),
            bottomRight: Offset(-200, -150),
          ),
          throwsA(const TypeMatcher<InvalidRectError>()),
        );
      },
    );

    test(
      'NegativeSizeError is thrown if the value of bottomRight is smaller than topLeft',
      () async {
        expect(
          () async => await cropper.call(
            original: testImage,
            topLeft: Offset(200, 50),
            bottomRight: Offset(100, 100),
          ),
          throwsA(const TypeMatcher<NegativeSizeError>()),
        );
      },
    );

    test(
      'NegativeSizeError is NOT thrown'
      'if the value of bottomRight is slightly greater than image size',
      () async {
        final croppedImage = await cropper.call(
          original: testImage,
          topLeft: Offset(100, 50),
          bottomRight: Offset(656.0004, 453.00005),
        );

        final imageDetail = decodeImage(croppedImage);

        expect(imageDetail, isNotNull);
        expect(imageDetail!.width, 556);
        expect(imageDetail.height, 403);
      },
    );
  });
}
