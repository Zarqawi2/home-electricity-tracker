import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/dashboard/data/datasources/local_appliance_store.dart';

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.instance.handleNotificationResponse(response);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final LocalApplianceStore _store = LocalApplianceStore();

  static const int _dailyReminderId = 1001;
  static const int _outageControlId = 1002;
  static const String _dailyReminderEnabledKey = 'daily_reminder_enabled';
  static const String _dailyReminderHourKey = 'daily_reminder_hour';
  static const String _dailyReminderMinuteKey = 'daily_reminder_minute';
  static const String _outageStartActionId = 'outage_start';
  static const String _outageStopActionId = 'outage_stop';

  static const int _defaultHour = 20;
  static const int _defaultMinute = 0;

  bool _initialized = false;

  bool get _supportsNotifications =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (!_supportsNotifications) {
      return;
    }
    if (_initialized) {
      return;
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    await _configureTimezone();
    _initialized = true;
  }

  Future<void> ensureDailyReminderScheduled() async {
    if (!_supportsNotifications) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_dailyReminderEnabledKey) ?? true;

    if (!enabled) {
      await cancelDailyReminder();
      return;
    }

    final hasPermission = await _hasNotificationPermission();
    if (!hasPermission) {
      return;
    }

    final hour = prefs.getInt(_dailyReminderHourKey) ?? _defaultHour;
    final minute = prefs.getInt(_dailyReminderMinuteKey) ?? _defaultMinute;
    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  Future<void> setDailyReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyReminderEnabledKey, enabled);

    if (enabled) {
      await ensureDailyReminderScheduled();
    } else {
      await cancelDailyReminder();
    }
  }

  Future<void> setDailyReminderTime({
    required int hour,
    required int minute,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyReminderHourKey, hour);
    await prefs.setInt(_dailyReminderMinuteKey, minute);
    await ensureDailyReminderScheduled();
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
  }) async {
    if (!_supportsNotifications) {
      return;
    }
    await initialize();

    final next = _nextInstanceOfTime(hour: hour, minute: minute);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      '⏰ بیرخستنەوەی ڕووناکی',
      '⚡ ئەمڕۆ بەکارهێنانی کارەبا و ئامێرەکانت پشکنە.',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_usage_reminder',
          'بیرخستنەوەی ڕۆژانە',
          channelDescription:
              'بیرخستنەوەی ڕۆژانە بۆ چاودێریکردنی کارەبا و خەرجی.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'daily_usage_reminder',
    );
  }

  Future<void> cancelDailyReminder() async {
    if (!_supportsNotifications) {
      return;
    }
    await _plugin.cancel(_dailyReminderId);
  }

  Future<void> ensureOutageControlNotification() async {
    if (!_supportsNotifications) {
      return;
    }
    await initialize();

    final hasPermission = await _hasNotificationPermission();
    if (!hasPermission) {
      return;
    }

    final trackingStart = await _store.getOutageTrackingStart();
    final isTracking = trackingStart != null;
    final action = AndroidNotificationAction(
      isTracking ? _outageStopActionId : _outageStartActionId,
      isTracking ? 'وەستاندن' : 'دەستپێکردن',
      icon: DrawableResourceAndroidBitmap(
        isTracking ? 'ic_outage_stop' : 'ic_outage_start',
      ),
      // Keep action in background, do not launch app UI on tap.
      showsUserInterface: false,
      cancelNotification: false,
    );

    var body = isTracking
        ? 'تۆمارکردنی قەطعبوون چالاکە.'
        : 'کاتێک کارەبا قەطع بوو، "دەستپێکردن" دابگرە.';

    if (trackingStart != null) {
      body =
          '$body ${_formatElapsedForNotification(DateTime.now().difference(trackingStart))}';
    }

    await _plugin.show(
      _outageControlId,
      'کۆنترۆڵی خێرای قەطعبوون',
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'outage_quick_control',
          'کۆنترۆڵی خێرا',
          channelDescription:
              'لە ئاگادارکردنەوەوە تۆمارکردنی قەطعبوون دەستپێبکە یان بوەستێنە.',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          showWhen: isTracking,
          when: isTracking ? trackingStart.millisecondsSinceEpoch : null,
          usesChronometer: isTracking,
          chronometerCountDown: false,
          actions: <AndroidNotificationAction>[action],
        ),
      ),
      payload: 'outage_quick_control',
    );
  }

  Future<void> handleInitialNotificationActionIfAny() async {
    if (!_supportsNotifications) {
      return;
    }
    await initialize();
    final details = await _plugin.getNotificationAppLaunchDetails();
    final response = details?.notificationResponse;
    if (response == null) {
      return;
    }
    final actionId = response.actionId;
    if (actionId == _outageStartActionId || actionId == _outageStopActionId) {
      await handleNotificationResponse(response);
    }
  }

  Future<void> handleNotificationResponse(NotificationResponse response) async {
    if (!_supportsNotifications) {
      return;
    }
    try {
      final actionId = response.actionId;
      if (actionId == _outageStartActionId) {
        await _store.startOutageTracking();
        await ensureOutageControlNotification();
        return;
      }
      if (actionId == _outageStopActionId) {
        await _store.stopOutageTracking();
        await ensureOutageControlNotification();
        return;
      }
      // Fallback: some devices may return no actionId for action taps.
      // Only handle this for action-button responses, never for notification
      // body taps to avoid accidental start/stop toggles.
      if (response.payload == 'outage_quick_control' &&
          response.notificationResponseType ==
              NotificationResponseType.selectedNotificationAction) {
        final isTracking = await _store.isOutageTrackingActive();
        if (isTracking) {
          await _store.stopOutageTracking();
        } else {
          await _store.startOutageTracking();
        }
        await ensureOutageControlNotification();
        return;
      }
    } catch (_) {
      // Ignore action processing errors to avoid crashing notification callback.
      if (kDebugMode) {
        debugPrint('Notification action failed: ${response.actionId}');
      }
    }
  }

  Future<void> _configureTimezone() async {
    tz.initializeTimeZones();
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
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

  Future<bool> _hasNotificationPermission() async {
    if (!_supportsNotifications) {
      return false;
    }

    try {
      final status = await Permission.notification.status;
      return status.isGranted || status.isLimited || status.isProvisional;
    } catch (_) {
      return false;
    }
  }

  String _formatElapsedForNotification(Duration duration) {
    final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  void _onForegroundNotificationResponse(NotificationResponse response) {
    unawaited(handleNotificationResponse(response));
  }
}
