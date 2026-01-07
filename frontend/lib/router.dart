import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/onboarding/presentation/pages/onboarding_page.dart';
import 'features/onboarding/presentation/viewmodels/onboarding_view_model.dart';

GoRouter appRouter = GoRouter(
  initialLocation: onboardingSeenNotifier.value ? '/' : '/onboarding',
  routes: [
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
  ],
);
