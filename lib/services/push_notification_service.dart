import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles Firebase Cloud Messaging setup and foreground message listening.
/// Received messages are stored so the Profile screen can display them.
class PushNotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // In-memory notification log — Profile screen reads from this list.
  static final List<AppNotification> notifications = [];

  // Listeners notified when a new notification arrives.
  static final List<VoidCallback> _listeners = [];

  static void addListener(VoidCallback cb) => _listeners.add(cb);
  static void removeListener(VoidCallback cb) => _listeners.remove(cb);
  static void _notify() {
    for (final cb in List.of(_listeners)) {
      cb();
    }
  }

  static Future<void> initialize() async {
    // Request permissions (required for iOS; harmless on Android)
    // await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Log the FCM token for debugging / server-side targeting
    final token = await _fcm.getToken();
    debugPrint('FCM Token: $token');

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground: ${message.messageId}');
      final n = AppNotification.fromRemoteMessage(message);
      notifications.insert(0, n);
      _notify();
    });

    // When the user taps a notification that opened the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final n = AppNotification.fromRemoteMessage(message);
      n.isRead; // mark as opened
      notifications.insert(0, n);
      _notify();
    });
  }

  static void markAllRead() {
    for (final n in notifications) {
      n.isRead = true;
    }
    _notify();
  }

  static int get unreadCount => notifications.where((n) => !n.isRead).length;
}

/// A single notification entry displayed in the Notification Center.
class AppNotification {
  final String title;
  final String body;
  final DateTime receivedAt;
  bool isRead;

  AppNotification({
    required this.title,
    required this.body,
    required this.receivedAt,
    this.isRead = false,
  });

  void markRead() => isRead = true;

  factory AppNotification.fromRemoteMessage(RemoteMessage message) {
    return AppNotification(
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? message.data.toString(),
      receivedAt: DateTime.now(),
    );
  }
}
