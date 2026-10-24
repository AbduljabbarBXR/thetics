import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Persistence for Thetics.
///
/// Android and iOS use SQLite. The web build and desktop targets without a
/// sqflite plugin keep using SharedPreferences. A session-only store is the
/// final fallback so startup can never deadlock.
class LocalStore {
  LocalStore(SharedPreferences prefs)
      : _prefs = prefs,
        _db = null,
        _memory = null;

  LocalStore.sqlite(Database db)
      : _prefs = null,
        _db = db,
        _memory = null;

  /// A working store for the current session when platform storage is
  /// unavailable. It deliberately does not pretend to persist across restarts.
  LocalStore.memory()
      : _prefs = null,
        _db = null,
        _memory = null;

  static const _key = 'thetics.app.v1';
  static const _migrationKey = 'thetics.sqlite.migrated.v1';
  static const _table = 'app_state';
  static const _databaseName = 'thetics.db';
  static const _databaseVersion = 1;

  final SharedPreferences? _prefs;
  final Database? _db;
  String? _memory;

  bool get isPersistent => _db != null || _prefs != null;

  String get storageKind {
    if (_db != null) return 'sqlite';
    if (_prefs != null) return 'preferences';
    return 'memory';
  }

  static Future<LocalStore> open() async {
    return LocalStore(await SharedPreferences.getInstance());
  }

  /// Opens persistent storage behind a timeout and never blocks startup.
  ///
  /// On Android and iOS the primary store is SQLite. Existing data in
  /// SharedPreferences is imported once, so users upgrading from 1.0.x keep
  /// their profile and history. If SQLite cannot be opened, the old
  /// SharedPreferences store is used; if that also fails, the app runs with a
  /// session-only store and surfaces a warning on the profile tab.
  static Future<LocalStore> openSafely({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb) return _openPreferencesSafely(timeout);

    try {
      final db = await _openDatabase().timeout(timeout);
      final store = LocalStore.sqlite(db);
      await store._migrateFromPreferences();
      return store;
    } catch (error, stackTrace) {
      debugPrint('Thetics: SQLite unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return _openPreferencesSafely(timeout);
  }

  static Future<LocalStore> _openPreferencesSafely(Duration timeout) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(timeout);
      return LocalStore(prefs);
    } catch (error, stackTrace) {
      debugPrint('Thetics: persistent storage unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return LocalStore.memory();
    }
  }

  static Future<Database> _openDatabase() async {
    final directories = await getDatabasesPath();
    final databasePath = path.join(directories, _databaseName);
    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onCreate: _createSchema,
    );
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_table (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        payload TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _migrateFromPreferences({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final db = _db;
    if (db == null) return;

    try {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $_table'),
      );
      if ((count ?? 0) > 0) return;

      final prefs = await SharedPreferences.getInstance().timeout(timeout);
      if (prefs.getBool(_migrationKey) ?? false) return;

      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        await prefs.setBool(_migrationKey, true);
        return;
      }

      await _writeToDatabase(db, raw);
      await prefs.setBool(_migrationKey, true);
      debugPrint(
        'Thetics: migrated ${raw.length} characters from SharedPreferences '
        'to SQLite.',
      );
    } catch (error) {
      debugPrint('Thetics: storage migration skipped: $error');
    }
  }

  @visibleForTesting
  Future<void> runMigrationForTesting() => _migrateFromPreferences();

  static Future<void> _writeToDatabase(Database db, String value) {
    return db.insert(
      _table,
      {
        'id': 1,
        'payload': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> readRaw() async {
    final db = _db;
    if (db != null) {
      try {
        final rows = await db.query(
          _table,
          columns: ['payload'],
          where: 'id = ?',
          whereArgs: [1],
          limit: 1,
        );
        if (rows.isEmpty) return null;
        return rows.first['payload'] as String?;
      } catch (error, stackTrace) {
        debugPrint('Thetics: SQLite read failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        return _readPreferencesSafely();
      }
    }
    return _prefs?.getString(_key) ?? _memory;
  }

  Future<String?> _readPreferencesSafely() async {
    try {
      final prefs = _prefs ??
          await SharedPreferences.getInstance().timeout(
            const Duration(seconds: 2),
          );
      return prefs.getString(_key) ?? _memory;
    } catch (error) {
      debugPrint('Thetics: preferences read failed: $error');
      return _memory;
    }
  }

  Future<bool> writeRaw(String value) async {
    _memory = value;

    final db = _db;
    if (db != null) {
      try {
        await _writeToDatabase(db, value);
        return true;
      } catch (error, stackTrace) {
        debugPrint('Thetics: SQLite write failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (db != null) {
      // SQLite failed after opening. Keep a best-effort copy in preferences so
      // the session is not silently lost.
      final prefs = await _preferencesSafely();
      if (prefs == null) return false;
      return prefs.setString(_key, value);
    }

    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.setString(_key, value);
  }

  static Future<SharedPreferences?> _preferencesSafely() async {
    try {
      return await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
    } catch (error) {
      debugPrint('Thetics: preferences unavailable: $error');
      return null;
    }
  }

  Future<bool> clear() async {
    _memory = null;

    final db = _db;
    if (db != null) {
      try {
        await db.delete(_table, where: 'id = ?', whereArgs: [1]);
      } catch (error, stackTrace) {
        debugPrint('Thetics: SQLite clear failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      // Keep the legacy copy from resurrecting old data after a reset. The
      // migration marker stays set, so an empty DB will not be re-imported.
      try {
        final prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 1),
        );
        await prefs.remove(_key);
      } catch (error) {
        debugPrint('Thetics: could not clear legacy storage: $error');
      }
      return true;
    }

    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.remove(_key);
  }

  Future<void> close() async {
    await _db?.close();
  }
}

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('LocalStore must be overridden in main()');
});
