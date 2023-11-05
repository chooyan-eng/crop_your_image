part of crop_your_image;

const dotTotalSize = 32.0; // fixed corner dot size.

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

  /// If [true], cropping area is fixed and CANNOT be moved.
  /// [false] by default.
  final bool fixArea;

  /// [Widget] for showing preparing for image is in progress.
  /// [SizedBox.shrink()] is used by default.
  final Widget progressIndicator;

  /// * Experimental Feature *
  /// If [true], users can move and zoom image.
  /// [false] by default.
  final bool interactive;

  const Crop({
    Key? key,
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
    this.fixArea = false,
    this.progressIndicator = const SizedBox.shrink(),
    this.interactive = false,
  })  : assert((initialSize ?? 1.0) <= 1.0,
            'initialSize must be less than 1.0, or null meaning not specified.'),
        super(key: key);

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
            fixArea: fixArea,
            progressIndicator: progressIndicator,
            interactive: interactive,
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
  final bool fixArea;
  final Widget progressIndicator;
  final bool interactive;

  const _CropEditor({
    Key? key,
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
    required this.baseColor,
    required this.radius,
    this.cornerDotBuilder,
    required this.fixArea,
    required this.progressIndicator,
    required this.interactive,
  }) : super(key: key);

  @override
  _CropEditorState createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor> {
  late CropController _cropController;
  late Rect _rect;
  image.Image? _targetImage;
  late Rect _imageRect;

  double? _aspectRatio;
  bool _withCircleUi = false;
  bool _isFitVertically = false;
  Future<image.Image?>? _lastComputed;

  bool get _isImageLoading => _lastComputed != null;

  _Calculator get calculator => _isFitVertically
      ? const _VerticalCalculator()
      : const _HorizontalCalculator();

  set rect(Rect newRect) {
    setState(() {
      _rect = newRect;
    });
    widget.onMoved?.call(_rect);
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
      _imageRect = Rect.fromLTWH(
        min(_rect.left, movedLeft),
        min(_rect.top, movedTop),
        _imageRect.width,
        _imageRect.height,
      );
    });

    // scale
    // _pointerNum >= 2
    if (true) {
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
    late double baseHeight;
    late double baseWidth;
    final ratio = _targetImage!.height / _targetImage!.width;

    if (_isFitVertically) {
      baseHeight = MediaQuery.of(context).size.height;
      baseWidth = baseHeight / ratio;
    } else {
      baseWidth = MediaQuery.of(context).size.width;
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
  void initState() {
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

    super.initState();
  }

  @override
  void didChangeDependencies() {
    final future = compute(_fromByteData, widget.image);
    _lastComputed = future;
    future.then((converted) {
      if (_lastComputed == future) {
        _targetImage = converted;
        _withCircleUi = widget.withCircleUi;
        _resetCroppingArea();

        setState(() {
          _lastComputed = null;
        });
        widget.onStatusChanged?.call(CropStatus.ready);
      }
    });
    super.didChangeDependencies();
  }

  /// reset image to be cropped
  void _resetImage(Uint8List targetImage) {
    widget.onStatusChanged?.call(CropStatus.loading);
    final future = compute(_fromByteData, targetImage);
    _lastComputed = future;
    future.then((converted) {
      if (_lastComputed == future) {
        setState(() {
          _targetImage = converted;
          _lastComputed = null;
        });
        _resetCroppingArea();
        widget.onStatusChanged?.call(CropStatus.ready);
      }
    });
  }

  /// reset [Rect] of cropping area with current state
  void _resetCroppingArea() {
    final screenSize = MediaQuery.of(context).size;

    final imageRatio = _targetImage!.width / _targetImage!.height;
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
        MediaQuery.of(context).size,
        _imageRect,
        _aspectRatio ?? 1,
        widget.initialSize ?? 1,
      );
    } else {
      final screenSizeRatio = calculator.screenSizeRatio(
        _targetImage!,
        MediaQuery.of(context).size,
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
    assert(_targetImage != null);

    final screenSizeRatio = calculator.screenSizeRatio(
      _targetImage!,
      MediaQuery.of(context).size,
    );

    widget.onStatusChanged?.call(CropStatus.cropping);

    // use compute() not to block UI update
    final cropResult = await compute(
      withCircleShape ? _doCropCircle : _doCrop,
      [
        _targetImage!,
        Rect.fromLTWH(
          (_rect.left - _imageRect.left) * screenSizeRatio / _scale,
          (_rect.top - _imageRect.top) * screenSizeRatio / _scale,
          _rect.width * screenSizeRatio / _scale,
          _rect.height * screenSizeRatio / _scale,
        ),
      ],
    );
    widget.onCropped(cropResult);

    widget.onStatusChanged?.call(CropStatus.ready);
  }

  @override
  Widget build(BuildContext context) {
    return _isImageLoading
        ? Center(child: widget.progressIndicator)
        : Stack(
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
                      ? _CircleCropAreaClipper(_rect)
                      : _CropAreaClipper(_rect, widget.radius),
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

class _CropAreaClipper extends CustomClipper<Path> {
  _CropAreaClipper(this.rect, this.radius);

  final Rect rect;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()
      ..addPath(
        Path()
          ..moveTo(rect.left, rect.top + radius)
          ..arcToPoint(Offset(rect.left + radius, rect.top),
              radius: Radius.circular(radius))
          ..lineTo(rect.right - radius, rect.top)
          ..arcToPoint(Offset(rect.right, rect.top + radius),
              radius: Radius.circular(radius))
          ..lineTo(rect.right, rect.bottom - radius)
          ..arcToPoint(Offset(rect.right - radius, rect.bottom),
              radius: Radius.circular(radius))
          ..lineTo(rect.left + radius, rect.bottom)
          ..arcToPoint(Offset(rect.left, rect.bottom - radius),
              radius: Radius.circular(radius))
          ..close(),
        Offset.zero,
      )
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class _CircleCropAreaClipper extends CustomClipper<Path> {
  final Rect rect;

  _CircleCropAreaClipper(this.rect);

  @override
  Path getClip(Size size) {
    return Path()
      ..addOval(Rect.fromCircle(center: rect.center, radius: rect.width / 2))
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

/// Defalt dot widget placed on corners to control cropping area.
/// This Widget automaticall fits the appropriate size.
class DotControl extends StatelessWidget {
  const DotControl({
    Key? key,
    this.color = Colors.white,
    this.padding = 8,
  }) : super(key: key);

  /// [Color] of this widget. [Colors.white] by default.
  final Color color;

  /// The size of transparent padding which exists to make dot easier to touch.
  /// Though total size of this widget cannot be changed,
  /// but visible size can be changed by setting this value.
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: dotTotalSize,
      height: dotTotalSize,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dotTotalSize),
          child: Container(
            width: dotTotalSize - (padding * 2),
            height: dotTotalSize - (padding * 2),
            color: color,
          ),
        ),
      ),
    );
  }
}

/// process cropping image.
/// this method is supposed to be called only via compute()
Uint8List _doCrop(List<dynamic> cropData) {
  final originalImage = cropData[0] as image.Image;
  final rect = cropData[1] as Rect;
  return Uint8List.fromList(
    image.encodePng(
      image.copyCrop(
        originalImage,
        x: rect.left.toInt(),
        y: rect.top.toInt(),
        width: rect.width.toInt(),
        height: rect.height.toInt(),
      ),
    ),
  );
}

/// process cropping image with circle shape.
/// this method is supposed to be called only via compute()
Uint8List _doCropCircle(List<dynamic> cropData) {
  final originalImage = cropData[0] as image.Image;
  final rect = cropData[1] as Rect;
  final center = image.Point(
    rect.left + rect.width / 2,
    rect.top + rect.height / 2,
  );
  return Uint8List.fromList(
    image.encodePng(
      image.copyCropCircle(
        originalImage,
        centerX: center.xi,
        centerY: center.yi,
        radius: min(rect.width, rect.height) ~/ 2,
      ),
    ),
  );
}

// decode orientation awared Image.
image.Image _fromByteData(Uint8List data) {
  final tempImage = image.decodeImage(data);
  assert(tempImage != null);

  // check orientation
  switch (tempImage?.exif.exifIfd.orientation ?? -1) {
    case 3:
      return image.copyRotate(tempImage!, angle: 180);
    case 6:
      return image.copyRotate(tempImage!, angle: 90);
    case 8:
      return image.copyRotate(tempImage!, angle: -90);
  }
  return tempImage!;
}
