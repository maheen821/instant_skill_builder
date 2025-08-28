import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    final AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings settings = InitializationSettings(android: androidInit);
    await _notifications.initialize(settings);
  }

  Future<void> showDailyNotification() async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_lesson', 'Daily Lesson', channelDescription: 'Reminder for daily lesson',
        importance: Importance.max, priority: Priority.high);

    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notifications.showDailyAtTime(
      0,
      'Instant Skill Builder',
      'Check your daily lesson!',
      Time(9, 0, 0), // 9:00 AM
      details,
    );
  }
}
