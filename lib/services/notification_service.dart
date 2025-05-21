import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:logger/logger.dart';
import 'package:ovarian_cyst_support_app/models/medication.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';

final _logger = Logger();

enum NotificationType { medication, appointment }

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  _logger.d('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyMedicationReminders = 'medication_reminders';
  static const String _keyAppointmentReminders = 'appointment_reminders';

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool _initialized = false;

  // Private constructor
  NotificationService._internal();

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone data
    tz_init.initializeTimeZones();

    await _initializeFirebaseMessaging();
    await _initializeLocalNotifications();
    await _setupNotificationTapActions();

    _initialized = true;
    _logger.i('Notification service initialized');
  }

  Future<void> _initializeFirebaseMessaging() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _logger.i(
        'Firebase Messaging authorization status: ${settings.authorizationStatus}');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _logger.d('Got a message whilst in the foreground!');
      _logger.d('Message data: ${message.data}');

      if (message.notification != null) {
        _logger.d(
            'Message contained notification: ${message.notification!.title}');
      }
    });
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      _logger.d('Notification payload: ${response.payload}');
      // Handle notification tap here
    }
  }

  Future<void> _setupNotificationTapActions() async {
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        _logger.d('App launched from notification: $payload');
      }
    }
  }

  Future<bool> get isNotificationsEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    _logger.i('Notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'reminders_channel',
      'Reminders',
      channelDescription: 'Channel for scheduled reminders',
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduledTime = tz.TZDateTime.from(scheduledDate, tz.local);

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // Public method to schedule a notification
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!await isNotificationsEnabled) {
      _logger.i('Notifications are disabled, skipping scheduling');
      return;
    }

    final int notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

    await _scheduleNotification(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      payload: payload,
    );
    _logger.i('Scheduled notification: $title for ${scheduledDate.toString()}');
  }

  Future<void> scheduleMedicationReminder(Medication medication) async {
    if (!medication.reminderEnabled || !await isNotificationsEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> existingReminders =
        prefs.getStringList(_keyMedicationReminders) ?? [];

    final int notificationId = medication.hashCode;
    await _localNotifications.cancel(notificationId);

    final DateTime scheduledDate = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
      medication.time.hour,
      medication.time.minute,
    );

    await _scheduleNotification(
      id: notificationId,
      title: 'Medication Reminder',
      body: 'Time to take ${medication.name}',
      scheduledDate: scheduledDate,
      payload: 'type: medication_reminder, medication: ${medication.name}',
    );

    final String reminderId =
        '${medication.name}_${medication.time.hour}_${medication.time.minute}';
    if (!existingReminders.contains(reminderId)) {
      existingReminders.add(reminderId);
      await prefs.setStringList(_keyMedicationReminders, existingReminders);
    }
  }

  Future<void> scheduleAppointmentReminderWithModel(
      Appointment appointment) async {
    if (!appointment.reminderEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final List<String> existingReminders =
        prefs.getStringList(_keyAppointmentReminders) ?? [];

    final int notificationId = appointment.hashCode;
    await _localNotifications.cancel(notificationId);

    // One day before reminder
    final oneDayBefore = appointment.dateTime.subtract(const Duration(days: 1));
    await _scheduleNotification(
      id: notificationId,
      title: 'Appointment Tomorrow',
      body: 'You have an appointment for ${appointment.purpose} tomorrow',
      scheduledDate: oneDayBefore,
      payload:
          'type: appointment_reminder, appointment: ${appointment.purpose}',
    );

    // One hour before reminder
    final oneHourBefore =
        appointment.dateTime.subtract(const Duration(hours: 1));
    await _scheduleNotification(
      id: notificationId + 1,
      title: 'Upcoming Appointment',
      body: 'You have an appointment for ${appointment.purpose} in 1 hour',
      scheduledDate: oneHourBefore,
      payload:
          'type: appointment_reminder, appointment: ${appointment.purpose}',
    );

    final String reminderId =
        '${appointment.purpose}_${appointment.dateTime.millisecondsSinceEpoch}';
    if (!existingReminders.contains(reminderId)) {
      existingReminders.add(reminderId);
      await prefs.setStringList(_keyAppointmentReminders, existingReminders);
    }
  }

  Future<void> cancelAllReminders() async {
    final prefs = await SharedPreferences.getInstance();
    await _localNotifications.cancelAll();
    await prefs.remove(_keyMedicationReminders);
    await prefs.remove(_keyAppointmentReminders);
    _logger.i('All reminders cancelled');
  }
}

// Keep AppToast separate - it's used by other services
class AppToast {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      isError: false,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context: context,
      message: message,
      isError: true,
    );
  }

  static void _show({
    required BuildContext context,
    required String message,
    required bool isError,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          right: 20,
          left: 20,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration,
      ),
    );
  }
}
