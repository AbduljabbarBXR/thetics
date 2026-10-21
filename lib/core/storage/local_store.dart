import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  LocalStore(this._prefs);

  static const _key = 'thetics.app.v1';
  final SharedPreferences _prefs;

  static Future<LocalStore> open() async {
    return LocalStore(await SharedPreferences.getInstance());
  }

  String? readRaw() => _prefs.getString(_key);

  Future<bool> writeRaw(String value) => _prefs.setString(_key, value);

  Future<bool> clear() => _prefs.remove(_key);
}

final localStoreProvider = Provider<LocalStore>((ref) {
  throw UnimplementedError('LocalStore must be overridden in main()');
});
