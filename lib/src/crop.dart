part of crop_your_image;

const dotSize = 16.0; // visible dot size
const dotPadding = 32.0; // padding for touchable area
const dotTotalSize = dotSize + (dotPadding * 2);

/// Widget for the entry point of crop_your_image.
class Crop extends StatelessWidget {
  /// original image data
  final Uint8List image;

  /// callback when cropping completed
  final ValueChanged<Uint8List> onCropped;

  /// conroller for control crop actions
  final CropController? controller;

  /// flag to show debug sheet
  final bool showDebugSheet;

  const Crop({
    Key? key,
    required this.image,
    required this.onCropped,
    this.controller,
    this.showDebugSheet = false,
  }) : super(key: key);

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
            controller: controller,
            showDebugSheet: showDebugSheet,
          ),
        );
      },
    );
  }
}

class _CropEditor extends StatefulWidget {
  final Uint8List image;
  final ValueChanged<Uint8List> onCropped;
  final CropController? controller;
  final bool showDebugSheet;

  const _CropEditor({
    Key? key,
    required this.image,
    required this.onCropped,
    this.controller,
    this.showDebugSheet = false,
  }) : super(key: key);

  @override
  _CropEditorState createState() => _CropEditorState();
}

class _CropEditorState extends State<_CropEditor> {
  late CropController _cropController;
  late TransformationController _controller;
  late Rect _rect;
  image.Image? _targetImage;
  late double _imageTop;
  late double _imageBottom;

  @override
  void initState() {
    _cropController = widget.controller ?? CropController();
    _cropController.delegate = CropControllerDelegate()..onCrop = _crop;

    final decodedImage = image.decodeImage(widget.image);
    setState(() {
      _targetImage = decodedImage;
    });

    _controller = TransformationController()
      ..addListener(() => setState(() {}));

    super.initState();
  }

  @override
  void didChangeDependencies() {
    final initialSize = 100.0;
    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    _rect = Rect.fromLTWH(centerX - initialSize / 2, centerY - initialSize / 2,
        initialSize, initialSize);

    final imageRatio = _targetImage!.width / _targetImage!.height;
    final imageScreenHeight = screenSize.width / imageRatio;
    _imageTop = (screenSize.height - imageScreenHeight) / 2;
    _imageBottom = _imageTop + imageScreenHeight;

    super.didChangeDependencies();
  }

  /// crop given image with given area.
  void _crop() async {
    if (_targetImage != null) {
      final screenSize = MediaQuery.of(context).size;
      final screenSizeRatio = _targetImage!.width / screenSize.width;

      final cropResult = image.encodePng(image.copyCrop(
        _targetImage!,
        (_rect.left.toInt() * screenSizeRatio).toInt(),
        ((_rect.top.toInt() - _imageTop) * screenSizeRatio).toInt(),
        (_rect.width * screenSizeRatio).toInt(),
        (_rect.height * screenSizeRatio).toInt(),
      ));

      widget.onCropped(Uint8List.fromList(cropResult));
    } else {
      print('data is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rightLimit = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        InteractiveViewer(
          scaleEnabled: false,
          transformationController: _controller,
          child: Container(
            color: Colors.blue.shade50,
            width: double.infinity,
            height: double.infinity,
            child: Image.memory(widget.image),
          ),
        ),
        IgnorePointer(
          child: ClipPath(
            clipper: _CropAreaClipper(_rect),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withAlpha(100),
            ),
          ),
        ),
        Positioned(
          left: _rect.left - (dotTotalSize / 2),
          top: _rect.top - (dotTotalSize / 2),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rect = Rect.fromLTRB(
                  max(0, min(_rect.left + details.delta.dx, _rect.right - 40)),
                  min(max(_rect.top + details.delta.dy, _imageTop),
                      _rect.bottom - 40),
                  _rect.right,
                  _rect.bottom,
                );
              });
            },
            child: _DotControl(),
          ),
        ),
        Positioned(
          left: _rect.right - (dotTotalSize / 2),
          top: _rect.top - (dotTotalSize / 2),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rect = Rect.fromLTRB(
                  _rect.left,
                  min(
                      rightLimit,
                      min(max(_rect.top + details.delta.dy, _imageTop),
                          _rect.bottom - 40)),
                  max(_rect.right + details.delta.dx, _rect.left + 40),
                  _rect.bottom,
                );
              });
            },
            child: _DotControl(),
          ),
        ),
        Positioned(
          left: _rect.left - (dotTotalSize / 2),
          top: _rect.bottom - (dotTotalSize / 2),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rect = Rect.fromLTRB(
                  max(0, min(_rect.left + details.delta.dx, _rect.right - 40)),
                  _rect.top,
                  _rect.right,
                  max(min(_rect.bottom + details.delta.dy, _imageBottom),
                      _rect.top + 40),
                );
              });
            },
            child: _DotControl(),
          ),
        ),
        Positioned(
          left: _rect.right - (dotTotalSize / 2),
          top: _rect.bottom - (dotTotalSize / 2),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _rect = Rect.fromLTRB(
                  _rect.left,
                  _rect.top,
                  min(rightLimit,
                      max(_rect.right + details.delta.dx, _rect.left + 40)),
                  max(min(_rect.bottom + details.delta.dy, _imageBottom),
                      _rect.top + 40),
                );
              });
            },
            child: _DotControl(),
          ),
        ),
        Visibility(
          visible: widget.showDebugSheet,
          child: _buildDebugSheet(context),
        ),
      ],
    );
  }

  /// build debug sheet containing current scale, position, image size, etc.
  Widget _buildDebugSheet(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Container(
      color: Colors.green.withAlpha(200),
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(16),
      child: Positioned(
        bottom: 0,
        left: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SCREEN: height ${screenSize.height} / width ${screenSize.width}',
              style: TextStyle(color: Colors.white),
            ),
            if (_targetImage != null)
              Text(
                'IMAGE: height ${_targetImage!.height} / width ${_targetImage!.width}',
                style: TextStyle(color: Colors.white),
              ),
            Text(
              '$_rect',
              style: TextStyle(color: Colors.white),
            ),
            Text(
              'CONTROLLER: ${_controller.value.getMaxScaleOnAxis()}\n${_controller.value}',
              style: TextStyle(color: Colors.white),
            ),
            if (_targetImage != null)
              Text(
                '${_targetImage!.width * _controller.value.getMaxScaleOnAxis()}\n${_controller.value.entry(0, 3).abs() + screenSize.width}',
                style: TextStyle(color: Colors.white),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _CropAreaClipper extends CustomClipper<Path> {
  final Rect rect;

  _CropAreaClipper(this.rect);

  @override
  Path getClip(Size size) {
    return Path()
      ..addPath(
        Path()
          ..moveTo(rect.left, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.left, rect.bottom)
          ..close(),
        Offset.zero,
      )
      ..addRect(Rect.fromLTWH(0.0, 0.0, size.width, size.height))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class _DotControl extends StatelessWidget {
  const _DotControl({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      width: dotTotalSize,
      height: dotTotalSize,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(dotSize),
          child: Container(
            width: dotSize,
            height: dotSize,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
