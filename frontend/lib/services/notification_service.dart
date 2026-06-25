import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/item.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final iOSImpl = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final androidImpl = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    bool granted = false;

    if (iOSImpl != null) {
      granted = await iOSImpl.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    if (androidImpl != null) {
      final androidGranted = await androidImpl.requestNotificationsPermission();
      granted = granted || (androidGranted ?? false);
    }

    return granted;
  }

  Future<void> scheduleExpiryNotification(Item item) async {
    if (!_initialized) return;

    final now = DateTime.now();
    final expiry = item.expiryDate;

    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);

    final daysUntil = expiryDay.difference(today).inDays;

    if (daysUntil < 0) return;

    DateTime scheduledTime;
    String title;
    String body;

    if (daysUntil == 0) {
      title = '物品今天过期';
      body = '「${item.name}」今天就过期了，尽快使用哦~';
      scheduledTime = DateTime(now.year, now.month, now.day, 9, 0);
      if (scheduledTime.isBefore(now)) return;
    } else if (daysUntil <= 7) {
      title = '物品即将过期';
      body = '「${item.name}」还有 $daysUntil 天就过期了';
      scheduledTime = DateTime(
        expiry.year,
        expiry.month,
        expiry.day - 3,
        9,
        0,
      );
      if (scheduledTime.isBefore(now)) return;
    } else {
      return;
    }

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    final notificationId = item.id.hashCode;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'expiry_reminder',
      '过期提醒',
      channelDescription: '物品过期提醒通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails();

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzScheduledTime,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(String itemId) async {
    if (!_initialized) return;
    await _flutterLocalNotificationsPlugin.cancel(itemId.hashCode);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
