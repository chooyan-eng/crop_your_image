import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crop_your_image/src/widget/crop_editor_view_state.dart';
import 'package:crop_your_image/src/widget/history_state.dart';

void main() {
  final defaultViewportSize = Size(360, 200);
  final defaultImageSize = Size(800, 600);

  late HistoryState historyState;
  late List<History> historyChangedCalls;

  setUp(() {
    historyChangedCalls = [];
    historyState = HistoryState(
      onHistoryChanged: (history) => historyChangedCalls.add(history),
    );
  });

  ReadyCropEditorViewState createViewState({double scale = 1.0}) {
    return ReadyCropEditorViewState.prepared(
      defaultImageSize,
      viewportSize: defaultViewportSize,
      scale: scale,
      aspectRatio: null,
      withCircleUi: false,
    );
  }

  test('initial state has empty history', () {
    expect(historyState.history, isEmpty);
    expect(historyState.redoHistory, isEmpty);
  });

  test('pushHistory adds state and clears redo history', () {
    final state1 = createViewState(scale: 1.0);
    final state2 = createViewState(scale: 1.5);

    historyState.pushHistory(state1);
    historyState.pushHistory(state2);

    expect(historyState.history.length, 2);
    expect(historyState.redoHistory, isEmpty);
    expect(historyChangedCalls, [
      (undoCount: 1, redoCount: 0),
      (undoCount: 2, redoCount: 0),
    ]);
  });

  test('requestUndo returns last state and moves it to redo history', () {
    final state1 = createViewState(scale: 1.0);
    final state2 = createViewState(scale: 1.5);

    historyState.pushHistory(state1);
    historyState.pushHistory(state2);

    final undoState = historyState.requestUndo(createViewState());

    expect(undoState, state2);
    expect(historyState.history.length, 1);
    expect(historyState.redoHistory.length, 1);
    expect(historyChangedCalls, [
      (undoCount: 1, redoCount: 0),
      (undoCount: 2, redoCount: 0),
      (undoCount: 1, redoCount: 1),
    ]);
  });

  test('requestUndo returns null when history is empty', () {
    final undoState = historyState.requestUndo(createViewState(scale: 1.0));

    expect(undoState, null);
    expect(historyState.history, isEmpty);
    expect(historyState.redoHistory, isEmpty);
    expect(historyChangedCalls, isEmpty);
  });

  test('requestRedo returns last redo state and moves it to history', () {
    final state1 = createViewState(scale: 1.0);
    final state2 = createViewState(scale: 1.5);

    historyState.pushHistory(state1);
    historyState.pushHistory(state2);

    final current = createViewState();
    historyState.requestUndo(current); // add current to redo history

    final redoState = historyState.requestRedo(current);

    expect(redoState, current);
    expect(historyState.history.length, 2);
    expect(historyState.redoHistory, isEmpty);
    expect(historyChangedCalls, [
      (undoCount: 1, redoCount: 0),
      (undoCount: 2, redoCount: 0),
      (undoCount: 1, redoCount: 1),
      (undoCount: 2, redoCount: 0),
    ]);
  });

  test('requestRedo returns null when redo history is empty', () {
    final redoState = historyState.requestRedo(createViewState());

    expect(redoState, null);
    expect(historyState.history, isEmpty);
    expect(historyState.redoHistory, isEmpty);
    expect(historyChangedCalls, isEmpty);
  });

  test('pushing new state clears redo history', () {
    final state1 = createViewState(scale: 1.0);
    final state2 = createViewState(scale: 1.5);
    final state3 = createViewState(scale: 2.0);

    historyState.pushHistory(state1);
    historyState.pushHistory(state2);
    historyState.requestUndo(createViewState()); // Move state2 to redo history
    historyState.pushHistory(state3); // Should clear redo history

    expect(historyState.history.length, 2);
    expect(historyState.redoHistory, isEmpty);
    expect(historyChangedCalls, [
      (undoCount: 1, redoCount: 0),
      (undoCount: 2, redoCount: 0),
      (undoCount: 1, redoCount: 1),
      (undoCount: 2, redoCount: 0),
    ]);
  });
}
