import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crop_your_image/src/widget/crop_editor_view_state.dart';

void main() {
  group('PreparingCropEditorViewState', () {
    final defaultViewportSize = Size(360, 200);

    late PreparingCropEditorViewState state;

    setUp(() {
      state = PreparingCropEditorViewState(
        viewportSize: defaultViewportSize,
        withCircleUi: false,
        aspectRatio: 1.5,
      );
    });

    test('preserves all the given values', () {
      expect(state.viewportSize, defaultViewportSize);
      expect(state.withCircleUi, false);
      expect(state.aspectRatio, 1.5);
    });

    test('state is not ready', () {
      expect(state.isReady, false);
    });

    test('prepared method creates ReadyCropEditorViewState', () {
      final imageSize = Size(800, 600);

      final readyState = state.prepared(imageSize);

      expect(readyState, isA<ReadyCropEditorViewState>());
      expect(readyState.isReady, true);
      expect(readyState.viewportSize, defaultViewportSize);
      expect(readyState.imageSize, imageSize);
      expect(readyState.scale, 1.0);
      expect(readyState.withCircleUi, false);
      expect(readyState.aspectRatio, 1.5);
    });
  });

  group('ReadyCropEditorViewState', () {
    final defaultViewportSize = Size(360, 200);
    final defaultImageSize = Size(800, 600);

    late ReadyCropEditorViewState state;

    setUp(() {
      state = ReadyCropEditorViewState.prepared(
        defaultImageSize,
        viewportSize: defaultViewportSize,
        scale: 1.0,
        aspectRatio: null,
        withCircleUi: false,
      );
    });

    test('prepared factory creates correct initial state', () {
      expect(state.isReady, true);
      expect(state.viewportSize, defaultViewportSize);
      expect(state.imageSize, defaultImageSize);
      expect(state.scale, 1.0);
      expect(state.withCircleUi, false);
      expect(state.aspectRatio, null);
    });

    test('isFitVertically calculates correctly', () {
      final verticalState = ReadyCropEditorViewState.prepared(
        Size(300, 800), // vertical image
        viewportSize: defaultViewportSize,
        scale: 1.0,
        aspectRatio: null,
        withCircleUi: false,
      );

      final horizontalState = ReadyCropEditorViewState.prepared(
        Size(800, 300), // horizontal image
        viewportSize: defaultViewportSize,
        scale: 1.0,
        aspectRatio: null,
        withCircleUi: false,
      );

      expect(verticalState.isFitVertically, true);
      expect(horizontalState.isFitVertically, false);
    });

    group('moveRect', () {
      test('moves rect within bounds', () {
        final initialRect = Rect.fromLTWH(30, 30, 50, 50);
        final stateWithRect = state.copyWith(cropRect: initialRect);

        final movedState = stateWithRect.moveRect(const Offset(50, 30));

        expect(movedState.cropRect.left, 80);
        expect(movedState.cropRect.top, 60);
        expect(movedState.cropRect.width, 50);
        expect(movedState.cropRect.height, 50);
      });

      test('constrains movement within image bounds', () {
        final initialRect = Rect.fromLTWH(50, 50, 100, 100);
        final stateWithRect = state.copyWith(cropRect: initialRect);

        final movedState = stateWithRect.moveRect(const Offset(-100, -100));

        // Check that the rect stays within bounds
        expect(movedState.cropRect.left, closeTo(46, 1));
        expect(movedState.cropRect.top, 0);
        expect(movedState.cropRect.width, 100);
        expect(movedState.cropRect.height, 100);
      });
    });

    group('scaleUpdated', () {
      test('updates scale with constraints', () {
        final initialRect = Rect.fromLTWH(100, 100, 200, 200);
        final stateWithRect = state.copyWith(cropRect: initialRect);

        final scaledState = stateWithRect.scaleUpdated(2.0);

        expect(scaledState.scale, 2.0);
        expect(scaledState.imageRect.width,
            greaterThan(stateWithRect.imageRect.width));
        expect(scaledState.imageRect.height,
            greaterThan(stateWithRect.imageRect.height));
      });

      test('maintains minimum scale to cover crop rect', () {
        final initialRect = Rect.fromLTWH(100, 100, 200, 200);
        final stateWithRect = state.copyWith(cropRect: initialRect);

        // Try to scale smaller than minimum allowed
        final scaledState = stateWithRect.scaleUpdated(0.1);

        // Scale should be constrained to minimum required to cover crop rect
        expect(scaledState.imageRect.width,
            greaterThanOrEqualTo(initialRect.width));
        expect(scaledState.imageRect.height,
            greaterThanOrEqualTo(initialRect.height));
      });
    });

    test('cropRectInitialized respects aspect ratio', () {
      final initializedState = state.cropRectInitialized(
        aspectRatio: 1.5,
        initialSize: 0.8,
      );

      final ratio =
          initializedState.cropRect.width / initializedState.cropRect.height;
      expect(ratio, closeTo(1.5, 0.01));
    });

    test('withCircleUi forces aspect ratio to 1.0', () {
      final state = ReadyCropEditorViewState.prepared(
        defaultImageSize,
        viewportSize: defaultViewportSize,
        scale: 1.0,
        aspectRatio: 1.5, // This should be ignored when withCircleUi is true
        withCircleUi: true,
      );

      final initializedState = state.cropRectInitialized();

      final ratio =
          initializedState.cropRect.width / initializedState.cropRect.height;
      expect(ratio, closeTo(1.0, 0.01));
    });
  });
}
