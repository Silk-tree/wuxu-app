import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/item.dart';

/// 通知点击回调类型
typedef NotificationCallback = void Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  NotificationCallback? _onNotificationTap;

  /// 通知渠道 ID
  static const String _channelId = 'expiry_reminder';
  static const String _channelName = '过期提醒';
  static const String _channelDescription = '物品过期提醒通知';

  /// 初始化通知服务
  Future<void> init({NotificationCallback? onNotificationTap}) async {
    if (_initialized) return;

    _onNotificationTap = onNotificationTap;
    tz.initializeTimeZones();

    // Android 配置
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS 配置
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // 初始化设置
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // Android 8.0+ 需要创建通知渠道
    await _createAndroidNotificationChannel();

    _initialized = true;
  }

  /// 创建 Android 通知渠道
  Future<void> _createAndroidNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  /// 处理通知点击
  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('通知点击，payload: $payload');
    _onNotificationTap?.call(payload);
  }

  /// 请求通知权限
  Future<bool> requestPermissions() async {
    if (!_initialized) await init();

    bool granted = false;

    // iOS 权限请求
    if (Platform.isIOS) {
      final iOSPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iOSPlugin != null) {
        granted = await iOSPlugin.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    }

    // Android 13+ 权限请求
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        try {
          final androidGranted =
              await androidPlugin.requestNotificationsPermission();
          granted = granted || (androidGranted ?? false);
        } catch (e) {
          debugPrint('请求 Android 通知权限失败: $e');
          // 假设有权限继续
          granted = true;
        }
      }
    }

    return granted;
  }

  /// 为单个物品安排通知
  Future<void> scheduleItemNotification(Item item) async {
    if (!_initialized) await init();
    if (item.id.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(
      item.expiryDate.year,
      item.expiryDate.month,
      item.expiryDate.day,
    );
    final daysUntil = expiryDay.difference(today).inDays;

    // 只为未过期的物品设置通知
    if (daysUntil < 0) return;

    // 1. 到期当天通知（上午 9:00）
    if (daysUntil == 0) {
      await _scheduleDayNotification(item);
    }

    // 2. 预警通知（到期前 3 天，上午 9:00）
    if (daysUntil >= 3) {
      await _scheduleWarningNotification(item, daysUntil);
    }

    // 3. 额外预警（到期前 1 天）
    if (daysUntil >= 1) {
      await _scheduleOneDayWarningNotification(item);
    }
  }

  /// 获取通知详情
  NotificationDetails _getNotificationDetails() {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: const BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  /// 安排到期当天通知
  Future<void> _scheduleDayNotification(Item item) async {
    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);

    // 如果已经过了今天9点，不再安排
    if (scheduledTime.isBefore(now)) return;

    final notificationId = _generateNotificationId(item.id, 'day');
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '🍱 ${item.name} 今天过期',
      _getDayNotificationBody(item),
      tzTime,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'item:${item.id}',
    );

    debugPrint('已安排当天通知: ${item.name}, ID: $notificationId');
  }

  /// 安排 3 天前预警通知
  Future<void> _scheduleWarningNotification(Item item, int daysUntil) async {
    final expiryDate = item.expiryDate;
    // 预警时间：到期前 3 天上午 9:00
    final warningDate = expiryDate.subtract(const Duration(days: 3));
    final scheduledTime = DateTime(warningDate.year, warningDate.month, warningDate.day, 9, 0);

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    final notificationId = _generateNotificationId(item.id, 'warning');
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '⏰ ${item.name} 即将过期',
      _getWarningNotificationBody(item, 3),
      tzTime,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'item:${item.id}',
    );

    debugPrint('已安排预警通知: ${item.name}, 3天后过期, ID: $notificationId');
  }

  /// 安排 1 天前预警通知
  Future<void> _scheduleOneDayWarningNotification(Item item) async {
    final expiryDate = item.expiryDate;
    final warningDate = expiryDate.subtract(const Duration(days: 1));
    final scheduledTime = DateTime(warningDate.year, warningDate.month, warningDate.day, 9, 0);

    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) return;

    final notificationId = _generateNotificationId(item.id, 'tomorrow');
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '⚠️ ${item.name} 明天过期',
      _getWarningNotificationBody(item, 1),
      tzTime,
      _getNotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'item:${item.id}',
    );

    debugPrint('已安排明天过期通知: ${item.name}, ID: $notificationId');
  }

  /// 安排每日汇总通知（每天上午 9:00 检查当天到期物品）
  Future<void> scheduleDailySummary(List<Item> items) async {
    if (!_initialized) await init();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 找出今天到期的物品
    final todayExpiring = items.where((item) {
      final expiryDay = DateTime(
        item.expiryDate.year,
        item.expiryDate.month,
        item.expiryDate.day,
      );
      return expiryDay.isAtSameMomentAs(today);
    }).toList();

    if (todayExpiring.isEmpty) return;

    // 每天 9:00 发送汇总
    final scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);
    final targetTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    final tzTime = tz.TZDateTime.from(targetTime, tz.local);

    final names = todayExpiring.map((e) => e.name).join('、');
    final body = todayExpiring.length == 1
        ? '$names 今天过期，请尽快处理'
        : '以下物品今天过期：$names';

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      _generateNotificationId('daily', 'summary'),
      '📋 今日过期提醒',
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_summary',
    );

    debugPrint('已安排每日汇总通知，${todayExpiring.length} 个物品今天过期');
  }

  /// 取消单个物品的所有通知
  Future<void> cancelItemNotification(String itemId) async {
    if (!_initialized) return;

    // 取消所有相关的通知 ID
    await _flutterLocalNotificationsPlugin
        .cancel(_generateNotificationId(itemId, 'day'));
    await _flutterLocalNotificationsPlugin
        .cancel(_generateNotificationId(itemId, 'warning'));
    await _flutterLocalNotificationsPlugin
        .cancel(_generateNotificationId(itemId, 'tomorrow'));

    debugPrint('已取消物品通知: $itemId');
  }

  /// 取消所有通知
  Future<void> cancelAllNotifications() async {
    if (!_initialized) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('已取消所有通知');
  }

  /// 发送即时通知（用于测试）
  Future<void> showTestNotification() async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      '🏠 物序提醒',
      '通知功能已开启！',
      details,
    );
  }

  /// 生成通知 ID（确保同一物品的不同通知类型有不同的 ID）
  int _generateNotificationId(String itemId, String type) {
    final base = itemId.hashCode.abs();
    switch (type) {
      case 'day':
        return base;
      case 'warning':
        return base + 100000;
      case 'tomorrow':
        return base + 200000;
      case 'summary':
        return 999999;
      default:
        return base;
    }
  }

  /// 获取到期当天通知内容
  String _getDayNotificationBody(Item item) {
    switch (item.categoryId) {
      case '0': // 食品
        return '「${item.name}」今天就过期了，请检查是否还能食用~';
      case '1': // 日用品
        return '「${item.name}」今天过期，记得查看保质期哦';
      case '2': // 药品
        return '「${item.name}」今天过期，药品请勿继续使用';
      default:
        return '「${item.name}」今天过期，请及时处理';
    }
  }

  /// 获取预警通知内容
  String _getWarningNotificationBody(Item item, int days) {
    if (days == 1) {
      switch (item.categoryId) {
        case '0': // 食品
          return '「${item.name}」明天过期，记得尽快食用哦~';
        case '1': // 日用品
          return '「${item.name}」明天过期，请注意使用期限';
        case '2': // 药品
          return '「${item.name}」明天过期，请提前准备替代品';
        default:
          return '「${item.name}」明天过期，请及时处理';
      }
    } else {
      switch (item.categoryId) {
        case '0': // 食品
          return '「${item.name}」还有 $days 天过期，记得尽快使用哦~';
        case '1': // 日用品
          return '「${item.name}」还有 $days 天过期，请注意使用期限';
        case '2': // 药品
          return '「${item.name}」还有 $days 天过期，请注意药品有效期';
        default:
          return '「${item.name}」还有 $days 天过期，请注意保质期';
      }
    }
  }
}
