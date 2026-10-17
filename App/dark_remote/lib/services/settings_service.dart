import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _sensitivityKey = 'sensitivity';
  static const _lastIpKey = 'last_ip';
  static const _darkModeKey = 'dark_mode';
  static const defaultSensitivity = 2.0;

  Future<double> loadSensitivity() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getDouble(_sensitivityKey) ?? defaultSensitivity;
  }

  Future<void> saveSensitivity(double sensitivity) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_sensitivityKey, sensitivity);
  }

  Future<String?> loadLastIp() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastIpKey);
  }

  Future<void> saveLastIp(String ip) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastIpKey, ip);
  }

  Future<bool> loadDarkMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_darkModeKey) ?? true;
  }

  Future<void> saveDarkMode(bool isDarkMode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, isDarkMode);
  }
}
