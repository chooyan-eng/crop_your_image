// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:crop_your_image/src/logic/cropper/errors.dart';
import 'package:crop_your_image/src/logic/parser/image_header_parser.dart';

/// An implementation of [ImageCropper] using browser-native canvas APIs.
///
/// Flutter web runs [compute] on the browser UI thread, so doing the default
/// Dart-side pixel decode/crop there can block rendering for large images.
/// This cropper lets the browser decode the image and perform the crop on a
/// canvas instead.
class BrowserCanvasImageCropper extends ImageCropper<Uint8List> {
  const BrowserCanvasImageCropper();

  @override
  Future<Uint8List> call({
    required Uint8List original,
    required Offset topLeft,
    required Offset bottomRight,
    ImageFormat? outputFormat,
    ImageShape shape = ImageShape.rectangle,
  }) async {
    final error = rectValidator(original, topLeft, bottomRight);
    if (error != null) {
      throw error;
    }

    final sourceFormat = imageHeaderFormatDetector(original);
    final sourceMimeType = _mimeTypeForSourceFormat(sourceFormat);
    final outputMimeType = _mimeTypeForOutputFormat(
      outputFormat ?? sourceFormat,
      shape,
    );
    final bounds = switch (shape) {
      ImageShape.rectangle => _rectBounds(topLeft, bottomRight),
      ImageShape.circle => _circleBounds(topLeft, bottomRight),
    };

    return _cropWithBrowserCanvas(
      original,
      sourceLeft: bounds.left,
      sourceTop: bounds.top,
      sourceWidth: bounds.width,
      sourceHeight: bounds.height,
      sourceMimeType: sourceMimeType,
      outputMimeType: outputMimeType,
      shape: shape,
    );
  }

  @override
  RectValidator<Uint8List> get rectValidator => _defaultRectValidator;

  @override
  RectCropper<Uint8List> get rectCropper =>
      throw UnsupportedError('BrowserCanvasImageCropper uses async call().');

  @override
  CircleCropper<Uint8List> get circleCropper =>
      throw UnsupportedError('BrowserCanvasImageCropper uses async call().');
}

({int left, int top, int width, int height}) _rectBounds(
  Offset topLeft,
  Offset bottomRight,
) {
  return (
    left: topLeft.dx.toInt(),
    top: topLeft.dy.toInt(),
    width: math.max(1, (bottomRight.dx - topLeft.dx).toInt()),
    height: math.max(1, (bottomRight.dy - topLeft.dy).toInt()),
  );
}

({int left, int top, int width, int height}) _circleBounds(
  Offset topLeft,
  Offset bottomRight,
) {
  final width = bottomRight.dx - topLeft.dx;
  final height = bottomRight.dy - topLeft.dy;
  final radius = math.max(1, (math.min(width, height) / 2).toInt());
  final center = Offset(
    topLeft.dx + width / 2,
    topLeft.dy + height / 2,
  );
  return (
    left: center.dx.toInt() - radius,
    top: center.dy.toInt() - radius,
    width: radius * 2,
    height: radius * 2,
  );
}

Exception? _defaultRectValidator(
  Uint8List original,
  Offset topLeft,
  Offset bottomRight,
) {
  final sourceSize = readImageHeaderSize(
    original,
    imageHeaderFormatDetector(original),
  );

  if (topLeft.dx.toInt().isNegative ||
      topLeft.dy.toInt().isNegative ||
      bottomRight.dx.toInt().isNegative ||
      bottomRight.dy.toInt().isNegative ||
      topLeft.dx.toInt() > sourceSize.width ||
      topLeft.dy.toInt() > sourceSize.height ||
      bottomRight.dx.toInt() > sourceSize.width ||
      bottomRight.dy.toInt() > sourceSize.height) {
    return InvalidRectException(topLeft: topLeft, bottomRight: bottomRight);
  }
  if (topLeft.dx > bottomRight.dx || topLeft.dy > bottomRight.dy) {
    return NegativeSizeException(topLeft: topLeft, bottomRight: bottomRight);
  }
  return null;
}

