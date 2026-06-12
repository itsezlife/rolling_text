import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rolling_text_example/main.dart';

void main() {
  testWidgets('Showcase app renders without error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RollingTextShowcaseApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
