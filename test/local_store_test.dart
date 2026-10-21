import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thetics/core/storage/local_store.dart';

void main() {
  test('memory store keeps data for the session without claiming persistence',
      () async {
    final store = LocalStore.memory();

    expect(store.isPersistent, isFalse);
    expect(store.readRaw(), isNull);

    expect(await store.writeRaw('session-only'), isFalse);
    expect(store.readRaw(), 'session-only');

    expect(await store.clear(), isFalse);
    expect(store.readRaw(), isNull);
  });

  test('openSafely opens persistent storage when the platform channel works',
      () async {
    SharedPreferences.setMockInitialValues({
      'thetics.app.v1': 'saved-data',
    });

    final store = await LocalStore.openSafely(
      timeout: const Duration(seconds: 2),
    );

    expect(store.isPersistent, isTrue);
    expect(store.readRaw(), 'saved-data');
  });
}
