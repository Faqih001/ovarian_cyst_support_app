import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'package:ovarian_cyst_support_app/models/medication.dart';
import 'package:ovarian_cyst_support_app/models/appointment.dart';

class NotificationService {
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyMedicationReminders = 'medication_reminders';
  static const String _keyAppointmentReminders = 'appointment_reminders';

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // Flutter Local Notifications Plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Firebase Messaging instance
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  // Notification Settings
  NotificationSettings? settings;

  // Initialize notification service
  static Future<void> initialize() async {
    // Get instance
    final instance = NotificationService();

    // Initialize timezone database
    tz_init.initializeTimeZones();

    // Initialize Firebase Messaging
    await instance._initializeFirebaseMessaging();

    // Initialize local notifications
    await instance._initializeLocalNotifications();

    // Handle notification tap
    instance._setupNotificationTapActions();

    debugPrint(
      'Enhanced notification service initialized with Firebase Cloud Messaging',
    );
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? false;
  }

  // Toggle notifications on/off
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  // Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Request permission
    settings = await firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Configure Firebase Messaging handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Get FCM token
    String? token = await firebaseMessaging.getToken();
    debugPrint('FCM Token: $token');

    // Subscribe to topics
    await firebaseMessaging.subscribeToTopic('all_users');
    await firebaseMessaging.subscribeToTopic('ovarian_cyst_updates');
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  // Setup notification tap actions
  void _setupNotificationTapActions() {
    // Check if app was opened from a notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  // Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message received: ${message.notification?.title}');

    // Show local notification
    _showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.notification?.title}');

    // Parse data payload
    final Map<String, dynamic> data = message.data;

