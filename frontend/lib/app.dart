import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'router.dart';

class ElectricityApp extends StatelessWidget {
  const ElectricityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Electricity Management App',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ckb', 'IQ'),
      supportedLocales: const [Locale('ckb', 'IQ'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      localeResolutionCallback: (locale, supported) {
        // Fallback to English material strings because ckb is not provided by stock delegates.
        if (locale == null || locale.languageCode == 'ckb') {
          return const Locale('en');
        }
        return supported.firstWhere(
          (l) => l.languageCode == locale.languageCode,
          orElse: () => const Locale('en'),
        );
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
