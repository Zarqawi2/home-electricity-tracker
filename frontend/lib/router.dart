import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/dashboard/presentation/pages/outage_log_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/onboarding/presentation/viewmodels/onboarding_view_model.dart';
import 'features/splash/presentation/pages/splash_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: onboardingSeenNotifier,
  redirect: (BuildContext context, GoRouterState state) {
    final hasSeenOnboarding = onboardingSeenNotifier.value;
    final isOnSplashRoute = state.uri.path == '/splash';
    final isOnOnboardingRoute = state.uri.path == '/onboarding';

    if (isOnSplashRoute) {
      return null;
    }
    if (!hasSeenOnboarding && !isOnOnboardingRoute) {
      return '/onboarding';
    }
    if (hasSeenOnboarding && isOnOnboardingRoute) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (BuildContext context, GoRouterState state) {
        return const SplashPage();
      },
    ),
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (BuildContext context, GoRouterState state) {
        return const OnboardingPage();
      },
    ),
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (BuildContext context, GoRouterState state) {
        return const DashboardPage();
      },
    ),
    GoRoute(
      path: '/outage-log',
      name: 'outage-log',
      builder: (BuildContext context, GoRouterState state) {
        return const OutageLogPage();
      },
    ),
  ],
);
