// C:\dev\memoir\lib\services\notification_service.dart
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
    // Initialization settings for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialization settings for iOS
    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android 13+
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
  }

  // A unique ID for the notification can be generated from the event's properties
  int _generateId(Event event, Note note) {
    return (note.path + event.time.toIso8601String() + event.info).hashCode & 0x7FFFFFFF;
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
      'Reminder: ${event.info}', // More specific title
      'From note: "${note.title}"', // Context in the body
      tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails,
      // The parameter below is for newer versions. It's removed to match your library version.
      // uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime, 
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