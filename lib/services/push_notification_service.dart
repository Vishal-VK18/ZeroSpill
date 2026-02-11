import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // 0. Initialize Timezones
    tz.initializeTimeZones();

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) print('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      if (kDebugMode) print('User granted provisional permission');
    } else {
      if (kDebugMode) print('User declined or has not accepted permission');
    }

    // 2. Initialize Local Notifications (for foreground & scheduling)
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 3. Foreground Message Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
        _showForegroundNotification(message);
      }
    });

    // 4. Background Message Handling
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Save Token (if logged in)
    await saveTokenToFirestore();
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'zerospill_priority_channel', // id
            'High Importance Notifications', // title
            channelDescription: 'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  static Future<void> saveTokenToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? token = await getToken();
    if (token == null) return;

    if (kDebugMode) print("Saving FCM Token: $token");

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(), // Track when token was last updated
      }, SetOptions(merge: true)); // Merge to avoid overwriting existing user data
    } catch (e) {
      if (kDebugMode) print("Error saving FCM token: $e");
    }
  }

  /// Schedules a local notification for pantry item expiry.
  /// 
  /// [itemId] is used to generate a unique notification ID.
  /// [itemName] is displayed in the notification body.
  /// [expiryDate] is the target expiry date.
  /// [notifyBeforeDays] is how many days before expiry to notify.
  static Future<void> scheduleExpiryNotification({
    required String itemId,
    required String itemName,
    required DateTime expiryDate,
    required int notifyBeforeDays,
  }) async {
    final int notificationId = itemId.hashCode;
    
    // Calculate the reminder date
    final DateTime reminderDate = expiryDate.subtract(Duration(days: notifyBeforeDays));
    final DateTime now = DateTime.now();

    // Notification Details
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'zerospill_expiry_channel',
      'Expiry Alerts',
      channelDescription: 'Notifications for expiring pantry items.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // Logic:
    // If reminderDate is in the past or today (meaning we are already late or it's time),
    // trigger immediate notification IF expiry hasn't passed more than a day ago (optional, but good UX).
    // Or just strictly follow: if reminderDate <= now, show immediately.
    
    // Actually, if expiryDate is today, we want "Expires today".
    // If reminderDate is today (and expiry is future), we want "Expiring in X days".
    
    // Simplification for user request:
    // "If reminderDate > now -> schedule"
    // "If expiryDate == today -> show immediate"
    
    // Let's refine for a robust implementation:
    // 1. If today is exactly or after expiryDate: "Item has expired/expires today!"
    // 2. If today is reminderDate or after (but before expiry): "Item is expiring soon!"
    
    // User logic: reminderDate = expiryDate - notifyBeforeDays
    
    if (reminderDate.isAfter(now)) {
      // Schedule for future
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId,
          'Pantry Alert',
          '$itemName is expiring in $notifyBeforeDays days',
          tz.TZDateTime.from(reminderDate, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        if (kDebugMode) print("Scheduled notification for $itemName at $reminderDate (ID: $notificationId)");
      } catch (e) {
         if (kDebugMode) print("Error scheduling notification: $e");
      }
    } else {
      // Immediate notification if valid
      // Preventing spam: only if expiryDate is still in the future or today
      // (If it expired a year ago, don't notify now just because we added it)
      // However, usually items are added fresh.
      
      String body = '$itemName is expiring soon!';
      if (expiryDate.year == now.year && expiryDate.month == now.month && expiryDate.day == now.day) {
         body = '$itemName expires today!';
      } else if (expiryDate.isBefore(now)) {
         body = '$itemName has expired!';
      }
      
      await _flutterLocalNotificationsPlugin.show(
        notificationId,
        'Pantry Alert',
        body,
        platformChannelSpecifics,
      );
      if (kDebugMode) print("Shown immediate notification for $itemName (ID: $notificationId)");
    }
  }

  static Future<void> cancelNotification(String itemId) async {
    final int notificationId = itemId.hashCode;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    if (kDebugMode) print("Canceled notification for item $itemId (ID: $notificationId)");
  }
}
