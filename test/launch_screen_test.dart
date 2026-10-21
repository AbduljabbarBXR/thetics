import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thetics/app.dart';
import 'package:thetics/core/theme/app_theme.dart';

void main() {
  testWidgets('launch screen fits a narrow phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: const LaunchScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('THETICS'), findsOneWidget);
    expect(find.text('TRAIN · TRACK · TRANSFORM'), findsOneWidget);
  });
}
