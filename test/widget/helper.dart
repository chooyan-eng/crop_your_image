import 'package:flutter/material.dart';

Widget withMaterial(Widget widget) {
  return MaterialApp(
    home: Scaffold(
      // TODO(chooyan-eng): fix error on cropping if image is not large enough comparing to viewport
      // body: SizedBox.expand(child: widget),
      body: SizedBox(width: 300, height: 300, child: widget),
    ),
  );
}
