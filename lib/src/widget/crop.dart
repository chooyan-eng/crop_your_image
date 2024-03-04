import 'dart:async';
import 'dart:math';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:crop_your_image/src/logic/cropper/crop_result.dart';
import 'package:crop_your_image/src/logic/shape.dart';
import 'package:crop_your_image/src/widget/calculator.dart';
import 'package:crop_your_image/src/widget/circle_crop_area_clipper.dart';
import 'package:crop_your_image/src/widget/constants.dart';
import 'package:crop_your_image/src/widget/rect_crop_area_clipper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

typedef ViewportBasedRect = Rect;
typedef ImageBasedRect = Rect;

typedef WillUpdateScale = bool Function(double newScale);
typedef CornerDotBuilder = Widget Function(
    double size, EdgeAlignment edgeAlignment);

typedef CroppingRectBuilder = ViewportBasedRect Function(
  ViewportBasedRect viewportRect,
  ViewportBasedRect imageRect,
);

enum CropStatus { nothing, loading, ready, cropping }

/// Widget for the entry point of crop_your_image.
class Crop extends StatelessWidget {
  /// original image data
  final Uint8List image;

  /// callback when cropping completed
  final ValueChanged<CropResult> onCropped;

  /// fixed aspect ratio of cropping rect.
  /// null, by default, means no fixed aspect ratio.
  final double? aspectRatio;

  /// initial size of cropping rect.
  /// Set double value less than 1.0.
  /// if initialSize is 1.0 (or null),
  /// cropping area would expand as much as possible.
  final double? initialSize;

  /// Builder for initial [ViewportBasedRect] of cropping rect.
  /// Builder is called when calculating initial cropping rect
  /// with passing [ViewportBasedRect] of viewport and image.
  final CroppingRectBuilder? initialRectBuilder;

  /// Initial [ImageBasedRect] of cropping rect, called "area" in this package.
  ///
  /// Note that [ImageBasedRect] is [Rect] based on original [image] data, not screen.
  ///
  /// e.g. If the original image size is 1280x1024,
  /// giving [Rect.fromLTWH(240, 212, 800, 600)] as [initialArea] would
  /// result in covering exact center of the image with 800x600 image size
  /// regardless of the size of viewport.
  ///
  /// If [initialArea] is given, [initialSize] is ignored.
  /// On the other hand, [aspectRatio] is still enabled although
  /// [initialArea] is given and the initial shape of cropping rect looks ignoring [aspectRatio].
  /// Once user moves cropping rect with their hand,
  /// the shape of cropping area is re-calculated depending on [aspectRatio].
  final ImageBasedRect? initialArea;

  /// flag if cropping image with circle shape.
  /// As oval shape is not supported, [aspectRatio] is fixed to 1 if [withCircleUi] is true.
  final bool withCircleUi;

  /// conroller for control crop actions
  final CropController? controller;

  /// Callback called when cropping rect changes for any reasons.
  final ValueChanged<ViewportBasedRect>? onMoved;

  /// Callback called when status of Crop widget is changed.
  ///
  /// note: Currently, the very first callback is [CropStatus.ready]
  /// which is called after loading [image] data for the first time.
  final ValueChanged<CropStatus>? onStatusChanged;

  /// [Color] of the mask widget which is placed over the cropping editor.
  final Color? maskColor;

  /// [Color] of the base color of the cropping editor.
  final Color baseColor;

  /// Corner radius of cropping rect
  final double radius;

  /// Builder function for corner dot widgets.
  /// [CornerDotBuilder] passes [size] which indicates a desired size of each dots
  /// and [EdgeAlignment] which indicates the position of each dot.
  /// If you want default dot widget with different color, [DotControl] is available.
  final CornerDotBuilder? cornerDotBuilder;

  /// [Clip] configuration for crop editor, especially corner dots.
  /// [Clip.hardEdge] by default.
  final Clip clipBehavior;

  /// [Widget] for showing preparing for image is in progress.
  /// [SizedBox.shrink()] is used by default.
  final Widget progressIndicator;

  /// If [true], the cropping editor is changed to _interactive_ mode
  /// and users can zoom and pan the image.
  /// [false] by default.
  final bool interactive;

  /// If [fixCropRect] and [interactive] are both [true], cropping rect is fixed and can't be moved.
  /// [false] by default.
  final bool fixCropRect;

