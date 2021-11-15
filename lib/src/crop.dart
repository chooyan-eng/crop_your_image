part of crop_your_image;

const dotTotalSize = 32.0; // fixed corner dot size.
const edgeLineSize = dotTotalSize / 2 + 4; // fixed edge line size

typedef CornerDotBuilder = Widget Function(
    double size, EdgeAlignment edgeAlignment);

enum CropStatus { nothing, loading, ready, cropping }

enum GridViewMode { none, onTap, always }

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

  /// builder for corner dot widget.
  /// [CornerDotBuilder] passes [size] which indicates the size of each dots
  /// and [EdgeAlignment] which indicates the position of each dots.
  /// If default dot Widget with different color is needed, [DotControl] is available.
  final CornerDotBuilder? cornerDotBuilder;

  /// Options for grid line in cropping area
  final GridViewMode gridViewMode;

  const Crop({
    Key? key,
    required this.image,
    required this.onCropped,
    this.aspectRatio,
    this.initialSize,
    this.initialArea,
    this.withCircleUi = false,
    this.controller,
    this.onMoved,
    this.onStatusChanged,
    this.maskColor,
    this.baseColor = Colors.white,
    this.cornerDotBuilder,
    this.gridViewMode = GridViewMode.onTap,
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
            initialArea: initialArea,
            withCircleUi: withCircleUi,
            controller: controller,
            onMoved: onMoved,
            onStatusChanged: onStatusChanged,
            maskColor: maskColor,
            baseColor: baseColor,
            cornerDotBuilder: cornerDotBuilder,
            gridViewMode: gridViewMode,
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
  final Rect? initialArea;
  final bool withCircleUi;
  final CropController? controller;
  final ValueChanged<Rect>? onMoved;
  final ValueChanged<CropStatus>? onStatusChanged;
  final Color? maskColor;
  final Color baseColor;
  final CornerDotBuilder? cornerDotBuilder;
  final GridViewMode gridViewMode;

  const _CropEditor({
    Key? key,
    required this.image,
    required this.onCropped,
    this.aspectRatio,
    this.initialSize,
    this.initialArea,
    this.withCircleUi = false,
    this.controller,
    this.onMoved,
    this.onStatusChanged,
    this.maskColor,
    required this.baseColor,
    this.cornerDotBuilder,
    required this.gridViewMode,
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

  Rect _borderRect = Rect.zero;
  double _borderThickness = 100;

  Rect _gridRect = Rect.zero;
  double _gridThickness = .5;

  bool _isOnTap = false;

  bool get _isImageLoading => _lastComputed != null;

  _Calculator get calculator => _isFitVertically
      ? const _VerticalCalculator()
      : const _HorizontalCalculator();

  set rect(Rect newRect) {
    _reCalculateRect(newRect);
    setState(() {
      _rect = newRect;
    });
    widget.onMoved?.call(_rect);
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

    _resizeWith(widget.aspectRatio, widget.initialArea);
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
          (_rect.left - _imageRect.left) * screenSizeRatio,
          (_rect.top - _imageRect.top) * screenSizeRatio,
          _rect.width * screenSizeRatio,
          _rect.height * screenSizeRatio,
        ),
      ],
    );
    widget.onCropped(cropResult);

    widget.onStatusChanged?.call(CropStatus.ready);
  }

  // re-calculate border (mask) rect and grid rect
  void _reCalculateRect(Rect rect) {
    final screenSize = MediaQuery.of(context).size;
    _borderThickness = sqrt(screenSize.width * screenSize.width +
        screenSize.height * screenSize.height);

    _borderRect = _calculateTopLeft(rect, _borderThickness);
    _gridRect = _calculateTopLeft(rect, _gridThickness);
  }

  // control grid line
  void onTap(bool tap) {
    setState(() => _isOnTap = tap);
  }

  @override
  Widget build(BuildContext context) {
    return _isImageLoading
        ? Center(child: const CircularProgressIndicator())
        : ClipRect(
            child: Material(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    color: widget.baseColor,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Image.memory(
                      widget.image,
                      fit:
                          _isFitVertically ? BoxFit.fitHeight : BoxFit.fitWidth,
                    ),
                  ),
                  Positioned(
                    left: _rect.left,
                    top: _rect.top,
                    child: GestureDetector(
                      onPanDown: (tap) => onTap(true),
                      onPanEnd: (tap) => onTap(false),
                      onPanCancel: () => onTap(false),
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
                        decoration: BoxDecoration(
                          shape: _withCircleUi
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _borderRect.left,
                    top: _borderRect.top,
                    child: IgnorePointer(
                      child: Container(
                        width: _borderRect.width,
                        height: _borderRect.height,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: widget.maskColor ?? Colors.black54,
                            style: BorderStyle.solid,
                            width: _borderThickness,
                          ),
                          shape: _withCircleUi
                              ? BoxShape.circle
                              : BoxShape.rectangle,
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _rect.left - (dotTotalSize / 2),
                    top: _rect.top - (dotTotalSize / 2),
                    child: GestureDetector(
                      onPanDown: (tap) => onTap(true),
                      onPanEnd: (tap) => onTap(false),
                      onPanCancel: () => onTap(false),
                      onPanUpdate: (details) {
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
                          const EdgeControl(
                              edgeAlignment: EdgeAlignment.topLeft),
                    ),
                  ),
                  Positioned(
                    left: _rect.right - (dotTotalSize / 2),
                    top: _rect.top - (dotTotalSize / 2),
                    child: GestureDetector(
                      onPanDown: (tap) => onTap(true),
                      onPanEnd: (tap) => onTap(false),
                      onPanCancel: () => onTap(false),
                      onPanUpdate: (details) {
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
                          const EdgeControl(
                              edgeAlignment: EdgeAlignment.topRight),
                    ),
                  ),
                  Positioned(
                    left: _rect.left - (dotTotalSize / 2),
                    top: _rect.bottom - (dotTotalSize / 2),
                    child: GestureDetector(
                      onPanDown: (tap) => onTap(true),
                      onPanEnd: (tap) => onTap(false),
                      onPanCancel: () => onTap(false),
                      onPanUpdate: (details) {
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
                          const EdgeControl(
                              edgeAlignment: EdgeAlignment.bottomLeft),
                    ),
                  ),
                  Positioned(
                    left: _rect.right - (dotTotalSize / 2),
                    top: _rect.bottom - (dotTotalSize / 2),
                    child: GestureDetector(
                      onPanDown: (tap) => onTap(true),
                      onPanEnd: (tap) => onTap(false),
                      onPanCancel: () => onTap(false),
                      onPanUpdate: (details) {
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
                          const EdgeControl(
                              edgeAlignment: EdgeAlignment.bottomRight),
                    ),
                  ),

                  // Grid view
                  if ((_isOnTap && widget.gridViewMode == GridViewMode.onTap) ||
                      widget.gridViewMode == GridViewMode.always) ...[
                    Positioned(
                      left: _gridRect.left,
                      top: _gridRect.top,
                      child: IgnorePointer(
                        child: Container(
                          width: _gridRect.width,
                          height: _gridRect.height,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              style: BorderStyle.solid,
                              width: _gridThickness,
                            ),
                            shape: BoxShape.rectangle,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _gridRect.left + _gridRect.width / 3,
                      top: _gridRect.top,
                      child: IgnorePointer(
                        child: Container(
                          width: _gridRect.width / 3,
                          height: _gridRect.height,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              style: BorderStyle.solid,
                              width: _gridThickness,
                            ),
                            shape: BoxShape.rectangle,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: _gridRect.left,
                      top: _gridRect.top + _gridRect.height / 3,
                      child: IgnorePointer(
                        child: Container(
                          width: _gridRect.width,
                          height: _gridRect.height / 3,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white,
                              style: BorderStyle.solid,
                              width: _gridThickness,
                            ),
                            shape: BoxShape.rectangle,
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
  }
}

/// Default dot widget placed on corners to control cropping area.
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

/// Default corner line widget placed on corners to control cropping area.
/// This Widget automaticall fits the appropriate size.
class EdgeControl extends StatelessWidget {
  const EdgeControl({
    Key? key,
    this.color = Colors.white,
    this.edgeAlignment,
  }) : super(key: key);

  /// [Color] of this widget. [Colors.white] by default.
  final Color color;

  /// Position of the current edge widget
  final EdgeAlignment? edgeAlignment;

  @override
  Widget build(BuildContext context) {
    return edgeAlignment == null
        ? DotControl(color: color)
        : Container(
            color: Colors.transparent,
            width: dotTotalSize,
            height: dotTotalSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (edgeAlignment == EdgeAlignment.topLeft)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: edgeLineSize,
                        height: edgeLineSize,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: color, width: 2),
                            top: BorderSide(color: color, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (edgeAlignment == EdgeAlignment.bottomLeft)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: edgeLineSize,
                        height: edgeLineSize,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: color, width: 2),
                            bottom: BorderSide(color: color, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (edgeAlignment == EdgeAlignment.topRight)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: edgeLineSize,
                        height: edgeLineSize,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: color, width: 2),
                            top: BorderSide(color: color, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (edgeAlignment == EdgeAlignment.bottomRight)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: edgeLineSize,
                        height: edgeLineSize,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(color: color, width: 2),
                            bottom: BorderSide(color: color, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
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
        rect.left.toInt(),
        rect.top.toInt(),
        rect.width.toInt(),
        rect.height.toInt(),
      ),
    ),
  );
}

/// process cropping image with circle shape.
/// this method is supposed to be called only via compute()
Uint8List _doCropCircle(List<dynamic> cropData) {
  final originalImage = cropData[0] as image.Image;
  final rect = cropData[1] as Rect;
  return Uint8List.fromList(
    image.encodePng(
      image.copyCropCircle(
        originalImage,
        center:
            image.Point(rect.left + rect.width / 2, rect.top + rect.height / 2),
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
  switch (tempImage?.exif.data[0x0112] ?? -1) {
    case 3:
      return image.copyRotate(tempImage!, 180);
    case 6:
      return image.copyRotate(tempImage!, 90);
    case 8:
      return image.copyRotate(tempImage!, -90);
  }
  return tempImage!;
}

// calculate the left and top coordinates of the border (mask) widget
Rect _calculateTopLeft(Rect rect, double borderThickness) {
  double fixBorderPixels = 0;

  // Workaround to fix pixel issues in HTML renderer
  if (isHtmlRenderer) {
    fixBorderPixels = 1;
  }

  return Rect.fromLTWH(
      rect.left - borderThickness + fixBorderPixels,
      rect.top - borderThickness + fixBorderPixels,
      rect.width + borderThickness * 2 - fixBorderPixels * 2,
      rect.height + borderThickness * 2 - fixBorderPixels * 2);
}
