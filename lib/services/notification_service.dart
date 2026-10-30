import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static Function(String, String, String)? onActionCallback;

  // ---------------------------------------------------------------------------
  // Initialisation
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    // 1. Load all timezone data
    tz_data.initializeTimeZones();

    // 2. Set the device's LOCAL timezone so scheduled times fire at the right
    //    local hour (e.g. "Asia/Dhaka" for Bangladesh, not UTC).
    try {
      final String localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {
      // If flutter_timezone fails just stay on UTC — better than crashing.
    }

    // 3. Initialise the plugin
    await _notifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: _handleAction,
      onDidReceiveBackgroundNotificationResponse: _handleAction,
    );

    // 4. Request Android permission (Android 13+)
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
  }

  // ---------------------------------------------------------------------------
  // Action callback (Taken / Missed buttons)
  // ---------------------------------------------------------------------------

  @pragma('vm:entry-point')
  static void _handleAction(NotificationResponse response) {
    final parts = response.payload?.split('|');
    if (parts != null &&
        parts.length >= 2 &&
        response.actionId != null &&
        onActionCallback != null) {
      onActionCallback!(parts[0], parts[1], response.actionId!);
    }
  }

  // ---------------------------------------------------------------------------
  // Notification details (shared between daily & weekly)
  // ---------------------------------------------------------------------------

  NotificationDetails _getDetails() => const NotificationDetails(
    android: AndroidNotificationDetails(
      'medicine_reminders',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine reminders',
      importance: Importance.high,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('taken', 'Taken', showsUserInterface: true),
        AndroidNotificationAction('missed', 'Missed', showsUserInterface: true),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ---------------------------------------------------------------------------
  // Schedule a DAILY repeating notification
  //   - Fires every day at the given time.
  //   - Uses DateTimeComponents.time so Android/iOS auto-repeat it.
  // ---------------------------------------------------------------------------

  Future<void> scheduleDailyNotification({
    required String medicineId,
    required String medicineName,
    required String dose,
    required String time,
    required int notificationId,
  }) async {
    if (kIsWeb) return;

    final parsed = _parseTime(time);
    if (parsed == null) return;

    final scheduledTime = _nextInstanceOfTime(parsed.$1, parsed.$2);

    await _notifications.zonedSchedule(
      notificationId,
      'Time for your medicine! 💊',
      '$medicineName — $dose',
      scheduledTime,
      _getDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // ← KEY FIX: repeat at the same clock-time every single day
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '$medicineId|$time',
    );
  }

  // ---------------------------------------------------------------------------
  // Schedule a WEEKLY repeating notification for one specific day
  //   - day = 'Mon' | 'Tue' | 'Wed' | 'Thu' | 'Fri' | 'Sat' | 'Sun'
  //   - Fires on that weekday at the given time, every week.
  //   - Uses DateTimeComponents.dayOfWeekAndTime for weekly repeat.
  // ---------------------------------------------------------------------------

  Future<void> scheduleWeeklyNotification({
    required String medicineId,
    required String medicineName,
    required String dose,
    required String time,
    required String day,
    required int notificationId,
  }) async {
    if (kIsWeb) return;

    final parsed = _parseTime(time);
    if (parsed == null) return;

    final scheduledTime = _nextInstanceOfDayAndTime(day, parsed.$1, parsed.$2);

    await _notifications.zonedSchedule(
      notificationId,
      'Time for your medicine! 💊',
      '$medicineName — $dose',
      scheduledTime,
      _getDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // ← KEY FIX: repeat on the same weekday + time every week
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: '$medicineId|$time',
    );
  }

  // ---------------------------------------------------------------------------
  // Schedule ALL notifications for a medicine (helper used when adding/restoring)
  //   med = the Firestore document map
  //   docId = the Firestore document ID
  // ---------------------------------------------------------------------------

  Future<void> scheduleForMedicine({
    required String docId,
    required Map<String, dynamic> med,
  }) async {
    if (kIsWeb) return;

    final name = med['name']?.toString() ?? '';
    final dose = med['dose']?.toString() ?? '';
    final schedule = med['schedule']?.toString() ?? 'Daily';
    final times = (med['times'] as List<dynamic>?)?.cast<String>() ?? [];
    final selectedDays =
        (med['selectedDays'] as List<dynamic>?)?.cast<String>() ?? [];

    if (schedule == 'Daily') {
      // One repeating notification per dose-time
      for (final time in times) {
        final id = generateDailyNotificationId(docId, time);
        await scheduleDailyNotification(
          medicineId: docId,
          medicineName: name,
          dose: dose,
          time: time,
          notificationId: id,
        );
      }
    } else {
      // "Specific Days" — one repeating notification per day × per dose-time
      for (final day in selectedDays) {
        for (final time in times) {
          final id = generateWeeklyNotificationId(docId, time, day);
          await scheduleWeeklyNotification(
            medicineId: docId,
            medicineName: name,
            dose: dose,
            time: time,
            day: day,
            notificationId: id,
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel ALL notifications that belong to a medicine
  // ---------------------------------------------------------------------------

  Future<void> cancelForMedicine({
    required String docId,
    required Map<String, dynamic> med,
  }) async {
    if (kIsWeb) return;

    final schedule = med['schedule']?.toString() ?? 'Daily';
    final times = (med['times'] as List<dynamic>?)?.cast<String>() ?? [];
    final selectedDays =
        (med['selectedDays'] as List<dynamic>?)?.cast<String>() ?? [];

    if (schedule == 'Daily') {
      for (final time in times) {
        await cancelNotification(generateDailyNotificationId(docId, time));
      }
    } else {
      for (final day in selectedDays) {
        for (final time in times) {
          await cancelNotification(
            generateWeeklyNotificationId(docId, time, day),
          );
        }
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Cancel helpers
  // ---------------------------------------------------------------------------

  Future<void> cancelNotification(int id) async =>
      !kIsWeb ? await _notifications.cancel(id) : null;

  Future<void> cancelAllNotifications() async =>
      !kIsWeb ? await _notifications.cancelAll() : null;

  // ---------------------------------------------------------------------------
  // Immediate (non-scheduled) notification
  // ---------------------------------------------------------------------------

  Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!kIsWeb) {
      await _notifications.show(
        id,
        title,
        body,
        _getDetails(),
        payload: payload,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Time helpers
  // ---------------------------------------------------------------------------

  /// Returns the next TZDateTime for the given hour/minute.
  /// → Today if the time hasn't passed yet, tomorrow if it has.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Returns the next TZDateTime for the given weekday name + hour/minute.
  /// → Advances day-by-day until both weekday and time conditions are met.
  tz.TZDateTime _nextInstanceOfDayAndTime(String day, int hour, int minute) {
    // DateTime weekday: 1 = Monday, 7 = Sunday
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final targetWeekday = dayNames.indexOf(day) + 1;

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Advance until we land on the right weekday AND the time is in the future
    while (scheduled.weekday != targetWeekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Parse "8:00 AM" / "10:30 PM" → (hour24, minute) record, or null on error.
  (int, int)? _parseTime(String timeStr) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
      caseSensitive: false,
    ).firstMatch(timeStr.trim());
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPM = match.group(3)!.toUpperCase() == 'PM';

    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    return (hour, minute);
  }

  // ---------------------------------------------------------------------------
  // Notification ID generators (stable & unique per medicine + time [+ day])
  // ---------------------------------------------------------------------------

  static int generateDailyNotificationId(String medicineId, String time) =>
      'daily_$medicineId$time'.hashCode.abs() % 2147483647;

  static int generateWeeklyNotificationId(
    String medicineId,
    String time,
    String day,
  ) => 'weekly_$medicineId${time}_$day'.hashCode.abs() % 2147483647;

  /// Legacy alias kept for backward-compatibility with any existing call-sites.
  static int generateNotificationId(String medicineId, String time) =>
      generateDailyNotificationId(medicineId, time);
}
