import 'dart:async';
import 'dart:math';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:crop_your_image/src/logic/shape.dart';
import 'package:crop_your_image/src/widget/calculator.dart';
import 'package:crop_your_image/src/widget/circle_crop_area_clipper.dart';
import 'package:crop_your_image/src/widget/constants.dart';
import 'package:crop_your_image/src/widget/rect_crop_area_clipper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ViewportBasedRect = Rect;

typedef AllowScale = bool Function(double newScale);
typedef CornerDotBuilder = Widget Function(
    double size, EdgeAlignment edgeAlignment);

typedef CroppingAreaBuilder = Rect Function(Rect imageRect);

enum CropStatus { nothing, loading, ready, cropping }

/// Widget for the entry point of crop_your_image.
class Crop extends StatelessWidget {
  /// original image data
  final Uint8List image;

  /// callback when cropping completed
  final ValueChanged<Uint8List> onCropped;

  /// fixed aspect ratio of cropping area.
  /// null, by default, means no fixed aspect ratio.
  final double? aspectRatio;

  /// initial size of cropping area.
  /// Set double value less than 1.0.
  /// if initialSize is 1.0 (or null),
  /// cropping area would expand as much as possible.
  final double? initialSize;

  /// Builder for initial [Rect] of cropping area based on viewport.
  /// Builder is called when calculating initial cropping area passing
  /// [Rect] of [Crop] viewport.
  final CroppingAreaBuilder? initialAreaBuilder;

  /// Initial [Rect] of cropping area.
  /// This [Rect] must be based on the rect of [image] data, not screen.
  ///
  /// e.g. If the original image size is 1280x1024,
  /// giving [Rect.fromLTWH(240, 212, 800, 600)] as [initialArea] would
  /// result in covering exact center of the image with 800x600 image size.
  ///
  /// If [initialArea] is given, [initialSize] is ignored.
  /// In other hand, [aspectRatio] is still enabled although initial shape of
  /// cropping area depends on [initialArea]. Once user moves cropping area
  /// with their hand, the shape of cropping area is calculated depending on [aspectRatio].
  final Rect? initialArea;

  /// flag if cropping image with circle shape.
  /// if [true], [aspectRatio] is fixed to 1.
  final bool withCircleUi;

  /// conroller for control crop actions
  final CropController? controller;

  /// Callback called when cropping area moved.
  final ValueChanged<Rect>? onMoved;

  /// Callback called when status of Crop widget is changed.
  ///
  /// note: Currently, the very first callback is [CropStatus.ready]
  /// which is called after loading [image] data for the first time.
  final ValueChanged<CropStatus>? onStatusChanged;

  /// [Color] of the mask widget which is placed over the cropping editor.
  final Color? maskColor;

  /// [Color] of the base color of the cropping editor.
  final Color baseColor;

  /// Corner radius of cropping area
  final double radius;

  /// builder for corner dot widget.
  /// [CornerDotBuilder] passes [size] which indicates the size of each dots
  /// and [EdgeAlignment] which indicates the position of each dots.
  /// If default dot Widget with different color is needed, [DotControl] is available.
  final CornerDotBuilder? cornerDotBuilder;

  /// [Clip] configuration for Crop editor, especially corner dots.
  /// [Clip.hardEdge] by default.
  final Clip clipBehavior;

  /// If [true], cropping area is fixed and CANNOT be moved.
  /// [false] by default.
  final bool fixArea;

  /// [Widget] for showing preparing for image is in progress.
  /// [SizedBox.shrink()] is used by default.
  final Widget progressIndicator;

  /// If [true], users can move and zoom image.
  /// [false] by default.
  final bool interactive;

  /// Function whether to allow scale image or not.
  /// This function is always called when user tries to scale image.
  /// If this function returns [false], image cannot be scaled.
  final AllowScale? allowScale;

  /// Injected logic for cropping image.
  final ImageCropper imageCropper;

  /// Injected logic for detecting image format.
  final FormatDetector? formatDetector;

  /// Injected logic for parsing image detail.
  final ImageParser imageParser;

