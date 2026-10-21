import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thetics/app.dart';
import 'package:thetics/core/models/app_data.dart';
import 'package:thetics/core/storage/local_store.dart';
import 'package:thetics/features/profile/models/user_profile.dart';
import 'package:thetics/features/progress/models/measurement.dart';
import 'package:thetics/features/shell/app_shell.dart';

void main() {
  testWidgets('all five tabs render with a populated local profile',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = await LocalStore.open();
    final data = AppData(
      profile: UserProfile(
        name: 'Test Lifter',
        sex: Sex.male,
        age: 30,
        heightCm: 180,
        weightKg: 80,
        goal: Goal.aesthetics,
        experience: Experience.intermediate,
        trainingDays: 4,
        activity: ActivityLevel.moderate,
        units: UnitSystem.metric,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        targetWeightKg: 76,
      ),
      measurements: [
        MeasurementEntry(
          id: 'm1',
          date: DateTime.now(),
          weightKg: 80,
          waistCm: 82,
        ),
      ],
      selectedProgramId: 'ppl_aesthetics',
    );
    await store.writeRaw(jsonEncode(data.toJson()));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const TheticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);

    for (final tab in ['Train', 'Fuel', 'Progress', 'You']) {
      await tester.tap(find.text(tab).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Tab $tab threw');
    }
  });
}
