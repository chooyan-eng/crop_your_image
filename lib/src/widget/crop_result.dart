// Created by alex@justprodev.com on 04.03.2024.

import 'dart:typed_data';

sealed class CropResult {
  const CropResult();
}

class CropSuccess extends CropResult {
  const CropSuccess(this.croppedImage);
  final Uint8List croppedImage;
}

class CropFailure extends CropResult {
  const CropFailure(this.cause, [this.stackTrace]);
  final Object cause;
  final StackTrace? stackTrace;
}
