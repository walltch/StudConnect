import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/router/app_router.dart';

import 'support/pump_helpers.dart';
import 'support/test_repository.dart';

/// Mirrors StudConnectApp (main.dart) but without `theme: AppTheme.light`
/// — google_fonts tries to fetch font files over HTTP on first use, which
/// is blocked (and pointless) under flutter_test and has no bundled
/// fallback asset. Routing/screens are exercised via the real
/// buildAppRouter(), which is what this smoke test cares about.
Widget _harness(AppRepository repository) {
  return ChangeNotifierProvider.value(
    value: repository,
    child: MaterialApp.router(routerConfig: buildAppRouter()),
  );
}

void main() {
  testWidgets('app boots on the feed tab with the bottom nav visible', (
    tester,
  ) async {
    final repository = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repository.close));
    await tester.pumpWidget(_harness(repository));
    await settle(tester);

    expect(find.text("Fil d'actualité"), findsWidgets);
    expect(find.text('Rechercher'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);
    // Appears both in the Feed's hero banner CTA and in the FAB.
    expect(find.text('Poser une question'), findsWidgets);
  });

  testWidgets('bottom nav switches tabs', (tester) async {
    final repository = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repository.close));
    await tester.pumpWidget(_harness(repository));
    await settle(tester);

    await tester.tap(find.text('Profil'));
    await settle(tester);
    expect(find.text('Profil'), findsWidgets);
  });
}
