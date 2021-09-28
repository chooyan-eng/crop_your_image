import 'package:crop_your_image/src/recognizers/custom_pan_recognizer.dart';
import 'package:flutter/widgets.dart';

class CustomPanDetector extends StatelessWidget {
  final Widget child;
  final Function(Offset offset)? onPanDown;
  final Function(Offset delta)? onPanUpdate;
  final Function()? onPanEnd;

  const CustomPanDetector({
    Key? key,
    required this.child,
    this.onPanDown,
    this.onPanUpdate,
    this.onPanEnd,
  }) : super(key: key);

  void _onPanDown(Offset offset) {
    this.onPanDown?.call(offset);
  }

  void _onPanUpdate(Offset delta) {
    this.onPanUpdate?.call(delta);
  }

  void _onPanEnd(_) {
    this.onPanEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        CustomPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<CustomPanGestureRecognizer>(
          () => CustomPanGestureRecognizer(
            onPanDown: this._onPanDown,
            onPanUpdate: this._onPanUpdate,
            onPanEnd: this._onPanEnd,
          ),
          (_) {},
        ),
      },
      child: this.child,
    );
  }
}
