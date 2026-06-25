import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyDeviceId = 'device_id';
  static const String _keyIsPremium = 'is_premium';
  static const String _keyNotificationEnabled = 'notification_enabled';

  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _prefs ??= await SharedPreferences.getInstance();
      _instance = StorageService._();
    }
    return _instance!;
  }

  String getDeviceId() {
    return _prefs?.getString(_keyDeviceId) ?? '';
  }

  Future<void> setDeviceId(String deviceId) async {
    await _prefs?.setString(_keyDeviceId, deviceId);
  }

  bool getIsPremium() {
    return _prefs?.getBool(_keyIsPremium) ?? false;
  }

  Future<void> setIsPremium(bool isPremium) async {
    await _prefs?.setBool(_keyIsPremium, isPremium);
  }

  bool getNotificationEnabled() {
    return _prefs?.getBool(_keyNotificationEnabled) ?? true;
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    await _prefs?.setBool(_keyNotificationEnabled, enabled);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }
}
