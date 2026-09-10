import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/splash/presentation/pages/splash_page.dart';

GoRouter _splashRouter() => GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      pageBuilder: (context, state) =>
          const NoTransitionPage(child: SplashPage()),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: Scaffold(body: Text('Home destination')),
      ),
    ),
  ],
);

void main() {
  for (final viewport in [const Size(800, 600), const Size(320, 240)]) {
    testWidgets('Shows minimal splash branding at $viewport', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = viewport;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _splashRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      final splash = find.byType(SplashPage);
      expect(splash, findsOneWidget);
      final scaffold = tester.widget<Scaffold>(
        find.descendant(of: splash, matching: find.byType(Scaffold)),
      );
      expect(scaffold.backgroundColor, Colors.white);

      final logo = find.descendant(of: splash, matching: find.byType(Image));
      expect(logo, findsOneWidget);
      expect(
        tester.widget<Image>(logo).image,
        isA<AssetImage>().having(
          (image) => image.assetName,
          'assetName',
          'assets/img/icon.png',
        ),
      );
      expect(tester.getCenter(logo).dx, viewport.width / 2);

      final title = find.text('ڕووناکی');
      expect(title, findsOneWidget);
      expect(
        tester.getTopLeft(title).dy,
        greaterThan(tester.getBottomLeft(logo).dy),
      );
      expect(
        find.descendant(of: splash, matching: find.byType(Text)),
        findsOneWidget,
      );
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(ClipOval), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
    });
  }

  testWidgets('Navigates home on the next frame without a delay', (
    tester,
  ) async {
    final router = _splashRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(SplashPage), findsOneWidget);

    await tester.pump();

    expect(find.text('Home destination'), findsOneWidget);
    expect(find.byType(SplashPage), findsNothing);
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(tester.takeException(), isNull);
  });
}
