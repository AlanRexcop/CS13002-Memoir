import 'package:shared_preferences/shared_preferences.dart';

class PersistenceService {
  static const String _kLocalStoragePathKey = 'local_storage_path';

  Future<void> saveLocalStoragePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocalStoragePathKey, path);
  }

  Future<String?> getLocalStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kLocalStoragePathKey);
  }

  Future<void> clearLocalStoragePath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocalStoragePathKey);
  }
}