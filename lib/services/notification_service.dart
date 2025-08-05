// C:\dev\memoir\lib\services\notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:memoir/models/event_model.dart';
import 'package:memoir/models/note_model.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Platform-specific initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // This cannot be 'const' because AssetsLinuxIcon() is not a const constructor.
    final LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(
      defaultActionName: 'Open',
      defaultIcon: AssetsLinuxIcon('assets/icons/app_icon.png'),
    );

    const WindowsInitializationSettings windowsSettings =
        WindowsInitializationSettings(
      appName: 'Memoir',
      appUserModelId: 'com.example.memoir',
      guid: 'd49b0314-ee7a-4626-bf79-97cdb8a991bb',
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
      windows: windowsSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request platform-specific permissions only on the relevant platform
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }
  
  int _generateId(Event event, Note note) {
    return (note.path + event.time.toIso8601String() + event.info).hashCode &
        0x7FFFFFFF;
  }

  Future<void> scheduleEventNotification(Event event, Note note) async {
    if (event.reminder == null || event.reminder == Duration.zero) return;

    final id = _generateId(event, note);
    final reminderTime = event.time.subtract(event.reminder!);

    if (reminderTime.isBefore(DateTime.now())) {
      // Don't schedule reminders for past events
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'memoir_event_reminders',
      'Event Reminders',
      channelDescription: 'Notifications for upcoming events in your notes.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,

      iOS: darwinDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      'Reminder: ${event.info}',
      'From note: "${note.title}"',
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelEventNotification(Event event, Note note) async {
    final id = _generateId(event, note);
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotificationsForNote(Note note) async {
    for (final event in note.events) {
      if (event.reminder != null) {
        await cancelEventNotification(event, note);
      }
    }
  }
}