  /// Function called before scaling image.
  /// Note that this function is called multiple times during user tries to scale image.
  /// If this function returns [false], scaling is canceled.
  final WillUpdateScale? willUpdateScale;

  /// (for Web) Sets the mouse-wheel zoom sensitivity for web applications.
  final double scrollZoomSensitivity;

  /// (Advanced) Injected logic for cropping image.
  final ImageCropper imageCropper;

  /// (Advanced) Injected logic for detecting image format.
  final FormatDetector? formatDetector;

  /// (Advanced) Injected logic for parsing image detail.
  final ImageParser imageParser;

  Crop({
    super.key,
    required this.image,
    required this.onCropped,
    this.aspectRatio,
    this.initialSize,
    this.initialRectBuilder,
    this.initialArea,
    this.withCircleUi = false,
    this.controller,
    this.onMoved,
    this.onStatusChanged,
    this.maskColor,
    this.baseColor = Colors.white,
    this.radius = 0,
    this.cornerDotBuilder,
    this.clipBehavior = Clip.hardEdge,
    this.fixCropRect = false,
    this.progressIndicator = const SizedBox.shrink(),
    this.interactive = false,
    this.willUpdateScale,
    this.formatDetector = defaultFormatDetector,
    this.imageCropper = defaultImageCropper,
    ImageParser? imageParser,
    this.scrollZoomSensitivity = 0.05,
  })  : assert((initialSize ?? 1.0) <= 1.0,
            'initialSize must be less than 1.0, or null meaning not specified.'),
        this.imageParser = imageParser ?? defaultImageParser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (c, constraints) {
        final newData = MediaQuery.of(c).copyWith(
          size: constraints.biggest,
        );
        return MediaQuery(
          data: newData,
          child: _CropEditor(
            key: key,
            image: image,
            onCropped: onCropped,
            aspectRatio: aspectRatio,
            initialSize: initialSize,
            initialRectBuilder: initialRectBuilder,
            initialArea: initialArea,
            withCircleUi: withCircleUi,
            controller: controller,
            onMoved: onMoved,
            onStatusChanged: onStatusChanged,
            maskColor: maskColor,
            baseColor: baseColor,
            radius: radius,
            cornerDotBuilder: cornerDotBuilder,
            clipBehavior: clipBehavior,
            fixCropRect: fixCropRect,
            progressIndicator: progressIndicator,
            interactive: interactive,
            willUpdateScale: willUpdateScale,
            scrollZoomSensitivity: scrollZoomSensitivity,
            imageCropper: imageCropper,
            formatDetector: formatDetector,
            imageParser: imageParser,
          ),
        );
      },
    );
  }
}

class _CropEditor extends StatefulWidget {
  final Uint8List image;
  final ValueChanged<CropResult> onCropped;
  final double? aspectRatio;
  final double? initialSize;
  final CroppingRectBuilder? initialRectBuilder;
  final ImageBasedRect? initialArea;
  final bool withCircleUi;
  final CropController? controller;
  final ValueChanged<ViewportBasedRect>? onMoved;
  final ValueChanged<CropStatus>? onStatusChanged;
  final Color? maskColor;
  final Color baseColor;
  final double radius;
  final CornerDotBuilder? cornerDotBuilder;
  final Clip clipBehavior;
  final bool fixCropRect;
  final Widget progressIndicator;
  final bool interactive;
  final WillUpdateScale? willUpdateScale;
  final ImageCropper imageCropper;
  final FormatDetector? formatDetector;
  final ImageParser imageParser;
  final double scrollZoomSensitivity;

  const _CropEditor({
    super.key,
    required this.image,
    required this.onCropped,
    required this.aspectRatio,
    required this.initialSize,
    required this.initialRectBuilder,
    required this.initialArea,
    this.withCircleUi = false,
    required this.controller,
    required this.onMoved,
    required this.onStatusChanged,
    required this.maskColor,
    required this.baseColor,
    required this.radius,
    required this.cornerDotBuilder,
    required this.clipBehavior,
    required this.fixCropRect,
    required this.progressIndicator,
    required this.interactive,
    required this.willUpdateScale,
    required this.imageCropper,
    required this.formatDetector,
    required this.imageParser,
    required this.scrollZoomSensitivity,
  });