Future<Uint8List> _cropWithBrowserCanvas(
  Uint8List bytes, {
  required int sourceLeft,
  required int sourceTop,
  required int sourceWidth,
  required int sourceHeight,
  required String sourceMimeType,
  required String outputMimeType,
  required ImageShape shape,
}) async {
  final sourceUrl = html.Url.createObjectUrlFromBlob(
    html.Blob([bytes], sourceMimeType),
  );

  try {
    final image = html.ImageElement(src: sourceUrl);
    await image.decode();

    try {
      return await _cropWithOffscreenCanvas(
        image,
        sourceLeft: sourceLeft,
        sourceTop: sourceTop,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        outputMimeType: outputMimeType,
        shape: shape,
      );
    } catch (_) {
      return _cropWithCanvasElement(
        image,
        sourceLeft: sourceLeft,
        sourceTop: sourceTop,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        outputMimeType: outputMimeType,
        shape: shape,
      );
    }
  } finally {
    html.Url.revokeObjectUrl(sourceUrl);
  }
}

Future<Uint8List> _cropWithOffscreenCanvas(
  html.ImageElement image, {
  required int sourceLeft,
  required int sourceTop,
  required int sourceWidth,
  required int sourceHeight,
  required String outputMimeType,
  required ImageShape shape,
}) async {
  final canvas = html.OffscreenCanvas(sourceWidth, sourceHeight);
  final context =
      canvas.getContext('2d') as html.OffscreenCanvasRenderingContext2D;
  _drawCrop(
    context,
    image,
    sourceLeft: sourceLeft,
    sourceTop: sourceTop,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    shape: shape,
  );
  final blob = await canvas.convertToBlob({
    'type': outputMimeType,
    if (_supportsQuality(outputMimeType)) 'quality': 0.92,
  });
  return _blobToBytes(blob);
}

Future<Uint8List> _cropWithCanvasElement(
  html.ImageElement image, {
  required int sourceLeft,
  required int sourceTop,
  required int sourceWidth,
  required int sourceHeight,
  required String outputMimeType,
  required ImageShape shape,
}) async {
  final canvas = html.CanvasElement(width: sourceWidth, height: sourceHeight);
  _drawCrop(
    canvas.context2D,
    image,
    sourceLeft: sourceLeft,
    sourceTop: sourceTop,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    shape: shape,
  );
  final blob = await canvas.toBlob(
    outputMimeType,
    _supportsQuality(outputMimeType) ? 0.92 : null,
  );
  return _blobToBytes(blob);
}

void _drawCrop(
  dynamic context,
  html.ImageElement image, {
  required int sourceLeft,
  required int sourceTop,
  required int sourceWidth,
  required int sourceHeight,
  required ImageShape shape,
}) {
  context.imageSmoothingEnabled = true;
  context.save();
  if (shape == ImageShape.circle) {
    final radius = math.min(sourceWidth, sourceHeight) / 2;
    context.beginPath();
    context.arc(radius, radius, radius, 0, math.pi * 2, false);
    context.clip();
  }
  context.drawImage(
    image,
    sourceLeft,
    sourceTop,
    sourceWidth,
    sourceHeight,
    0,
    0,
    sourceWidth,
    sourceHeight,
  );
  context.restore();
}

Future<Uint8List> _blobToBytes(html.Blob blob) async {
  final reader = html.FileReader();
  final loaded = reader.onLoad.first.then((_) => true);
  final failed = reader.onError.first.then((_) => false);

  reader.readAsArrayBuffer(blob);
  if (!await Future.any(<Future<bool>>[loaded, failed])) {
    throw StateError('Could not read cropped image data.');
  }

  final result = reader.result;
  if (result is ByteBuffer) {
    return result.asUint8List();
  }
  if (result is Uint8List) {
    return result;
  }
  if (result is List<int>) {
    return Uint8List.fromList(result);
  }
  throw StateError('Cropped image had an unsupported byte format.');
}

String _mimeTypeForSourceFormat(ImageFormat format) {
  return switch (format) {
    ImageFormat.bmp => 'image/bmp',
    ImageFormat.ico => 'image/x-icon',
    ImageFormat.jpeg => 'image/jpeg',
    ImageFormat.webp => 'image/webp',
    ImageFormat.png => 'image/png',
  };
}

String _mimeTypeForOutputFormat(ImageFormat format, ImageShape shape) {
  if (shape == ImageShape.circle) {
    return 'image/png';
  }
  return switch (format) {
    ImageFormat.jpeg => 'image/jpeg',
    ImageFormat.webp => 'image/webp',
    _ => 'image/png',
  };
}

bool _supportsQuality(String mimeType) {
  return mimeType == 'image/jpeg' || mimeType == 'image/webp';
}
