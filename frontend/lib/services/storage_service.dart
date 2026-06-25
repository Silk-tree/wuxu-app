import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyDeviceId = 'device_id';
  static const String _keyIsPremium = 'is_premium';
  static const String _keyNotificationEnabled = 'notification_enabled';
  static const String _keyHistoryNames = 'history_names';
  static const int _maxHistoryNames = 50;

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

  List<String> getHistoryNames() {
    return _prefs?.getStringList(_keyHistoryNames) ?? [];
  }

  Future<void> addHistoryName(String name) async {
    if (name.trim().isEmpty) return;

    final history = getHistoryNames();
    final trimmedName = name.trim();

    // 移除已存在的相同名称
    history.remove(trimmedName);

    // 添加到列表开头
    history.insert(0, trimmedName);

    // 限制最大数量
    if (history.length > _maxHistoryNames) {
      history.removeRange(_maxHistoryNames, history.length);
    }

    await _prefs?.setStringList(_keyHistoryNames, history);
  }

  Future<void> clearHistoryNames() async {
    await _prefs?.remove(_keyHistoryNames);
  }

  Future<void> clear() async {
    await _prefs?.clear();
  }
}
