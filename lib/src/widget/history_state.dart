import 'package:crop_your_image/crop_your_image.dart';
import 'package:crop_your_image/src/widget/crop_editor_view_state.dart';
import 'package:flutter/foundation.dart';

class HistoryState {
  HistoryState({required this.onHistoryChanged});

  /// history of crop editor operation for undo
  /// history is stored when zoom / pan is changed, as well as crop rect moved.
  @visibleForTesting
  final List<CropEditorViewState> history = [];

  /// history of crop editor operation for redo
  @visibleForTesting
  final List<CropEditorViewState> redoHistory = [];

  final HistoryChangedCallback? onHistoryChanged;

  /// push current view state to history
  /// this operation will clear redo history
  void pushHistory(CropEditorViewState viewState) {
    history.add(viewState);
    redoHistory.clear();
    onHistoryChanged?.call(
      (undoCount: history.length, redoCount: redoHistory.length),
    );
  }

  /// request [CropEditorViewState] for undo
  /// this method will pop last history and push to redo history
  CropEditorViewState? requestUndo(CropEditorViewState current) {
    if (history.isEmpty) {
      return null;
    }

    redoHistory.add(current);
    final last = history.removeLast();

    onHistoryChanged?.call(
      (undoCount: history.length, redoCount: redoHistory.length),
    );

    return last;
  }

  /// request [CropEditorViewState] for redo
  /// this method will pop last redo history
  CropEditorViewState? requestRedo(CropEditorViewState current) {
    if (redoHistory.isEmpty) {
      return null;
    }

    history.add(current);
    final last = redoHistory.removeLast();
    onHistoryChanged?.call(
      (undoCount: history.length, redoCount: redoHistory.length),
    );
    return last;
  }
}
