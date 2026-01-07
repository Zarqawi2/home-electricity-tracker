import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'network/dio_client.dart';

/// Core application-level providers shared across features.
final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnv();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(appConfigProvider));
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});
