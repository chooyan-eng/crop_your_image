part of crop_your_image;

const dotTotalSize = 32.0; // fixed corner dot size.

typedef CornerDotBuilder = Widget Function(
    double size, EdgeAlignment edgeAlignment);

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

  /// Use [Clip.none] in Stack, this is more reliable then using [Clip.hardEdge] but
  /// it will overlaps all other widgets by [maskColor].
  /// Default is set to false.
  final bool useClipNone;

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
    this.useClipNone = false,
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
            useClipNone: useClipNone,
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
  final bool useClipNone;

  const _CropEditor(
      {Key? key,
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
      required this.useClipNone})
      : super(key: key);

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
  double _borderThickness = 0;
  bool _isHtml = isHtmlRenderer;

  bool get _isImageLoading => _lastComputed != null;

  _Calculator get calculator => _isFitVertically
      ? const _VerticalCalculator()
      : const _HorizontalCalculator();

  set rect(Rect newRect) {
    final screenSize = MediaQuery.of(context).size;
    _borderThickness = sqrt(screenSize.width * screenSize.width +
        screenSize.height * screenSize.height);
    final borderRect = _calculateEdge(newRect, _borderThickness, screenSize);
    setState(() {
      _borderRect = borderRect;
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
    final screenSize = MediaQuery.of(context).size;
    _borderThickness = sqrt(screenSize.width * screenSize.width +
        screenSize.height * screenSize.height);

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

  // calculate the left and top coordinates of the contour widget because it won't be correct if the position is a negative number
  // Clip.none cannot be used in Stack because the mask will stack on top of all other widgets
  Rect _calculateEdge(Rect rect, double maxThickness, Size screenSize) {
    // Just a workaround
    if (!widget.useClipNone && _isHtml) {
      return Rect.fromLTWH(
          rect.left - maxThickness - maxThickness / 2,
          rect.top - maxThickness - maxThickness / 2,
          rect.width + maxThickness * 2,
          rect.height + maxThickness * 2);
    }

    return Rect.fromLTWH(rect.left - maxThickness, rect.top - maxThickness,
        rect.width + maxThickness * 2, rect.height + maxThickness * 2);
  }

  @override
  Widget build(BuildContext context) {
    return _isImageLoading
        ? Center(child: const CircularProgressIndicator())
        : Stack(
            fit: StackFit.expand,
            clipBehavior: widget.useClipNone ? Clip.none : Clip.hardEdge,
            children: [
              Container(
                color: widget.baseColor,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Image.memory(
                  widget.image,
                  fit: _isFitVertically ? BoxFit.fitHeight : BoxFit.fitWidth,
                ),
              ),
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
                    decoration: BoxDecoration(
                      shape:
                          _withCircleUi ? BoxShape.circle : BoxShape.rectangle,
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
                      shape:
                          _withCircleUi ? BoxShape.circle : BoxShape.rectangle,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: _rect.left - (dotTotalSize / 2),
                top: _rect.top - (dotTotalSize / 2),
                child: GestureDetector(
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
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _rect.right - (dotTotalSize / 2),
                top: _rect.top - (dotTotalSize / 2),
                child: GestureDetector(
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
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _rect.left - (dotTotalSize / 2),
                top: _rect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
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
                      const DotControl(),
                ),
              ),
              Positioned(
                left: _rect.right - (dotTotalSize / 2),
                top: _rect.bottom - (dotTotalSize / 2),
                child: GestureDetector(
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
                      const DotControl(),
                ),
              ),
            ],
          );
  }
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
