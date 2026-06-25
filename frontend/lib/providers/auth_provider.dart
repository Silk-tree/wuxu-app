import 'dart:math';
import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AuthProvider with ChangeNotifier {
  final StorageService _storage;
  final ApiService _apiService;
  final NotificationService _notificationService = NotificationService();

  AuthProvider({
    required StorageService storage,
    required ApiService apiService,
  })  : _storage = storage,
        _apiService = apiService;

  bool _isPremium = false;
  bool _notificationEnabled = true;
  String _deviceId = '';
  bool _isInitialized = false;

  bool get isPremium => _isPremium;
  bool get notificationEnabled => _notificationEnabled;
  String get deviceId => _deviceId;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    _deviceId = _storage.getDeviceId();
    if (_deviceId.isEmpty) {
      _deviceId = _generateDeviceId();
      await _storage.setDeviceId(_deviceId);
    }
    _isPremium = _storage.getIsPremium();
    _notificationEnabled = _storage.getNotificationEnabled();
    _isInitialized = true;
    notifyListeners();
  }

  String _generateDeviceId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(16, (i) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<bool> purchase() async {
    try {
      final success = await _apiService.purchase();
      if (success) {
        _isPremium = true;
        await _storage.setIsPremium(true);
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleNotification(bool value) async {
    _notificationEnabled = value;
    await _storage.setNotificationEnabled(value);

    if (value) {
      // 开启通知时，重新安排所有通知
      // 注意：这需要访问 ItemProvider，但由于在 AuthProvider 中，
      // 我们无法直接访问它。通知的重安排将在应用重启时自动进行。
      try {
        await _notificationService.cancelAllNotifications();
      } catch (e) {
        debugPrint('取消旧通知失败: $e');
      }
    } else {
      // 关闭通知时，取消所有通知
      try {
        await _notificationService.cancelAllNotifications();
      } catch (e) {
        debugPrint('取消通知失败: $e');
      }
    }

    notifyListeners();
  }
}
