import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_harness.dart';
import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

void main() {
  testWidgets('submit button disabled until all fields are filled', (
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

    final submitFinder = find.widgetWithText(
      ElevatedButton,
      'Créer mon compte',
    );
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNull);

    await tester.enterText(
      find.byType(TextField).at(0),
      'Léa Martin',
    );
    await tester.enterText(find.byType(TextField).at(1), 'ESGI Bordeaux');
    await tester.enterText(find.byType(TextField).at(2), 'Bachelor Réseaux');
    await tester.enterText(find.byType(TextField).at(3), 'B1');
    await settle(tester);

    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNotNull);
  });

  testWidgets('submitting creates an account and routes to the feed', (
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

    // Avatar color defaults to the first palette entry; no interaction
    // needed with the picker for signup to be valid.
    await tester.enterText(find.byType(TextField).at(0), 'Léa Martin');
    await tester.enterText(find.byType(TextField).at(1), 'ESGI Bordeaux');
    await tester.enterText(find.byType(TextField).at(2), 'Bachelor Réseaux');
    await tester.enterText(find.byType(TextField).at(3), 'B1');
    await settle(tester);

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Créer mon compte'),
    );
    await settle(tester);

    expect(repo.isLoggedIn, isTrue);
    expect(repo.currentUser.name, 'Léa Martin');
    expect(repo.currentUser.avatar, 'LM');
    expect(find.text('home-feed'), findsOneWidget);
  });
}