  Crop({
    super.key,
    required this.image,
    required this.onCropped,
    this.aspectRatio,
    this.initialSize,
    this.initialAreaBuilder,
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
    this.fixArea = false,
    this.progressIndicator = const SizedBox.shrink(),
    this.interactive = false,
    this.allowScale,
    this.formatDetector = defaultFormatDetector,
    this.imageCropper = defaultImageCropper,
    ImageParser? imageParser,
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
            initialAreaBuilder: initialAreaBuilder,
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
            fixArea: fixArea,
            progressIndicator: progressIndicator,
            interactive: interactive,
            allowScale: allowScale,
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
  final ValueChanged<Uint8List> onCropped;
  final double? aspectRatio;
  final double? initialSize;
  final CroppingAreaBuilder? initialAreaBuilder;
  final Rect? initialArea;
  final bool withCircleUi;
  final CropController? controller;
  final ValueChanged<Rect>? onMoved;
  final ValueChanged<CropStatus>? onStatusChanged;
  final Color? maskColor;
  final Color baseColor;
  final double radius;
  final CornerDotBuilder? cornerDotBuilder;
  final Clip clipBehavior;
  final bool fixArea;
  final Widget progressIndicator;
  final bool interactive;
  final AllowScale? allowScale;
  final ImageCropper imageCropper;
  final FormatDetector? formatDetector;
  final ImageParser imageParser;

  const _CropEditor({
    super.key,
    required this.image,
    required this.onCropped,
    required this.aspectRatio,
    required this.initialSize,
    required this.initialAreaBuilder,
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
    required this.fixArea,
    required this.progressIndicator,
    required this.interactive,
    required this.allowScale,
    required this.imageCropper,
    required this.formatDetector,
    required this.imageParser,
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

  /// [Rect] of displaying image
  /// Note that this is not the actual [Size] of the image.
  late ViewportBasedRect _imageRect;

  /// for cropping editor
  double? _aspectRatio;
  bool _withCircleUi = false;
  bool _isFitVertically = false;

  /// [ViewportBasedRect] of cropping area
  /// The result of cropping is based on this [_rect].
  late ViewportBasedRect _rect;
  set rect(ViewportBasedRect newRect) {
    setState(() => _rect = newRect);
    widget.onMoved?.call(_rect);
  }

  bool get _isImageLoading => _lastComputed != null;

  Calculator get calculator => _isFitVertically
      ? const VerticalCalculator()
      : const HorizontalCalculator();

  ImageFormat? _detectedFormat;

  @override
  void initState() {
    super.initState();

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
      ..onChangeRect = (newRect) {
        rect = calculator.correct(newRect, _imageRect);
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

    final future = compute(
      _parseFunc,
      [widget.imageParser, formatDetector, image],
    );
    _lastComputed = future;
    future.then((parsed) {
      // if _parseImageWith() is called again before future completed,
      // just skip and the last future is used.
      if (_lastComputed == future) {
        setState(() {
          _parsedImageDetail = parsed;
          _lastComputed = null;
          _detectedFormat = widget.formatDetector?.call(image);
        });
        _resetCroppingArea();
        widget.onStatusChanged?.call(CropStatus.ready);
      }
    });
  }

  /// reset [Rect] of cropping area with current state
  void _resetCroppingArea() {
    final screenSize = _viewportSize;

    final imageRatio = _parsedImageDetail!.width / _parsedImageDetail!.height;
    _isFitVertically = imageRatio < screenSize.aspectRatio;

    _imageRect = calculator.imageRect(screenSize, imageRatio);

    if (widget.initialAreaBuilder != null) {
      rect = widget.initialAreaBuilder!(Rect.fromLTWH(
        0,
        0,
        screenSize.width,
        screenSize.height,
      ));
    } else {
      _resizeWith(widget.aspectRatio, widget.initialArea);
    }

    if (widget.interactive) {
      final initialScale = calculator.scaleToCover(screenSize, _imageRect);
      _applyScale(initialScale);
    }
  }

  /// resize cropping area with given aspect ratio.
  void _resizeWith(double? aspectRatio, Rect? initialArea) {
    _aspectRatio = _withCircleUi ? 1 : aspectRatio;

    if (initialArea == null) {
      rect = calculator.initialCropRect(
        _viewportSize,
        _imageRect,
        _aspectRatio ?? 1,
        widget.initialSize ?? 1,
      );
    } else {
      final screenSizeRatio = calculator.screenSizeRatio(
        _parsedImageDetail!,
        _viewportSize,
      );
      rect = Rect.fromLTWH(
        _imageRect.left + initialArea.left / screenSizeRatio,
        _imageRect.top + initialArea.top / screenSizeRatio,
        initialArea.width / screenSizeRatio,
        initialArea.height / screenSizeRatio,
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
    final cropResult = await compute(
      _cropFunc,
      [
        widget.imageCropper,
        _parsedImageDetail!.image,
        Rect.fromLTWH(
          (_rect.left - _imageRect.left) * screenSizeRatio / _scale,
          (_rect.top - _imageRect.top) * screenSizeRatio / _scale,
          _rect.width * screenSizeRatio / _scale,
          _rect.height * screenSizeRatio / _scale,
        ),
        withCircleShape,
        _detectedFormat,
      ],
    );

    widget.onCropped(cropResult);
    widget.onStatusChanged?.call(CropStatus.ready);
  }

  // for zooming
  int _pointerNum = 0;
  double _scale = 1.0;
  double _baseScale = 1.0;

  void _startScale(ScaleStartDetails detail) {
    _baseScale = _scale;
  }

  void _updateScale(ScaleUpdateDetails detail) {
    // move
    var movedLeft = _imageRect.left + detail.focalPointDelta.dx;
    if (movedLeft + _imageRect.width < _rect.right) {
      movedLeft = _rect.right - _imageRect.width;
    }

    var movedTop = _imageRect.top + detail.focalPointDelta.dy;
    if (movedTop + _imageRect.height < _rect.bottom) {
      movedTop = _rect.bottom - _imageRect.height;
    }
    setState(() {
      _imageRect = ViewportBasedRect.fromLTWH(
        min(_rect.left, movedLeft),
        min(_rect.top, movedTop),
        _imageRect.width,
        _imageRect.height,
      );
    });

    // scale
    if (_pointerNum >= 2) {
      _applyScale(
        _baseScale * detail.scale,
        focalPoint: detail.localFocalPoint,
      );
    }
  }

  void _applyScale(
    double nextScale, {
    Offset? focalPoint,
  }) {
    final allowScale = widget.allowScale?.call(nextScale) ?? true;
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
    final newLeft = max(min(_rect.left, _imageRect.left - leftPositionDelta),
        _rect.right - newWidth);
    final newTop = max(min(_rect.top, _imageRect.top - topPositionDelta),
        _rect.bottom - newHeight);

    if (newWidth < _rect.width || newHeight < _rect.height) {
      return;
    }
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
                onPointerDown: (_) => _pointerNum++,
                onPointerUp: (_) => _pointerNum--,
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
                      ? CircleCropAreaClipper(_rect)
                      : CropAreaClipper(_rect, widget.radius),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: widget.maskColor ?? Colors.black.withAlpha(100),
                  ),
                ),
              ),
              if (!widget.interactive && !widget.fixArea)
                Positioned(
                  left: _rect.left,
                  top: _rect.top,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      rect = calculator.moveRect(
                        _rect,
                        details.delta.dx,
                        details.delta.dy,
                        _imageRect,
                      );
                    },
                    child: Container(
                      width: _rect.width,
                      height: _rect.height,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              Positioned(
                left: _rect.left - (dotTotalSize / 2),
                top: _rect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixArea
                      ? null
                      : (details) {
                          rect = calculator.moveTopLeft(
                            _rect,
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
                left: _rect.right - (dotTotalSize / 2),
                top: _rect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixArea
                      ? null
                      : (details) {
                          rect = calculator.moveTopRight(
                            _rect,
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
                left: _rect.left - (dotTotalSize / 2),
                top: _rect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixArea
                      ? null
                      : (details) {
                          rect = calculator.moveBottomLeft(
                            _rect,
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
                left: _rect.right - (dotTotalSize / 2),
                top: _rect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixArea
                      ? null
                      : (details) {
                          rect = calculator.moveBottomRight(
                            _rect,
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
  final formatDetector = args[1] as FormatDetector?;
  return parser(args[2] as Uint8List, formatDetector: formatDetector);
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