    // Handle navigation based on notification type
    if (data.containsKey('type')) {
      _navigateBasedOnNotificationType(data['type'], data);
    }
  }

  // Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');

    // Parse payload
    if (response.payload != null) {
      try {
        // Convert string payload to map and navigate
        // In a real app, this would be proper JSON parsing
        final payload = response.payload!;
        if (payload.contains('type')) {
          final type = payload.split('type:')[1].split(',')[0].trim();
          _navigateBasedOnNotificationType(type, {});
        }
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  // Navigate based on notification type
  void _navigateBasedOnNotificationType(
    String type,
    Map<String, dynamic> data,
  ) {
    // This would be implemented to push navigation routes based on notification type
    switch (type) {
      case 'appointment_reminder':
        // Navigate to appointments page
        break;
      case 'medication_reminder':
        // Navigate to medication page
        break;
      case 'symptom_alert':
        // Navigate to symptom tracking page
        break;
      case 'new_message':
        // Navigate to community chat
        break;
      case 'new_article':
        // Navigate to education page
        break;
      default:
        // Navigate to home page
        break;
    }
  }

  // Show a local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ovarian_cyst_support_channel',
      'Ovarian Cyst Support',
      channelDescription: 'Notifications for the Ovarian Cyst Support app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Schedule a notification at a future time
  Future<void> _scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ovarian_cyst_reminder_channel',
      'Reminders',
      channelDescription: 'Scheduled reminders',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Convert DateTime to TZDateTime
    final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
      scheduledTime,
      tz.local,
    );

    // Schedule notification
    await flutterLocalNotificationsPlugin.zonedSchedule(
      scheduledTime.millisecond, // Unique ID
      title,
      body,
      tzScheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  // Public method to schedule notifications
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }

    await _scheduleNotification(
      title: title,
      body: body,
      scheduledTime: scheduledDate,
      payload: payload,
    );
  }

  // Schedule medication reminder
  static Future<void> scheduleMedicationReminder(Medication medication) async {
    if (!medication.reminderEnabled) {
      return;
    }

    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }

    // Store in SharedPreferences (for compatibility)
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList(_keyMedicationReminders) ?? [];

    final reminderData = {
      'id':
          '${medication.name}_${medication.time.hour}_${medication.time.minute}',
      'title': 'Medication Reminder',
      'body': 'Time to take ${medication.name} (${medication.dosage})',
      'hour': medication.time.hour,
      'minute': medication.time.minute,
      'frequency': medication.frequency,
    };

    reminders.add(reminderData.toString());
    await prefs.setStringList(_keyMedicationReminders, reminders);

    // Schedule with enhanced notification service
    final instance = NotificationService();
    final now = DateTime.now();
    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      medication.time.hour,
      medication.time.minute,
    );

    // If the time has already passed today, schedule for tomorrow
    final actualScheduledTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await instance._scheduleNotification(
      title: reminderData['title'] as String,
      body: reminderData['body'] as String,
      scheduledTime: actualScheduledTime,
      payload: 'type: medication_reminder, medication: ${medication.name}',
    );

    debugPrint(
      'Enhanced medication reminder scheduled: ${reminderData['title']} at ${reminderData['hour']}:${reminderData['minute']}',
    );
  }

  // Cancel medication reminder
  static Future<void> cancelMedicationReminder(Medication medication) async {
    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList(_keyMedicationReminders) ?? [];

    final reminderId =
        '${medication.name}_${medication.time.hour}_${medication.time.minute}';
    final updatedReminders =
        reminders.where((reminder) => !reminder.contains(reminderId)).toList();

    await prefs.setStringList(_keyMedicationReminders, updatedReminders);

    // Cancel with enhanced notification service
    // This is a simplified approach - in a real app you'd store the exact notification ID
    final notificationId = (medication.name.hashCode +
            medication.time.hour +
            medication.time.minute) %
        10000;
    final instance = NotificationService();
    await instance.flutterLocalNotificationsPlugin.cancel(notificationId);

    debugPrint('Canceled medication reminder for ${medication.name}');
  }

  // Schedule appointment reminder using Appointment model
  static Future<void> scheduleAppointmentReminderWithModel(
    Appointment appointment,
  ) async {
    if (!appointment.reminderEnabled) {
      return;
    }

    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }

    // Store in SharedPreferences (for compatibility)
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList(_keyAppointmentReminders) ?? [];

    // Schedule reminder for 1 day before appointment
    final reminderTime = appointment.dateTime.subtract(const Duration(days: 1));

    final reminderData = {
      'id':
          '${appointment.purpose}_${appointment.dateTime.millisecondsSinceEpoch}',
      'title': 'Appointment Reminder',
      'body':
          'You have an appointment for ${appointment.purpose} with Dr. ${appointment.doctorName} tomorrow',
      'year': reminderTime.year,
      'month': reminderTime.month,
      'day': reminderTime.day,
      'hour': reminderTime.hour,
      'minute': reminderTime.minute,
    };

    reminders.add(reminderData.toString());
    await prefs.setStringList(_keyAppointmentReminders, reminders);

    // Schedule with enhanced notification service
    final instance = NotificationService();

    // Schedule one day before
    await instance._scheduleNotification(
      title: reminderData['title'] as String,
      body: reminderData['body'] as String,
      scheduledTime: reminderTime,
      payload:
          'type: appointment_reminder, appointment: ${appointment.purpose}',
    );

    // Also schedule one hour before
    final hourBeforeReminder = appointment.dateTime.subtract(
      const Duration(hours: 1),
    );
    await instance._scheduleNotification(
      title: 'Upcoming Appointment',
      body:
          'Your appointment for ${appointment.purpose} with Dr. ${appointment.doctorName} is in 1 hour',
      scheduledTime: hourBeforeReminder,
      payload:
          'type: appointment_reminder, appointment: ${appointment.purpose}',
    );

    debugPrint(
      'Enhanced appointment reminders scheduled for ${appointment.purpose}',
    );
  }

  // Cancel appointment reminder
  static Future<void> cancelAppointmentReminder(Appointment appointment) async {
    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList(_keyAppointmentReminders) ?? [];

    final reminderId =
        '${appointment.purpose}_${appointment.dateTime.millisecondsSinceEpoch}';
    final updatedReminders =
        reminders.where((reminder) => !reminder.contains(reminderId)).toList();

    await prefs.setStringList(_keyAppointmentReminders, updatedReminders);

    // Cancel with enhanced notification service
    // This is a simplified approach - in a real app you'd store the exact notification IDs
    final notificationId = appointment.dateTime.millisecondsSinceEpoch % 10000;
    final instance = NotificationService();
    await instance.flutterLocalNotificationsPlugin.cancel(notificationId);
    await instance.flutterLocalNotificationsPlugin.cancel(notificationId + 1);

    debugPrint('Canceled appointment reminders for ${appointment.purpose}');
  }

  // Cancel all reminders
  static Future<void> cancelAllReminders() async {
    // Update SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMedicationReminders);
    await prefs.remove(_keyAppointmentReminders);

    // Cancel all notifications
    final instance = NotificationService();
    await instance.flutterLocalNotificationsPlugin.cancelAll();

    debugPrint('Canceled all reminders');
  }

  // Schedule appointment reminder
  static Future<void> scheduleAppointmentReminder(
    String appointmentId,
    DateTime appointmentDateTime,
    String providerName,
    String appointmentPurpose,
    String location,
  ) async {
    // Get notification settings
    final bool notificationsEnabled = await areNotificationsEnabled();
    if (!notificationsEnabled) {
      debugPrint(
        'Notifications are disabled. Skipping appointment reminder scheduling.',
      );
      return;
    }

    // Store in SharedPreferences (for compatibility)
    final prefs = await SharedPreferences.getInstance();
    final reminders = prefs.getStringList(_keyAppointmentReminders) ?? [];

    // Schedule reminder for 1 day before appointment
    final reminderTime = appointmentDateTime.subtract(const Duration(days: 1));

    final reminderData = {
      'id':
          '${appointmentPurpose}_${appointmentDateTime.millisecondsSinceEpoch}',
      'title': 'Appointment Reminder',
      'body':
          'You have an appointment for $appointmentPurpose with $providerName tomorrow at $location',
      'year': reminderTime.year,
      'month': reminderTime.month,
      'day': reminderTime.day,
      'hour': reminderTime.hour,
      'minute': reminderTime.minute,
    };

    reminders.add(reminderData.toString());
    await prefs.setStringList(_keyAppointmentReminders, reminders);

    // Schedule with enhanced notification service
    final instance = NotificationService();

    // Schedule one day before
    await instance._scheduleNotification(
      title: reminderData['title'] as String,
      body: reminderData['body'] as String,
      scheduledTime: reminderTime,
      payload: 'type: appointment_reminder, appointment: $appointmentPurpose',
    );

    // Also schedule one hour before
    final hourBeforeReminder = appointmentDateTime.subtract(
      const Duration(hours: 1),
    );
    await instance._scheduleNotification(
      title: 'Upcoming Appointment',
      body:
          'Your appointment for $appointmentPurpose with $providerName is in 1 hour',
      scheduledTime: hourBeforeReminder,
      payload: 'type: appointment_reminder, appointment: $appointmentPurpose',
    );

    debugPrint(
      'Enhanced appointment reminders scheduled for $appointmentPurpose',
    );
  }
}
