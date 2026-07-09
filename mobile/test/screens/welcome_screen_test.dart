import 'package:flutter_test/flutter_test.dart';

import '../support/auth_harness.dart';
import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

void main() {
  testWidgets('lists every local account, including teammates', (
    tester,
  ) async {
    final repo = (await tester.runAsync(
      () => buildTestRepository(autoLogin: false),
    ))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(authTestHarness(repo));
    await settle(tester);

    expect(find.text('Wall Fatah T.'), findsOneWidget);
    expect(find.text('Charles Keita'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });

  testWidgets('tapping an account logs in and routes away automatically', (
    tester,
  ) async {
    final repo = (await tester.runAsync(
      () => buildTestRepository(autoLogin: false),
    ))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(authTestHarness(repo));
    await settle(tester);

    expect(repo.isLoggedIn, isFalse);
    await tester.tap(find.text('Charles Keita'));
    await settle(tester);

    expect(repo.isLoggedIn, isTrue);
    expect(repo.currentUser.id, 'charles');
    expect(find.text('home-feed'), findsOneWidget);
  });

  testWidgets('tapping "Créer un compte" navigates to signup', (
    tester,
  ) async {
    final repo = (await tester.runAsync(
      () => buildTestRepository(autoLogin: false),
    ))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(authTestHarness(repo));
    await settle(tester);

    await tester.tap(find.text('Créer un compte'));
    await settle(tester);

    expect(find.text('Créer un compte'), findsOneWidget); // AppBar title now
    expect(find.text('Nom complet *'), findsOneWidget);
  });
}
