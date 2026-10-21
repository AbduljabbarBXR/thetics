import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(SharedPreferences prefs)
      : _prefs = prefs,
        _memory = null;

  /// A working store for the current session when platform storage is
  /// unavailable. It deliberately does not pretend to persist across restarts.
  LocalStore.memory()
      : _prefs = null,
        _memory = null;

  static const _key = 'thetics.app.v1';
  final SharedPreferences? _prefs;
  String? _memory;

  bool get isPersistent => _prefs != null;

  static Future<LocalStore> open() async {
    return LocalStore(await SharedPreferences.getInstance());
  }

  /// Opens storage without ever blocking the first Flutter frame indefinitely.
  ///
  /// SharedPreferences normally resolves in milliseconds, but a broken plugin
  /// registration or platform channel must not leave the native splash screen
  /// on screen forever. In that case the app still starts with a session-only
  /// store and the caller can surface the persistence warning.
  static Future<LocalStore> openSafely({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(timeout);
      return LocalStore(prefs);
    } catch (error, stackTrace) {
      debugPrint('Thetics: persistent storage unavailable: $error');
      debugPrintStack(stackTrace: stackTrace);
      return LocalStore.memory();
    }
  }

  String? readRaw() => _prefs?.getString(_key) ?? _memory;

  Future<bool> writeRaw(String value) async {
    _memory = value;
    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.setString(_key, value);
  }

  Future<bool> clear() async {
    _memory = null;
    final prefs = _prefs;
    if (prefs == null) return false;
    return prefs.remove(_key);
  }
}

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('LocalStore must be overridden in main()');
});
