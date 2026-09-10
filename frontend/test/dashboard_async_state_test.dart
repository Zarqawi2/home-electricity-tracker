import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/app_dialog_shell.dart';
import 'package:frontend/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:frontend/features/dashboard/presentation/widgets/dashboard_workspace.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardPage(),
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'closing the calculator updates state synchronously',
    (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.byKey(const ValueKey('dashboard-tab-3')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ژمێریاری وزە و تێچوو'));
      await tester.pumpAndSettle();
      expect(find.byType(AppModalCloseButton), findsOneWidget);

      await tester.tap(find.byType(AppModalCloseButton));
      await tester.pumpAndSettle();
      // Also finish deferred controller disposal after the dismissal animation.
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.byType(AppModalCloseButton), findsNothing);
      expect(find.byType(DashboardToolList), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );

  testWidgets(
    'refreshing records replaces the history without a state error',
    (tester) async {
      await pumpDashboard(tester);
      await tester.tap(find.byKey(const ValueKey('dashboard-tab-2')));
      await tester.pumpAndSettle();
      final previousHistory = tester
          .widget<DashboardRecordsSection>(find.byType(DashboardRecordsSection))
          .history;

      await tester
          .widget<RefreshIndicator>(find.byType(RefreshIndicator))
          .onRefresh();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<DashboardRecordsSection>(
              find.byType(DashboardRecordsSection),
            )
            .history,
        isNot(same(previousHistory)),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}
