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
    onHistoryChanged?.call((history.length, redoHistory.length));
  }

  /// request [CropEditorViewState] for undo
  /// this method will pop last history and push to redo history
  CropEditorViewState? requestUndo() {
    if (history.isEmpty) {
      return null;
    }

    final last = history.removeLast();
    redoHistory.add(last);
    onHistoryChanged?.call((history.length, redoHistory.length));

    return last;
  }

  /// request [CropEditorViewState] for redo
  /// this method will pop last redo history
  CropEditorViewState? requestRedo() {
    if (redoHistory.isEmpty) {
      return null;
    }

    final last = redoHistory.removeLast();
    history.add(last);
    onHistoryChanged?.call((history.length, redoHistory.length));
    return last;
  }
}
