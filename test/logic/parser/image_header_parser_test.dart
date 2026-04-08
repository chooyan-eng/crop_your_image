import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/src/logic/format_detector/format.dart';
import 'package:crop_your_image/src/logic/parser/errors.dart';
import 'package:crop_your_image/src/logic/parser/image_header_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('imageHeaderFormatDetector', () {
    test('detects common image formats from headers', () {
      expect(imageHeaderFormatDetector(_pngHeader()), ImageFormat.png);
      expect(imageHeaderFormatDetector(_jpegHeader()), ImageFormat.jpeg);
      expect(imageHeaderFormatDetector(_webpHeader()), ImageFormat.webp);
      expect(imageHeaderFormatDetector(_bmpHeader()), ImageFormat.bmp);
      expect(imageHeaderFormatDetector(_icoHeader()), ImageFormat.ico);
    });
  });

  group('imageHeaderParser', () {
    test('reads dimensions from a PNG header without decoding pixels', () {
      final testImage =
          File('test_resources/snow_landscape.png').readAsBytesSync();

      final actual = imageHeaderParser(testImage);

      expect(actual.width, 656);
      expect(actual.height, 453);
      expect(actual.image, same(testImage));
    });

    test('throws InvalidInputFormatException for the wrong explicit format',
        () {
      expect(
        () => imageHeaderParser(_pngHeader(), inputFormat: ImageFormat.jpeg),
        throwsA(const TypeMatcher<InvalidInputFormatException>()),
      );
    });
  });

  group('readImageHeaderSize', () {
    test('reads JPEG dimensions', () {
      final actual = readImageHeaderSize(_jpegHeader(), ImageFormat.jpeg);

      expect(actual.width, 640);
      expect(actual.height, 480);
    });

    test('respects JPEG EXIF orientation for dimensions', () {
      final actual = readImageHeaderSize(
        _jpegHeaderWithExifOrientation6(),
        ImageFormat.jpeg,
      );

      expect(actual.width, 480);
      expect(actual.height, 640);
    });

    test('reads WEBP dimensions', () {
      final actual = readImageHeaderSize(_webpHeader(), ImageFormat.webp);

      expect(actual.width, 321);
      expect(actual.height, 241);
    });

    test('reads BMP dimensions', () {
      final actual = readImageHeaderSize(_bmpHeader(), ImageFormat.bmp);

      expect(actual.width, 320);
      expect(actual.height, 240);
    });

    test('reads ICO dimensions', () {
      final actual = readImageHeaderSize(_icoHeader(), ImageFormat.ico);

      expect(actual.width, 64);
      expect(actual.height, 32);
    });
  });
}

Uint8List _pngHeader() {
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, // IHDR length
    0x49, 0x48, 0x44, 0x52, // IHDR
    0x00, 0x00, 0x02, 0x80, // width: 640
    0x00, 0x00, 0x01, 0xE0, // height: 480
  ]);
}

Uint8List _jpegHeader() {
  return Uint8List.fromList([
    0xFF, 0xD8, // SOI
    0xFF, 0xC0, // SOF0
    0x00, 0x11, // segment length
    0x08, // precision
    0x01, 0xE0, // height: 480
    0x02, 0x80, // width: 640
    0x03, // components
    0x01, 0x11, 0x00,
    0x02, 0x11, 0x00,
    0x03, 0x11, 0x00,
  ]);
}

Uint8List _jpegHeaderWithExifOrientation6() {
  return Uint8List.fromList([
    0xFF, 0xD8, // SOI
    0xFF, 0xE1, // APP1
    0x00, 0x22, // segment length
    0x45, 0x78, 0x69, 0x66, 0x00, 0x00, // Exif header
    0x49, 0x49, // little endian TIFF
    0x2A, 0x00, // TIFF magic
    0x08, 0x00, 0x00, 0x00, // first IFD offset
    0x01, 0x00, // entry count
    0x12, 0x01, // orientation tag
    0x03, 0x00, // short type
    0x01, 0x00, 0x00, 0x00, // count
    0x06, 0x00, 0x00, 0x00, // value: rotate 90 degrees
    0x00, 0x00, 0x00, 0x00, // next IFD offset
    ..._jpegHeader().skip(2),
  ]);
}

Uint8List _webpHeader() {
  return Uint8List.fromList([
    0x52, 0x49, 0x46, 0x46, // RIFF
    0x00, 0x00, 0x00, 0x00,
    0x57, 0x45, 0x42, 0x50, // WEBP
    0x56, 0x50, 0x38, 0x58, // VP8X
    0x0A, 0x00, 0x00, 0x00, // chunk size
    0x00, 0x00, 0x00, 0x00, // flags and reserved
    0x40, 0x01, 0x00, // width minus 1: 320
    0xF0, 0x00, 0x00, // height minus 1: 240
  ]);
}

Uint8List _bmpHeader() {
  return Uint8List.fromList([
    0x42, 0x4D, // BM
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00,
    0x40, 0x01, 0x00, 0x00, // width: 320
    0xF0, 0x00, 0x00, 0x00, // height: 240
  ]);
}

Uint8List _icoHeader() {
  return Uint8List.fromList([
    0x00, 0x00, // reserved
    0x01, 0x00, // icon type
    0x01, 0x00, // image count
    0x40, // width: 64
    0x20, // height: 32
  ]);
}
