import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thetics/app.dart';
import 'package:thetics/core/storage/local_store.dart';
import 'package:thetics/features/shell/app_shell.dart';

void main() {
  testWidgets('first-run onboarding reaches the name step and completes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await LocalStore.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const TheticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    // The intro CTA is pinned above the fold so the flow is always startable.
    expect(find.text('BUILD MY BLUEPRINT'), findsOneWidget);
    await tester.tap(find.text('BUILD MY BLUEPRINT'));
    await tester.pumpAndSettle();

    // Regression: the name step must actually be revealed after the intro.
    expect(find.text('Who are we\nbuilding?'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'e.g. Abdul'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. Abdul'),
      'Abdul',
    );
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('Start from\nthe truth.'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('What are we\nbuilding toward?'), findsOneWidget);

    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    expect(find.text('Numbers, not\nguesswork.'), findsOneWidget);

    await tester.tap(find.text('ENTER THETICS'));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small phone can start onboarding from the visible CTA',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await LocalStore.open();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const TheticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    final cta = find.text('BUILD MY BLUEPRINT');
    expect(cta.hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(cta).dy, lessThanOrEqualTo(568));

    await tester.tap(cta);
    await tester.pumpAndSettle();

    expect(find.text('Who are we\nbuilding?'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'e.g. Abdul'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
