/// Image with detail information.
class ImageDetail<T> {
  ImageDetail({
    required this.image,
    required this.width,
    required this.height,
  });

  final T image;
  final double width;
  final double height;

  late final bool isLandscape = width >= height;
  late final bool isPortrait = width < height;
}
