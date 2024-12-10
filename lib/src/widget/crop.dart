import 'dart:async';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:crop_your_image/src/logic/shape.dart';
import 'package:crop_your_image/src/widget/circle_crop_area_clipper.dart';
import 'package:crop_your_image/src/widget/constants.dart';
import 'package:crop_your_image/src/widget/crop_editor_view_state.dart';
import 'package:crop_your_image/src/widget/rect_crop_area_clipper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef ViewportBasedRect = Rect;
typedef ImageBasedRect = Rect;

typedef WillUpdateScale = bool Function(double newScale);
typedef CornerDotBuilder = Widget Function(
    double size, EdgeAlignment edgeAlignment);

typedef CroppingRectBuilder = ViewportBasedRect Function(
  ViewportBasedRect viewportRect,
  ImageBasedRect imageRect,
);

typedef OnMovedCallback = void Function(
  ViewportBasedRect viewportRect,
  ImageBasedRect imageRect,
);

typedef OverlayBuilder = Widget Function(BuildContext context, Rect rect);

enum CropStatus { nothing, loading, ready, cropping }

/// Widget for the entry point of crop_your_image.
class Crop extends StatelessWidget {
  /// original image data
  final Uint8List image;

  /// callback when cropping completed
  final ValueChanged<Uint8List> onCropped;

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

  /// controller for control crop actions
  final CropController? controller;

  /// Callback called when cropping rect changes for any reasons.
  final OnMovedCallback? onMoved;

  final void Function(Rect imageRect)? onImageMoved;

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

