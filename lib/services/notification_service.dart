import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // Android 13+
    await androidPlugin?.requestNotificationsPermission();

    // Android exact alarms
    await androidPlugin?.requestExactAlarmsPermission();
  }

  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for AI Work Planner tasks',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      999999,
      'AI Work Planner',
      'Notification system is working!',
      details,
    );
  }

  static Future<void> scheduleTaskReminder({
    required int notificationId,
    required String taskTitle,
    required DateTime dueDate,
  }) async {
    final reminderDate = dueDate.subtract(const Duration(minutes: 15));
    if (reminderDate.isBefore(DateTime.now())) {
      return;
    }

    final scheduledTime = tz.TZDateTime.from(reminderDate, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Notifications for AI Work Planner tasks',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      notificationId,
      'Task Reminder',
      '"$taskTitle" is due in 15 minutes.',
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_reminder',
    );
  }

  static Future<void> cancelNotification(int notificationId) async {
    await _notifications.cancel(notificationId);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> scheduleTaskReminderFromParts({
    required String taskId,
    required String taskTitle,
    required DateTime? dueDate,
    required String dueTime,
  }) async {
    if (dueDate == null || dueTime.trim().isEmpty) return;

    final dueDateTime = reminderDateFromParts(dueDate, dueTime);
    if (dueDateTime == null) return;

    await cancelNotification(taskId.hashCode);
    await scheduleTaskReminder(
      notificationId: taskId.hashCode,
      taskTitle: taskTitle,
      dueDate: dueDateTime,
    );
  }

  static DateTime? reminderDateFromParts(DateTime? dueDate, String dueTime) {
    if (dueDate == null || dueTime.trim().isEmpty) return null;

    final time = _parseTime(dueTime);
    if (time == null) return null;

    return DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      time.hour,
      time.minute,
    ).subtract(const Duration(minutes: 15));
  }

  static TimeOfDay? _parseTime(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return null;

    var hour = int.tryParse(match.group(1)!) ?? -1;
    final minute = int.tryParse(match.group(2)!) ?? -1;
    final period = match.group(3)!.toUpperCase();
    if (hour < 1 || hour > 12 || minute < 0 || minute > 59) return null;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour, minute: minute);
  }
}
