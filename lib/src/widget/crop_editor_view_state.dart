import 'dart:math';

import 'package:crop_your_image/src/widget/calculator.dart';
import 'package:flutter/widgets.dart';
import 'package:crop_your_image/crop_your_image.dart';

/// state management class for _CropEditor
/// see the link below for more details
/// https://github.com/chooyan-eng/complex_local_state_management/blob/main/docs/local_state.md
interface class CropEditorViewState {
  final Size viewportSize;
  final bool withCircleUi;
  final double? aspectRatio;

  late final bool isReady;

  CropEditorViewState({
    required this.viewportSize,
    required this.withCircleUi,
    required this.aspectRatio,
  });
}

/// implementation of [CropEditorViewState] for preparing state
class PreparingCropEditorViewState extends CropEditorViewState {
  PreparingCropEditorViewState({
    required super.viewportSize,
    required super.withCircleUi,
    required super.aspectRatio,
  });

  @override
  bool isReady = false;

  ReadyCropEditorViewState prepared(Size imageSize) {
    return ReadyCropEditorViewState.prepared(
      imageSize,
      viewportSize: viewportSize,
      withCircleUi: withCircleUi,
      aspectRatio: aspectRatio,
      scale: 1.0,
    );
  }
}

/// implementation of [CropEditorViewState] for ready state
class ReadyCropEditorViewState extends CropEditorViewState {
  final Size imageSize;
  final ViewportBasedRect cropRect;
  final ViewportBasedRect imageRect;
  final double scale;
  final Offset offset;

  factory ReadyCropEditorViewState.prepared(
    Size imageSize, {
    required Size viewportSize,
    required double scale,
    required double? aspectRatio,
    required bool withCircleUi,
  }) {
    final isFitVertically = imageSize.aspectRatio < viewportSize.aspectRatio;
    final calculator =
        isFitVertically ? VerticalCalculator() : HorizontalCalculator();

    return ReadyCropEditorViewState(
      viewportSize: viewportSize,
      imageSize: imageSize,
      imageRect: calculator.imageRect(viewportSize, imageSize.aspectRatio),
      cropRect: ViewportBasedRect.zero,
      scale: scale,
      aspectRatio: aspectRatio,
      withCircleUi: withCircleUi,
    );
  }

  ReadyCropEditorViewState({
    required super.viewportSize,
    required this.imageSize,
    required this.imageRect,
    required this.cropRect,
    required this.scale,
    this.offset = Offset.zero,
    required super.aspectRatio,
    required super.withCircleUi,
  });

  @override
  bool isReady = true;

  late final isFitVertically = imageSize.aspectRatio < viewportSize.aspectRatio;

  late final calculator =
      isFitVertically ? VerticalCalculator() : HorizontalCalculator();

  late final screenSizeRatio = calculator.screenSizeRatio(
    imageSize,
    viewportSize,
  );

  late final rectToCrop = ImageBasedRect.fromLTWH(
    (cropRect.left - imageRect.left) * screenSizeRatio / scale,
    (cropRect.top - imageRect.top) * screenSizeRatio / scale,
    cropRect.width * screenSizeRatio / scale,
    cropRect.height * screenSizeRatio / scale,
  );

  late final imageBaseRect = Rect.fromLTWH(
    (cropRect.left - imageRect.left) * screenSizeRatio / scale,
    (cropRect.top - imageRect.top) * screenSizeRatio / scale,
    cropRect.width * screenSizeRatio / scale,
    cropRect.height * screenSizeRatio / scale,
  );

  late final scaleToCover = calculator.scaleToCover(viewportSize, imageRect);

  ReadyCropEditorViewState imageSizeDetected(Size size) {
    return copyWith(imageSize: size);
  }

  ReadyCropEditorViewState resetCropRect() {
    return copyWith(
      imageRect: calculator.imageRect(viewportSize, imageSize.aspectRatio),
    );
  }

  ReadyCropEditorViewState correct(ViewportBasedRect newCropRect) {
    return copyWith(cropRect: calculator.correct(newCropRect, imageRect));
  }

  ReadyCropEditorViewState cropRectInitialized({
    double? initialSize,
    double? aspectRatio,
    double? initialAspectRatio,
  }) {
    final effectiveAspectRatio =
        withCircleUi ? 1.0 : aspectRatio ?? initialAspectRatio ?? 1.0;
    return copyWith(
      cropRect: calculator.initialCropRect(
        viewportSize,
        imageRect,
        effectiveAspectRatio,
        initialSize ?? 1,
      ),
    );
  }