  /// builder to place a widget inside the cropping area
  final OverlayBuilder? overlayBuilder;

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
    this.onImageMoved,
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
    this.overlayBuilder,
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
            onImageMoved: onImageMoved,
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
            overlayBuilder: overlayBuilder,
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
  final CroppingRectBuilder? initialRectBuilder;
  final ImageBasedRect? initialArea;
  final bool withCircleUi;
  final CropController? controller;
  final OnMovedCallback? onMoved;
  final void Function(Rect imageRect)? onImageMoved;
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
  final OverlayBuilder? overlayBuilder;

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
    required this.onImageMoved,
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
    this.overlayBuilder,
  });

  @override
  _CropEditorState createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor> {
  /// controller for crop actions
  late CropController _cropController;

  /// an object that preserve and expose all the state for _CropEditor
  late CropEditorViewState _viewState;
  ReadyCropEditorViewState get _readyState =>
      _viewState as ReadyCropEditorViewState;

  /// image with detail info parsed with [widget.imageParser]
  ImageDetail? _parsedImageDetail;

  /// detected image format with [widget.formatDetector]
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
        _viewState = _readyState.copyWith(withCircleUi: withCircleUi);
        _resizeWith(null, null);
      }
      ..onImageChanged = _resetImage
      ..onChangeCropRect = (newCropRect) {
        _updateCropRect(_readyState.correct(newCropRect));
      }
      ..onChangeArea = (newArea) {
        _resizeWith(widget.aspectRatio, newArea);
      };
  }

  @override
  void didChangeDependencies() {
    _viewState = PreparingCropEditorViewState(
      viewportSize: MediaQuery.of(context).size,
      withCircleUi: widget.withCircleUi,
      aspectRatio: widget.aspectRatio,
    );

    /// parse image with given parser and format detector
    _parseImageWith(
      parser: widget.imageParser,
      formatDetector: widget.formatDetector,
      image: widget.image,
    ).then((parsed) {
      if (parsed != null) {
        setState(() {
          _viewState = (_viewState as PreparingCropEditorViewState).prepared(
            Size(parsed.width, parsed.height),
          );
        });
        _resetCropRect();
        widget.onStatusChanged?.call(CropStatus.ready);
      }
    });

    super.didChangeDependencies();
  }

  /// apply crop rect changed to view state
  void _updateCropRect(CropEditorViewState newState) {
    setState(() => _viewState = newState);
    widget.onMoved?.call(_readyState.cropRect, _readyState.imageBaseRect);
  }

  /// reset image to be cropped
  void _resetImage(Uint8List targetImage) {
    widget.onStatusChanged?.call(CropStatus.loading);

    /// reset view state back to preparing state
    _viewState = PreparingCropEditorViewState(
      viewportSize: MediaQuery.of(context).size,
      withCircleUi: widget.withCircleUi,
      aspectRatio: widget.aspectRatio,
    );

    _parseImageWith(
      parser: widget.imageParser,
      formatDetector: widget.formatDetector,
      image: targetImage,
    ).then((parsed) {
      if (parsed != null) {
        setState(() {
          _viewState = (_viewState as PreparingCropEditorViewState).prepared(
            Size(parsed.width, parsed.height),
          );
        });
        _resetCropRect();
        widget.onStatusChanged?.call(CropStatus.ready);
      }
    });
  }

  /// temporary field to detect last computed.
  ImageParser? _lastParser;
  FormatDetector? _lastFormatDetector;
  Uint8List? _lastImage;
  Future<ImageDetail?>? _lastComputed;

  Future<ImageDetail?> _parseImageWith({
    required ImageParser parser,
    required FormatDetector? formatDetector,
    required Uint8List image,
  }) async {
    if (_lastParser == parser &&
        _lastImage == image &&
        _lastFormatDetector == formatDetector) {
      // no change
      return null;
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
    final parsed = await future;
    // check if Crop is still alive
    if (!mounted) {
      return null;
    }

    // if _parseImageWith() is called again before future completed,
    // just skip and the last future is used.
    if (_lastComputed == future) {
      // cache parsed image for future use of _crop()
      _parsedImageDetail = parsed;
      _lastComputed = null;
      _detectedFormat = format;
      return parsed;
    }
    return null;
  }

  /// reset [ViewportBasedRect] of crop rect with current state
  void _resetCropRect() {
    setState(() {
      _viewState = _readyState.resetCropRect();
      widget.onImageMoved?.call(_readyState.imageRect);
    });

    if (widget.initialRectBuilder != null) {
      _updateCropRect(
        _readyState.copyWith(
          cropRect: widget.initialRectBuilder!(
            Rect.fromLTWH(
              0,
              0,
              _readyState.viewportSize.width,
              _readyState.viewportSize.height,
            ),
            _readyState.imageRect,
          ),
        ),
      );
    } else {
      _resizeWith(widget.aspectRatio, widget.initialArea);
    }

    if (widget.interactive) {
      _applyScale(_readyState.scaleToCover);
    }
  }

  /// resize crop rect with given aspect ratio and area.
  void _resizeWith(double? aspectRatio, ImageBasedRect? area) {
    if (area == null) {
      _updateCropRect(
        _readyState.cropRectInitialized(
          initialSize: widget.initialSize,
          aspectRatio: aspectRatio,
        ),
      );
    } else {
      // calculate how smaller the viewport is than the image
      _updateCropRect(_readyState.cropRectWith(area));
    }
  }

  /// crop given image with given area.
  Future<void> _crop(bool withCircleShape) async {
    assert(_parsedImageDetail != null);

    widget.onStatusChanged?.call(CropStatus.cropping);

    // use compute() not to block UI update
    final cropResult = await compute(
      _cropFunc,
      [
        widget.imageCropper,
        _parsedImageDetail!.image,
        _readyState.rectToCrop,
        withCircleShape,
        _detectedFormat,
      ],
    );

    widget.onCropped(cropResult);
    widget.onStatusChanged?.call(CropStatus.ready);
  }

  // for zooming
  double _baseScale = 1.0;

  /// handle scale events with pinching
  void _handleScaleStart(ScaleStartDetails detail) {
    _baseScale = _readyState.scale;
  }

  void _handleScaleUpdate(ScaleUpdateDetails detail) {
    setState(() {
      _viewState = _readyState.offsetUpdated(detail.focalPointDelta);
      widget.onImageMoved?.call(_readyState.imageRect);
    });

    _applyScale(
      _baseScale * detail.scale,
      focalPoint: detail.localFocalPoint,
    );
  }

  /// handle mouse pointer signal event
  void _handlePointerSignal(PointerSignalEvent signal) {
    if (signal is PointerScrollEvent) {
      if (signal.scrollDelta.dy > 0) {
        _applyScale(
          _readyState.scale - widget.scrollZoomSensitivity,
          focalPoint: signal.localPosition,
        );
      } else if (signal.scrollDelta.dy < 0) {
        _applyScale(
          _readyState.scale + widget.scrollZoomSensitivity,
          focalPoint: signal.localPosition,
        );
      }
    }
  }

  /// apply scale updated to view state
  void _applyScale(
    double nextScale, {
    Offset? focalPoint,
  }) {
    final allowScale = widget.willUpdateScale?.call(nextScale) ?? true;
    if (!allowScale) {
      return;
    }

    setState(() {
      _viewState = _readyState.scaleUpdated(
        nextScale,
        focalPoint: focalPoint,
      );
      widget.onImageMoved?.call(_readyState.imageRect);
    });
  }

  @override
  Widget build(BuildContext context) {
    return !_viewState.isReady
        ? Center(child: widget.progressIndicator)
        : Stack(
            clipBehavior: widget.clipBehavior,
            children: [
              Listener(
                onPointerSignal: _handlePointerSignal,
                child: GestureDetector(
                  onScaleStart: widget.interactive ? _handleScaleStart : null,
                  onScaleUpdate: widget.interactive ? _handleScaleUpdate : null,
                  child: Container(
                    color: widget.baseColor,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Stack(
                      children: [
                        SizedBox.expand(),
                        Positioned(
                          left: _readyState.imageRect.left,
                          top: _readyState.imageRect.top,
                          child: Image.memory(
                            widget.image,
                            width: _readyState.imageRect.width,
                            height: _readyState.imageRect.height,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.overlayBuilder != null)
                Positioned.fromRect(
                  rect: _readyState.cropRect,
                  child: IgnorePointer(
                    child:
                        widget.overlayBuilder!(context, _readyState.cropRect),
                  ),
                ),
              IgnorePointer(
                child: ClipPath(
                  clipper: _readyState.withCircleUi
                      ? CircleCropAreaClipper(_readyState.cropRect)
                      : CropAreaClipper(_readyState.cropRect, widget.radius),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: widget.maskColor ?? Colors.black.withAlpha(100),
                  ),
                ),
              ),
              if (!widget.interactive && !widget.fixCropRect)
                Positioned(
                  left: _readyState.cropRect.left,
                  top: _readyState.cropRect.top,
                  child: GestureDetector(
                    onPanUpdate: (details) => _updateCropRect(
                      _readyState.moveRect(details.delta),
                    ),
                    child: Container(
                      width: _readyState.cropRect.width,
                      height: _readyState.cropRect.height,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              Positioned(
                left: _readyState.cropRect.left - (dotTotalSize / 2),
                top: _readyState.cropRect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) => _updateCropRect(
                            _readyState.moveTopLeft(details.delta),
                          ),
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.topLeft) ??
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _readyState.cropRect.right - (dotTotalSize / 2),
                top: _readyState.cropRect.top - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) => _updateCropRect(
                            _readyState.moveTopRight(details.delta),
                          ),
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.topRight) ??
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _readyState.cropRect.left - (dotTotalSize / 2),
                top: _readyState.cropRect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) => _updateCropRect(
                            _readyState.moveBottomLeft(details.delta),
                          ),
                  child: widget.cornerDotBuilder
                          ?.call(dotTotalSize, EdgeAlignment.bottomLeft) ??
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _readyState.cropRect.right - (dotTotalSize / 2),
                top: _readyState.cropRect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
                  onPanUpdate: widget.fixCropRect
                      ? null
                      : (details) => _updateCropRect(
                            _readyState.moveBottomRight(details.delta),
                          ),
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
