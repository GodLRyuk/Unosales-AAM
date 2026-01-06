import 'package:shared_preferences/shared_preferences.dart';

/// A utility class to manage in-app tour completion status
/// using SharedPreferences. Supports saving and retrieving
/// tour flags using simple keys.
class AppTourManager {
  /// Save tour status with the given [key].
  static Future<void> saveTourStatus(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  /// Get tour status by [key]. Returns `true` if completed, otherwise `false`.
  static Future<bool> getTourStatus(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }
}
