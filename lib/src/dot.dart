part of crop_your_image;

class DotControl extends StatelessWidget {
  const DotControl({
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
