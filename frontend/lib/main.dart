import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/onboarding/presentation/viewmodels/onboarding_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
  onboardingSeenNotifier.value = hasSeenOnboarding;

  runApp(const ProviderScope(child: ElectricityApp()));
}
