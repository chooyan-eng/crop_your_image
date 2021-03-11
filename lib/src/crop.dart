part of crop_your_image;

const dotSize = 16.0;
const dotPadding = 32.0;
const dotTotalSize = dotSize + dotPadding * 2;

class MyHomePage extends StatefulWidget {
  final String imageName;

  const MyHomePage({
    Key? key,
    required this.imageName,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late TransformationController _controller;
  late Rect _rect;
  Uint8List? _croppedImage;
  image.Image? _targetImage;

  @override
  void initState() {
    _controller = TransformationController()
      ..addListener(() => setState(() {}));
    rootBundle.load(widget.imageName).then((assetData) {
      final dataList = assetData.buffer.asUint8List();
      final decodedImage = image.decodeImage(dataList);
      setState(() {
        _targetImage = decodedImage;
      });
    });
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

    super.didChangeDependencies();
  }

  void _crop() async {
    if (_targetImage != null) {
      final screenSize = MediaQuery.of(context).size;
      final screenSizeRatio = _targetImage!.width / screenSize.width;

      final imageRatio = _targetImage!.width / _targetImage!.height;
      final imageScreenHeight = screenSize.width / imageRatio;
      final imageTop = (screenSize.height - imageScreenHeight) / 2;

      final cropResult = image.encodePng(image.copyCrop(
        _targetImage!,
        (_rect.left.toInt() * screenSizeRatio).toInt(),
        ((_rect.top.toInt() - imageTop) * screenSizeRatio).toInt(),
        (_rect.width * screenSizeRatio).toInt(),
        (_rect.height * screenSizeRatio).toInt(),
      ));
      setState(() {
        _croppedImage = Uint8List.fromList(cropResult);
      });
    } else {
      print('data is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _crop();
        },
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            transformationController: _controller,
            child: Container(
              color: Colors.blue.shade50,
              width: double.infinity,
              height: double.infinity,
              child: _croppedImage == null
                  ? Image.asset(widget.imageName)
                  : Image.memory(_croppedImage!),
            ),
          ),
          if (_croppedImage == null)
            IgnorePointer(
              child: ClipPath(
                clipper: InvertedCircleClipper(_rect),
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withAlpha(100),
                ),
              ),
            ),
          if (_croppedImage == null)
            Positioned(
              left: _rect.left - (dotTotalSize / 2),
              top: _rect.top - (dotTotalSize / 2),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rect = Rect.fromLTRB(
                      _rect.left + details.delta.dx,
                      _rect.top + details.delta.dy,
                      _rect.right,
                      _rect.bottom,
                    );
                  });
                },
                child: _DotControl(),
              ),
            ),
          if (_croppedImage == null)
            Positioned(
              left: _rect.right - (dotTotalSize / 2),
              top: _rect.top - (dotTotalSize / 2),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rect = Rect.fromLTRB(
                      _rect.left,
                      _rect.top + details.delta.dy,
                      _rect.right + details.delta.dx,
                      _rect.bottom,
                    );
                  });
                },
                child: _DotControl(),
              ),
            ),
          if (_croppedImage == null)
            Positioned(
              left: _rect.left - (dotTotalSize / 2),
              top: _rect.bottom - (dotTotalSize / 2),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rect = Rect.fromLTRB(
                      _rect.left + details.delta.dx,
                      _rect.top,
                      _rect.right,
                      _rect.bottom + details.delta.dy,
                    );
                  });
                },
                child: _DotControl(),
              ),
            ),
          if (_croppedImage == null)
            Positioned(
              left: _rect.right - (dotTotalSize / 2),
              top: _rect.bottom - (dotTotalSize / 2),
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _rect = Rect.fromLTRB(
                      _rect.left,
                      _rect.top,
                      _rect.right + details.delta.dx,
                      _rect.bottom + details.delta.dy,
                    );
                  });
                },
                child: _DotControl(),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              color: Colors.green.withAlpha(200),
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.all(16),
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
          )
        ],
      ),
    );
  }
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

class InvertedCircleClipper extends CustomClipper<Path> {
  final Rect rect;

  InvertedCircleClipper(this.rect);

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
