part of crop_your_image;

/// Controller to control crop actions.
class CropController {
  late CropControllerDelegate _delegate;
  set delegate(CropControllerDelegate value) {
    _delegate = value;
  }

  void crop() => _delegate.onCrop();
}

/// Delegate of actions from [CropController]
class CropControllerDelegate {
  late VoidCallback onCrop;
}