  ReadyCropEditorViewState cropRectWith(ImageBasedRect area) {
    return copyWith(
      cropRect: Rect.fromLTWH(
        imageRect.left + area.left / screenSizeRatio,
        imageRect.top + area.top / screenSizeRatio,
        area.width / screenSizeRatio,
        area.height / screenSizeRatio,
      ),
    );
  }

  // Methods for state updates
  ReadyCropEditorViewState moveRect(Offset delta) {
    final newCropRect = calculator.moveRect(
      cropRect,
      delta.dx,
      delta.dy,
      imageRect,
    );
    return copyWith(cropRect: newCropRect);
  }

  ReadyCropEditorViewState moveTopLeft(Offset delta) {
    final newCropRect = calculator.moveTopLeft(
      cropRect,
      delta.dx,
      delta.dy,
      imageRect,
      aspectRatio,
    );
    return copyWith(cropRect: newCropRect);
  }

  ReadyCropEditorViewState moveTopRight(Offset delta) {
    final newCropRect = calculator.moveTopRight(
      cropRect,
      delta.dx,
      delta.dy,
      imageRect,
      aspectRatio,
    );
    return copyWith(cropRect: newCropRect);
  }

  ReadyCropEditorViewState moveBottomLeft(Offset delta) {
    final newCropRect = calculator.moveBottomLeft(
      cropRect,
      delta.dx,
      delta.dy,
      imageRect,
      aspectRatio,
    );
    return copyWith(cropRect: newCropRect);
  }

  ReadyCropEditorViewState moveBottomRight(Offset delta) {
    final newCropRect = calculator.moveBottomRight(
      cropRect,
      delta.dx,
      delta.dy,
      imageRect,
      aspectRatio,
    );
    return copyWith(cropRect: newCropRect);
  }

  ReadyCropEditorViewState offsetUpdated(Offset delta) {
    var movedLeft = imageRect.left + delta.dx;
    if (movedLeft + imageRect.width < cropRect.right) {
      movedLeft = cropRect.right - imageRect.width;
    }

    var movedTop = imageRect.top + delta.dy;
    if (movedTop + imageRect.height < cropRect.bottom) {
      movedTop = cropRect.bottom - imageRect.height;
    }

    return copyWith(
      imageRect: ViewportBasedRect.fromLTWH(
        min(cropRect.left, movedLeft),
        min(cropRect.top, movedTop),
        imageRect.width,
        imageRect.height,
      ),
    );
  }

  ReadyCropEditorViewState scaleUpdated(
    double nextScale, {
    Offset? focalPoint,
  }) {
    final baseSize = isFitVertically
        ? Size(
            viewportSize.height * imageSize.aspectRatio,
            viewportSize.height,
          )
        : Size(
            viewportSize.width,
            viewportSize.width / imageSize.aspectRatio,
          );

    // clamp the scale
    nextScale = max(
      nextScale,
      max(cropRect.width / baseSize.width, cropRect.height / baseSize.height),
    );

    // no change
    if (scale == nextScale) {
      return this;
    }

    // width
    final newWidth = baseSize.width * nextScale;
    final horizontalFocalPointBias = focalPoint == null
        ? 0.5
        : (focalPoint.dx - imageRect.left) / imageRect.width;
    final leftPositionDelta =
        (newWidth - imageRect.width) * horizontalFocalPointBias;

    // height
    final newHeight = baseSize.height * nextScale;
    final verticalFocalPointBias = focalPoint == null
        ? 0.5
        : (focalPoint.dy - imageRect.top) / imageRect.height;
    final topPositionDelta =
        (newHeight - imageRect.height) * verticalFocalPointBias;

    // position
    final newLeft = max(min(cropRect.left, imageRect.left - leftPositionDelta),
        cropRect.right - newWidth);
    final newTop = max(min(cropRect.top, imageRect.top - topPositionDelta),
        cropRect.bottom - newHeight);

    return copyWith(
      scale: nextScale,
      imageRect: ViewportBasedRect.fromLTWH(
        newLeft,
        newTop,
        newWidth,
        newHeight,
      ),
    );
  }

  ReadyCropEditorViewState copyWith({
    Size? viewportSize,
    Size? imageSize,
    ViewportBasedRect? imageRect,
    ViewportBasedRect? cropRect,
    double? scale,
    Offset? offset,
    double? aspectRatio,
    bool? withCircleUi,
  }) {
    return ReadyCropEditorViewState(
      viewportSize: viewportSize ?? this.viewportSize,
      imageSize: imageSize ?? this.imageSize,
      imageRect: imageRect ?? this.imageRect,
      cropRect: cropRect ?? this.cropRect,
      scale: scale ?? this.scale,
      offset: offset ?? this.offset,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      withCircleUi: withCircleUi ?? this.withCircleUi,
    );
  }
}
