import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService.instance;
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[FCM Background] Message received: ${message.messageId}');
  } catch (e) {
    debugPrint('[FCM Background] Error: $e');
  }
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
        debugPrint('[FCM] Web push messaging skipped (requires VAPID configuration).');
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
        'Exam Alerts & Study Updates',
        description:
            'Notifications for daily mock tests, PYQ updates, and APSSB/APPSC alerts.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 4. Handle foreground notifications
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
            '[FCM Foreground] Message received: ${message.notification?.title}');
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
      if (token != null) {
        debugPrint('[FCM] Device Token: $token');
      }

      // 6. Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token refreshed: $newToken');
      });
    } catch (e) {
      debugPrint('[FCM] Initialization error: $e');
    }
  }
}
