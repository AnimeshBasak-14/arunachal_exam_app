import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: initSettings);
      
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      await androidImplementation?.requestNotificationsPermission();
      
      const channel = AndroidNotificationChannel(
        'daily_streak_channel',
        'Daily Study Reminder',
        importance: Importance.high,
      );
      
      await androidImplementation?.createNotificationChannel(channel);
          
      _initialized = true;

      // Schedule daily 8 AM notification
      await scheduleDailyReminder();
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  static Future<void> scheduleDailyReminder() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_streak_channel',
        'Daily Study Reminder',
        channelDescription: 'Daily reminder to keep your study streak alive',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const notifDetails = NotificationDetails(android: androidDetails);

      // Schedule at 8:00 AM IST daily
      await _plugin.zonedSchedule(
        id: AppConstants.dailyStreakNotifId,
        title: '🔥 Keep your streak alive!',
        body: 'Open the app for your Word of the Day and solve 5 questions.',
        scheduledDate: _nextInstanceOf8AM(),
        notificationDetails: notifDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('[NotificationService] Schedule error: $e');
    }
  }

  static Future<void> showNotification(int id, String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_streak_channel',
        'Daily Study Reminder',
        channelDescription: 'Daily reminder to keep your study streak alive',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const notifDetails = NotificationDetails(android: androidDetails);
      
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: notifDetails,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show error: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOf8AM() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[NotificationService] Cancel error: $e');
    }
  }
}
