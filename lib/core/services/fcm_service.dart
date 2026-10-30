import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_inbox.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService.instance;
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await _saveToInbox(message);
  } catch (e) {
    debugPrint('[FCM Background] Error: $e');
  }
}

Future<void> _saveToInbox(RemoteMessage m) async {
  final n = m.notification;
  final title = n?.title ?? m.data['title'] as String?;
  if (title == null || title.isEmpty) return;
  await saveInboxMessage(InboxMessage(
    m.messageId ??
        '${m.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
    title,
    n?.body ?? m.data['body'] as String? ?? '',
    m.sentTime ?? DateTime.now(),
    link: m.data['link'] as String?,
  ));
}

class FcmService {
  static final FcmService instance = FcmService._internal();
  factory FcmService() => instance;
  FcmService._internal();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) return;

      // On Web, FCM requires VAPID key configuration; if not provided, skip gracefully
      if (kIsWeb) {
        debugPrint(
            '[FCM] Web push messaging skipped (requires VAPID configuration).');
        return;
      }

      _messaging = FirebaseMessaging.instance;

      // 1. Register background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Request notification permissions (Android 13+ & iOS)
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      debugPrint('[FCM] AuthorizationStatus: ${settings.authorizationStatus}');

      // 3. Set up local notification channel for Android foreground notifications
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'arunachal_exam_announcements',
        'Exam alerts',
        description:
            'Exam notices, new papers and study reminders from Dawnlit.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Handle foreground notifications
      FirebaseMessaging.onMessageOpenedApp.listen(_saveToInbox);
      final initial = await _messaging!.getInitialMessage();
      if (initial != null) await _saveToInbox(initial);

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _saveToInbox(message);
        final notification = message.notification;
        final android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      // 5. Fetch FCM registration token
      final token = await _messaging!.getToken();
      if (kDebugMode && token != null) debugPrint('[FCM] Device token: $token');

      // Every install receives broadcast messages sent to this topic.
      await _messaging!.subscribeToTopic('all');
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }
}
