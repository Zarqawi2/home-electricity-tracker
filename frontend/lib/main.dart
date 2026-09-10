import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'features/onboarding/presentation/viewmodels/onboarding_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  onboardingSeenNotifier.value = await _loadOnboardingSeenSafely();

  runApp(const ProviderScope(child: ElectricityApp()));
  unawaited(_runPostLaunchInitialization());
}

Future<void> _runPostLaunchInitialization() async {
  unawaited(_setSystemUiModeSafely());

  final notificationPermissionFuture = _requestNotificationPermissionIfNeeded();

  var notificationsReady = false;
  try {
    await NotificationService.instance.initialize().timeout(
      const Duration(seconds: 5),
    );
    await NotificationService.instance
        .handleInitialNotificationActionIfAny()
        .timeout(const Duration(seconds: 5));
    notificationsReady = true;
  } catch (_) {
    // Ignore notification initialization failures to avoid startup hangs.
    notificationsReady = false;
  }

  if (!notificationsReady) {
    return;
  }

  bool notificationPermissionGranted = false;
  try {
    notificationPermissionGranted = await notificationPermissionFuture.timeout(
      const Duration(seconds: 5),
    );
  } catch (_) {
    notificationPermissionGranted = false;
  }

  if (notificationPermissionGranted) {
    try {
      await NotificationService.instance.ensureDailyReminderScheduled().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {
      // Ignore scheduling failures; app should still function.
    }
    try {
      await NotificationService.instance
          .ensureOutageControlNotification()
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ignore quick-control notification failures; app should still function.
    }
  }
}

Future<void> _setSystemUiModeSafely() async {
  try {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  } catch (_) {
    // Ignore system UI mode failures to avoid blocking app startup.
  }
}

Future<bool> _loadOnboardingSeenSafely() async {
  try {
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(seconds: 3),
    );
    return prefs.getBool('has_seen_onboarding') ?? false;
  } catch (_) {
    return false;
  }
}

Future<bool> _requestNotificationPermissionIfNeeded() async {
  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  if (!isAndroid) {
    return false;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final promptedBefore =
        prefs.getBool('notification_permission_prompted_v1') ?? false;

    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited || status.isProvisional) {
      await prefs.setBool('notification_permission_prompted_v1', true);
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      await prefs.setBool('notification_permission_prompted_v1', true);
      return false;
    }

    // Avoid showing the permission prompt on every app launch.
    if (promptedBefore) {
      return false;
    }

    final requested = await Permission.notification.request();
    await prefs.setBool('notification_permission_prompted_v1', true);
    return requested.isGranted ||
        requested.isLimited ||
        requested.isProvisional;
  } catch (_) {
    return false;
  }
}
