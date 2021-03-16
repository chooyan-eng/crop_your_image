part of crop_your_image;

/// Controller to control crop actions.
class CropController {
  late CropControllerDelegate _delegate;

  /// setter for [CropControllerDelegate]
  set delegate(CropControllerDelegate value) => _delegate = value;

  /// crop given image with current configuration
  void crop() => _delegate.onCrop();
}

/// Delegate of actions from [CropController]
class CropControllerDelegate {
  /// callback that [CropController.crop] is called.
  late VoidCallback onCrop;
}
