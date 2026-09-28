import 'package:crop_your_image/src/widget/constants.dart';
import 'package:flutter/widgets.dart';

/// Default dot widget placed on corners to control cropping area.
/// This Widget automatically fits the appropriate size.
class DotControl extends StatelessWidget {
  const DotControl({
    Key? key,
    this.color = const Color(0xFFFFFFFF),
    this.padding = 8,
  }) : super(key: key);

  /// [Color] of this widget. White (`Color(0xFFFFFFFF)`) by default.
  final Color color;

  /// The size of transparent padding which exists to make dot easier to touch.
  /// Though total size of this widget cannot be changed,
  /// but visible size can be changed by setting this value.
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0x00000000),
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
