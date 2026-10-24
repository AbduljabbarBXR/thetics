import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:thetics/core/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('memory store keeps data for the session without claiming persistence',
      () async {
    final store = LocalStore.memory();

    expect(store.isPersistent, isFalse);
    expect(store.storageKind, 'memory');
    expect(await store.readRaw(), isNull);

    expect(await store.writeRaw('session-only'), isFalse);
    expect(await store.readRaw(), 'session-only');

    expect(await store.clear(), isFalse);
    expect(await store.readRaw(), isNull);
  });

  test('SQLite store round-trips and clears the saved document', () async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE app_state (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              payload TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    final store = LocalStore.sqlite(db);

    expect(store.isPersistent, isTrue);
    expect(store.storageKind, 'sqlite');
    expect(await store.readRaw(), isNull);

    expect(await store.writeRaw('sqlite-data'), isTrue);
    expect(await store.readRaw(), 'sqlite-data');

    expect(await store.clear(), isTrue);
    expect(await store.readRaw(), isNull);

    await store.close();
  });

  test('migration imports legacy preferences once and cannot resurrect data',
      () async {
    SharedPreferences.setMockInitialValues({
      'thetics.app.v1': 'legacy-data',
    });
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) {
          return db.execute('''
            CREATE TABLE app_state (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              payload TEXT NOT NULL,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    final store = LocalStore.sqlite(db);

    await store.runMigrationForTesting();
    expect(await store.readRaw(), 'legacy-data');

    await store.clear();
    await store.runMigrationForTesting();
    expect(await store.readRaw(), isNull);

    await store.close();
  });

  test('openSafely falls back to preferences when SQLite is unavailable',
      () async {
    SharedPreferences.setMockInitialValues({
      'thetics.app.v1': 'saved-data',
    });

    final store = await LocalStore.openSafely(
      timeout: const Duration(seconds: 2),
    );

    expect(store.isPersistent, isTrue);
    expect(await store.readRaw(), 'saved-data');
  });
}
