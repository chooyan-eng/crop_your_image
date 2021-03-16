part of crop_your_image;

/// Controller to control crop actions.
class CropController {
  late CropControllerDelegate _delegate;

  /// setter for [CropControllerDelegate]
  set delegate(CropControllerDelegate value) => _delegate = value;

  /// crop given image with current configuration
  void crop() => _delegate.onCrop(false);

  /// crop given image with current configuration and circle shape.
  void cropCircle() => _delegate.onCrop(true);

  /// change fixed aspect ratio
  /// if [value] is null, cropping area can be moved without fixed aspect ratio.
  set aspectRatio(double? value) => _delegate.onChangeAspectRatio(value);

  /// change if cropping with circle shaped UI.
  /// if [value] is true, [aspectRatio] automatically fixed with 1
  set withCircleUi(bool value) => _delegate.onChangeWithCircleUi(value);
}

/// Delegate of actions from [CropController]
class CropControllerDelegate {
  /// callback that [CropController.crop] is called.
  /// the meaning of the value is if cropping a image with circle shape.
  late ValueChanged<bool> onCrop;

  /// callback that [CropController.aspectRatio] is set.
  late ValueChanged<double?> onChangeAspectRatio;

  /// callback that [CropController.withCircleUi] is changed.
  late ValueChanged<bool> onChangeWithCircleUi;
}
