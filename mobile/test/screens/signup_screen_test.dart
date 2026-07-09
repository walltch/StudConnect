import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_harness.dart';
import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

// Field order on the signup form: Nom complet(0), Identifiant(1, auto-filled
// from the name but still a real TextField), École(2), Filière(3),
// Année(4), Mot de passe(5), Confirmer le mot de passe(6).

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

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Léa Martin');
    await tester.enterText(fields.at(2), 'ESGI Bordeaux');
    await tester.enterText(fields.at(3), 'Bachelor Réseaux');
    await tester.enterText(fields.at(4), 'B1');
    await settle(tester);

    // Name/école/filière/année filled, but no password yet.
    expect(tester.widget<ElevatedButton>(submitFinder).onPressed, isNull);

    await tester.enterText(fields.at(5), 'secret');
    await tester.enterText(fields.at(6), 'secret');
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
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Léa Martin');
    await tester.enterText(fields.at(2), 'ESGI Bordeaux');
    await tester.enterText(fields.at(3), 'Bachelor Réseaux');
    await tester.enterText(fields.at(4), 'B1');
    await tester.enterText(fields.at(5), 'secret');
    await tester.enterText(fields.at(6), 'secret');
    await settle(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Créer mon compte'));
    await settle(tester);

    expect(repo.isLoggedIn, isTrue);
    expect(repo.currentUser.name, 'Léa Martin');
    expect(repo.currentUser.avatar, 'LM');
    expect(repo.currentUser.username, 'lea.martin');
    expect(find.text('home-feed'), findsOneWidget);
  });

  testWidgets('an already-taken username shows an inline error', (
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

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Bob');
    await settle(tester);

    expect(find.text('Cet identifiant est déjà pris.'), findsOneWidget);
  });
}
