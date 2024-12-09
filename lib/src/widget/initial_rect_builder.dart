import 'package:crop_your_image/src/widget/crop.dart';

/// an interface for initial rect builder.
abstract class InitialRectBuilder {
  /// create [InitialRectBuilder] with builder function, with passed [viewportRect] and [imageRect].
  /// see also [Crop.initialRectBuilder].
  factory InitialRectBuilder.withBuilder(CroppingRectBuilder builder) =>
      WithBuilderInitialRectBuilder(builder);

  /// create [InitialRectBuilder] with [ImageBasedRect] named [area].
  /// see also [Crop.initialRectBuilder].
  factory InitialRectBuilder.withArea(ImageBasedRect area) =>
      WithAreaInitialRectBuilder(area);

  /// create [InitialRectBuilder] with [size] and [aspectRatio].
  /// see also [Crop.initialRectBuilder].
  factory InitialRectBuilder.withSizeAndRatio({
    double? size,
    double? aspectRatio,
  }) =>
      WithSizeAndRatioInitialRectBuilder(size, aspectRatio);
}

/// [InitialRectBuilder] with builder function.
final class WithBuilderInitialRectBuilder implements InitialRectBuilder {
  WithBuilderInitialRectBuilder(this._builder);

  final CroppingRectBuilder _builder;

  ViewportBasedRect build(
    ViewportBasedRect viewportRect,
    ImageBasedRect imageRect,
  ) {
    return _builder(viewportRect, imageRect);
  }
}

/// [InitialRectBuilder] with [ImageBasedRect] named [area].
final class WithAreaInitialRectBuilder implements InitialRectBuilder {
  WithAreaInitialRectBuilder(this._area);

  final ImageBasedRect _area;
  ImageBasedRect get area => _area;
}

/// [InitialRectBuilder] with [size] and [aspectRatio].
final class WithSizeAndRatioInitialRectBuilder implements InitialRectBuilder {
  WithSizeAndRatioInitialRectBuilder(
    this._size,
    this._aspectRatio,
  );

  final double? _size;
  final double? _aspectRatio;

  double? get size => _size;
  double? get aspectRatio => _aspectRatio;
}