  @override
  _CropEditorState createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor> {
  late CropController _cropController;

  /// image with detail info parsed with [widget.imageParser]
  ImageDetail? _parsedImageDetail;

  /// [Size] of viewport
  /// This is equivalent to [MediaQuery.of(context).size]
  late Size _viewportSize;

  /// [ViewportBasedRect] of displaying image
  /// Note that this is not the actual [Size] of the image.
  late ViewportBasedRect _imageRect;

  /// for cropping editor
  double? _aspectRatio;
  bool _withCircleUi = false;
  bool _isFitVertically = false;

  /// [ViewportBasedRect] of cropping area
  /// The result of cropping is based on this [_cropRect].
  late ViewportBasedRect _cropRect;
  set cropRect(ViewportBasedRect newRect) {
    setState(() => _cropRect = newRect);
    widget.onMoved?.call(_cropRect);
  }

  bool get _isImageLoading => _lastComputed != null;

  Calculator get calculator => _isFitVertically
      ? const VerticalCalculator()
      : const HorizontalCalculator();

  ImageFormat? _detectedFormat;

  @override
  void initState() {
    super.initState();

    _withCircleUi = widget.withCircleUi;

    // prepare for controller
    _cropController = widget.controller ?? CropController();
    _cropController.delegate = CropControllerDelegate()
      ..onCrop = _crop
      ..onChangeAspectRatio = (aspectRatio) {
        _resizeWith(aspectRatio, null);
      }
      ..onChangeWithCircleUi = (withCircleUi) {
        _withCircleUi = withCircleUi;
        _resizeWith(null, null);
      }
      ..onImageChanged = _resetImage
      ..onChangeCropRect = (newCropRect) {
        cropRect = calculator.correct(newCropRect, _imageRect);
      }
      ..onChangeArea = (newArea) {
        _resizeWith(_aspectRatio, newArea);
      };
  }

  @override
  void didChangeDependencies() {
    _viewportSize = MediaQuery.of(context).size;

    _parseImageWith(
      parser: widget.imageParser,
      formatDetector: widget.formatDetector,
      image: widget.image,
    );
    super.didChangeDependencies();
  }

  /// reset image to be cropped
  void _resetImage(Uint8List targetImage) {
    widget.onStatusChanged?.call(CropStatus.loading);
    _parseImageWith(
      parser: widget.imageParser,
      formatDetector: widget.formatDetector,
      image: targetImage,
    );
  }

  /// temporary field to detect last computed.
  ImageParser? _lastParser;
  FormatDetector? _lastFormatDetector;
  Uint8List? _lastImage;
  Future<ImageDetail?>? _lastComputed;

  void _parseImageWith({
    required ImageParser parser,
    required FormatDetector? formatDetector,
    required Uint8List image,
  }) {
    if (_lastParser == parser &&
        _lastImage == image &&
        _lastFormatDetector == formatDetector) {
      // no change
      return;
    }

    _lastParser = parser;
    _lastFormatDetector = formatDetector;
    _lastImage = image;

    final format = formatDetector?.call(image);
    final future = compute(
      _parseFunc,
      [widget.imageParser, format, image],
    );
    _lastComputed = future;
    future.then((parsed) {
      // check if Crop is still alive
      if (!mounted) {
        return;
      }

      // if _parseImageWith() is called again before future completed,
      // just skip and the last future is used.
      if (_lastComputed == future) {
        setState(() {
          _parsedImageDetail = parsed;
          _lastComputed = null;
          _detectedFormat = format;
        });
        _resetCropRect();
        widget.onStatusChanged?.call(CropStatus.ready);
      }
    });
  }

  /// reset [ViewportBasedRect] of crop rect with current state
  void _resetCropRect() {
    final screenSize = _viewportSize;

    final imageAspectRatio =
        _parsedImageDetail!.width / _parsedImageDetail!.height;
    _isFitVertically = imageAspectRatio < screenSize.aspectRatio;

    _imageRect = calculator.imageRect(screenSize, imageAspectRatio);

    if (widget.initialRectBuilder != null) {
      cropRect = widget.initialRectBuilder!(
        Rect.fromLTWH(
          0,
          0,
          screenSize.width,
          screenSize.height,
        ),
        _imageRect,
      );
    } else {
      _resizeWith(widget.aspectRatio, widget.initialArea);
    }

    if (widget.interactive) {
      final initialScale = calculator.scaleToCover(screenSize, _imageRect);
      _applyScale(initialScale);
    }
  }

  /// resize crop rect with given aspect ratio and area.
  void _resizeWith(double? aspectRatio, ImageBasedRect? area) {
    _aspectRatio = _withCircleUi ? 1 : aspectRatio;

    if (area == null) {
      cropRect = calculator.initialCropRect(
        _viewportSize,
        _imageRect,
        _aspectRatio ?? 1,
        widget.initialSize ?? 1,
      );
    } else {
      // calculate how smaller the viewport is than the image
      final screenSizeRatio = calculator.screenSizeRatio(
        _parsedImageDetail!,
        _viewportSize,
      );
      cropRect = Rect.fromLTWH(
        _imageRect.left + area.left / screenSizeRatio,
        _imageRect.top + area.top / screenSizeRatio,
        area.width / screenSizeRatio,
        area.height / screenSizeRatio,
      );
    }
  }

  /// crop given image with given area.
  Future<void> _crop(bool withCircleShape) async {
    assert(_parsedImageDetail != null);

    final screenSizeRatio = calculator.screenSizeRatio(
      _parsedImageDetail!,
      _viewportSize,
    );

    widget.onStatusChanged?.call(CropStatus.cropping);

    // use compute() not to block UI update
    late CropResult cropResult;
    try {
      final image = await compute(
        _cropFunc,
        [
          widget.imageCropper,
          _parsedImageDetail!.image,
          Rect.fromLTWH(
            (_cropRect.left - _imageRect.left) * screenSizeRatio / _scale,
            (_cropRect.top - _imageRect.top) * screenSizeRatio / _scale,
            _cropRect.width * screenSizeRatio / _scale,
            _cropRect.height * screenSizeRatio / _scale,
          ),
          withCircleShape,
          _detectedFormat,
        ],
      );
      cropResult = CropResult(image, null, null);
    } catch(e, trace) {
      cropResult = CropResult(null, e, trace);
    }

    widget.onCropped(cropResult);
    widget.onStatusChanged?.call(CropStatus.ready);
  }

  // for zooming
  double _scale = 1.0;
  double _baseScale = 1.0;

  void _startScale(ScaleStartDetails detail) {
    _baseScale = _scale;
  }

  void _updateScale(ScaleUpdateDetails detail) {
    // move
    var movedLeft = _imageRect.left + detail.focalPointDelta.dx;
    if (movedLeft + _imageRect.width < _cropRect.right) {
      movedLeft = _cropRect.right - _imageRect.width;
    }

    var movedTop = _imageRect.top + detail.focalPointDelta.dy;
    if (movedTop + _imageRect.height < _cropRect.bottom) {
      movedTop = _cropRect.bottom - _imageRect.height;
    }
    setState(() {
      _imageRect = ViewportBasedRect.fromLTWH(
        min(_cropRect.left, movedLeft),
        min(_cropRect.top, movedTop),
        _imageRect.width,
        _imageRect.height,
      );
    });

    _applyScale(
      _baseScale * detail.scale,
      focalPoint: detail.localFocalPoint,
    );
  }

  void _applyScale(
    double nextScale, {
    Offset? focalPoint,
  }) {
    final allowScale = widget.willUpdateScale?.call(nextScale) ?? true;
    if (!allowScale) {
      return;
    }

    late double baseHeight;
    late double baseWidth;
    final ratio = _parsedImageDetail!.height / _parsedImageDetail!.width;

    if (_isFitVertically) {
      baseHeight = _viewportSize.height;
      baseWidth = baseHeight / ratio;
    } else {
      baseWidth = _viewportSize.width;
      baseHeight = baseWidth * ratio;
    }

    // clamp the scale
    nextScale = max(
      nextScale,
      max(_cropRect.width / baseWidth, _cropRect.height / baseHeight),
    );

    if (_scale == nextScale) {
      return;
    }

    // width
    final newWidth = baseWidth * nextScale;
    final horizontalFocalPointBias = focalPoint == null
        ? 0.5
        : (focalPoint.dx - _imageRect.left) / _imageRect.width;
    final leftPositionDelta =
        (newWidth - _imageRect.width) * horizontalFocalPointBias;

    // height
    final newHeight = baseHeight * nextScale;
    final verticalFocalPointBias = focalPoint == null
        ? 0.5
        : (focalPoint.dy - _imageRect.top) / _imageRect.height;
    final topPositionDelta =
        (newHeight - _imageRect.height) * verticalFocalPointBias;

    // position
    final newLeft = max(
        min(_cropRect.left, _imageRect.left - leftPositionDelta),
        _cropRect.right - newWidth);
    final newTop = max(min(_cropRect.top, _imageRect.top - topPositionDelta),
        _cropRect.bottom - newHeight);

    // apply
    setState(() {
      _imageRect = Rect.fromLTRB(
        newLeft,
        newTop,
        newLeft + newWidth,
        newTop + newHeight,
      );
      _scale = nextScale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isImageLoading
        ? Center(child: widget.progressIndicator)
        : Stack(
            clipBehavior: widget.clipBehavior,
            children: [
              Listener(
                onPointerSignal: (signal) {
                  if (signal is PointerScrollEvent) {
                    if (signal.scrollDelta.dy > 0) {
                      _applyScale(
                        _scale - widget.scrollZoomSensitivity,
                        focalPoint: signal.localPosition,
                      );
                    } else if (signal.scrollDelta.dy < 0) {
                      _applyScale(
                        _scale + widget.scrollZoomSensitivity,
                        focalPoint: signal.localPosition,
                      );
                    }
                    //print(_scale);
                  }
                },
                child: GestureDetector(
                  onScaleStart: widget.interactive ? _startScale : null,
                  onScaleUpdate: widget.interactive ? _updateScale : null,
                  child: Container(
                    color: widget.baseColor,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        Positioned(
                          left: _imageRect.left,
                          top: _imageRect.top,
                          child: Image.memory(
                            widget.image,
                            width: _isFitVertically
                                ? null
                                : MediaQuery.of(context).size.width * _scale,
                            height: _isFitVertically
                                ? MediaQuery.of(context).size.height * _scale
                                : null,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: ClipPath(
                  clipper: _withCircleUi
                      ? CircleCropAreaClipper(_cropRect)
                      : CropAreaClipper(_cropRect, widget.radius),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: widget.maskColor ?? Colors.black.withAlpha(100),
                  ),
                ),
              ),
              if (!widget.interactive && !widget.fixCropRect)
                Positioned(
                  left: _cropRect.left,
                  top: _cropRect.top,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      cropRect = calculator.moveRect(
                        _cropRect,
                        details.delta.dx,
                        details.delta.dy,
                        _imageRect,
                      );
                    },
                    child: Container(
                      width: _cropRect.width,
                      height: _cropRect.height,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              Positioned(
                left: _cropRect.left - (dotTotalSize / 2),
                top: _cropRect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          cropRect = calculator.moveTopLeft(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.topLeft) ??
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _cropRect.right - (dotTotalSize / 2),
                top: _cropRect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          cropRect = calculator.moveTopRight(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.topRight) ??
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _cropRect.left - (dotTotalSize / 2),
                top: _cropRect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          cropRect = calculator.moveBottomLeft(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.bottomLeft) ??
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _cropRect.right - (dotTotalSize / 2),
                top: _cropRect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) {
                          cropRect = calculator.moveBottomRight(
                            _cropRect,
                            details.delta.dx,
                            details.delta.dy,
                            _imageRect,
                            _aspectRatio,
                          );
                        },
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.bottomRight) ??
                      const DotControl(),
                ),
              ),
            ],
          );
  }
}

/// top-level function for [compute]
/// calls [ImageParser.call] with given arguments
ImageDetail _parseFunc(List<dynamic> args) {
  final parser = args[0] as ImageParser;
  final format = args[1] as ImageFormat?;
  return parser(args[2] as Uint8List, inputFormat: format);
}

/// top-level function for [compute]
/// calls [ImageCropper.call] with given arguments
FutureOr<Uint8List> _cropFunc(List<dynamic> args) {
  final cropper = args[0] as ImageCropper;
  final originalImage = args[1];
  final rect = args[2] as Rect;
  final withCircleShape = args[3] as bool;

  // TODO(chooyan-eng): currently always PNG
  // final outputFormat = args[4] as ImageFormat?;

  return cropper.call(
    original: originalImage,
    topLeft: Offset(rect.left, rect.top),
    bottomRight: Offset(rect.right, rect.bottom),
    shape: withCircleShape ? ImageShape.circle : ImageShape.rectangle,
  );
}
