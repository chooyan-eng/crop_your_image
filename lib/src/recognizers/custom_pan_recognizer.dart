import 'dart:ui';

import 'package:flutter/gestures.dart';

class CustomPanGestureRecognizer extends OneSequenceGestureRecognizer {
  final Function(Offset offset) onPanDown;
  final Function(Offset delta) onPanUpdate;
  final Function onPanEnd;

  CustomPanGestureRecognizer({
    required this.onPanDown,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  void addPointer(PointerEvent event) {
    if (event.original is PointerDownEvent) {
      this.onPanDown(event.position);
      this.startTrackingPointer(event.pointer);
      this.resolve(GestureDisposition.accepted);
      return;
    }
    this.stopTrackingPointer(event.pointer);
  }

  @override
  void handleEvent(PointerEvent event) {
    switch (event.runtimeType) {
      case PointerMoveEvent:
        this.onPanUpdate(event.delta);
        return;
      case PointerUpEvent:
        this.onPanEnd(event.position);
        this.stopTrackingPointer(event.pointer);
        return;
    }
  }

  @override
  String get debugDescription => 'customPan';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
