import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/auth_harness.dart';
import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

void main() {
  testWidgets('submitting the right credentials logs in and routes away', (
    tester,
  ) async {
    final repo = (await tester.runAsync(
      () => buildTestRepository(autoLogin: false),
    ))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(authTestHarness(repo));
    await settle(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'charles');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.text('Se connecter'));
    await settle(tester);

    expect(repo.isLoggedIn, isTrue);
    expect(repo.currentUser.id, 'charles');
    expect(find.text('home-feed'), findsOneWidget);
  });

  testWidgets('a wrong password shows an inline error and stays logged out', (
    tester,
  ) async {
    final repo = (await tester.runAsync(
      () => buildTestRepository(autoLogin: false),
    ))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(authTestHarness(repo));
    await settle(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'charles');
    await tester.enterText(fields.at(1), 'not-the-password');
    await tester.tap(find.text('Se connecter'));
    await settle(tester);

    expect(repo.isLoggedIn, isFalse);
    expect(find.text('Identifiant ou mot de passe incorrect.'), findsOneWidget);
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

  testWidgets(
    'expanding "Comptes de démo" and tapping one logs in directly',
    (tester) async {
      final repo = (await tester.runAsync(
        () => buildTestRepository(autoLogin: false),
      ))!;
      addTearDown(() => tester.runAsync(repo.close));
      useTallTestViewport(tester);
      await tester.pumpWidget(authTestHarness(repo));
      await settle(tester);

      expect(find.text('Charles Keita'), findsNothing);
      await tester.tap(find.text('Comptes de démo'));
      await settle(tester);

      expect(find.text('Charles Keita'), findsOneWidget);
      await tester.tap(find.text('Charles Keita'));
      await settle(tester);

      expect(repo.isLoggedIn, isTrue);
      expect(repo.currentUser.id, 'charles');
      expect(find.text('home-feed'), findsOneWidget);
    },
  );
}
