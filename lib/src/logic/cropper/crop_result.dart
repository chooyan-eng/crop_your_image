// Created by alex@justprodev.com on 04.03.2024.

import 'dart:typed_data';

class CropResult {
  final Uint8List? image;
  final Object? error;
  final StackTrace? trace;

  const CropResult(
    this.image,
    this.error,
    this.trace,
  );
}
