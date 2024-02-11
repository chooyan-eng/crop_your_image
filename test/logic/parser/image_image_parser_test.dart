import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/parser/errors.dart';
import 'package:crop_your_image/src/logic/parser/image_image_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final imageParser = imageImageParser;

  group('when png image with the size of 656 x 453 is given', () {
    late Uint8List testImage;

    setUpAll(() {
      // read a test image file with the size of 656 x 453
      testImage = File('test_resources/snow_landscape.png').readAsBytesSync();
    });

    test(
      'imageParser generates ImageDetail with width: 656, height: 453',
      () {
        final actual = imageParser(testImage);

        expect(actual.width, 656);
        expect(actual.height, 453);
        expect(actual.image, isNotNull);
      },
    );

    test(
      'imageParser generates ImageDetail with width: 656, height: 453'
      'when passing inputFormat: ImageFormat.png',
      () {
        final actual = imageParser(
          testImage,
          inputFormat: ImageFormat.png,
        );

        expect(actual.width, 656);
        expect(actual.height, 453);
        expect(actual.image, isNotNull);
      },
    );

    test(
      'imageParser throws InvalidInputFormatError'
      'when passing wrong inputFormat, ImageFormat.jpeg',
      () {
        expect(
          () => imageParser(
            testImage,
            inputFormat: ImageFormat.jpeg,
          ),
          throwsA(const TypeMatcher<InvalidInputFormatError>()),
        );
      },
    );
  });
}
