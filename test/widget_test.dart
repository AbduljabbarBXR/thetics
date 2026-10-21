import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thetics/app.dart';
import 'package:thetics/core/storage/local_store.dart';
import 'package:thetics/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('fresh install boots into onboarding', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final store = await LocalStore.open();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(store)],
        child: const TheticsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('THETICS'), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
