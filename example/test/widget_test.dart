import 'package:crop_your_image/crop_your_image.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Show Crop', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CropSample(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(Crop), findsOneWidget);
  });
}
