import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class StudyReminderService {
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required int cardGoal,
  });
  Future<void> cancelDailyReminder();
  Future<bool> requestPermission();
  Future<bool> hasPermission();
}

class LocalStudyReminderService implements StudyReminderService {
  static const int _reminderNotificationId = 7001;
  static const String _channelId = 'study_plan_reminders';
  static const String _channelName = 'Daily Study Reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  LocalStudyReminderService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  Future<void> _ensureInit() async {
    if (kIsWeb || _initialized) return;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _plugin.initialize(settings: initSettings);

      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        importance: Importance.high,
        description: 'Scheduled daily time for revising cards',
      );
      await androidImpl?.createNotificationChannel(channel);
      _initialized = true;
    } catch (e) {
      debugPrint('[StudyReminderService] Init error: $e');
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await _ensureInit();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    return granted ?? true;
  }

  @override
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    await _ensureInit();
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final enabled = await androidImpl?.areNotificationsEnabled();
    return enabled ?? true;
  }

  @override
  Future<bool> scheduleDailyReminder({
    required int hour,
    required int minute,
    required int cardGoal,
  }) async {
    if (kIsWeb) return false;
    await _ensureInit();
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Scheduled daily time for revising cards',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      final estMinutes = (cardGoal / 5).ceil();
      await _plugin.zonedSchedule(
        id: _reminderNotificationId,
        title: 'Your daily study time',
        body: '$cardGoal cards today, about $estMinutes minutes.',
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (e) {
      debugPrint('[StudyReminderService] Schedule error: $e');
      return false;
    }
  }

  @override
  Future<void> cancelDailyReminder() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id: _reminderNotificationId);
    } catch (e) {
      debugPrint('[StudyReminderService] Cancel error: $e');
    }
  }
}

final studyReminderServiceProvider = Provider<StudyReminderService>((ref) {
  return LocalStudyReminderService();
});
