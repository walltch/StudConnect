import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/screens/question_detail/question_detail_screen.dart';

import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

Widget _harness(AppRepository repo, String questionId) {
  return ChangeNotifierProvider.value(
    value: repo,
    child: MaterialApp(
      home: QuestionDetailScreen(questionId: questionId),
    ),
  );
}

void main() {
  testWidgets('renders the question and its answers (US3)', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo, 'q1'));
    await settle(tester);

    expect(
      find.textContaining('Comment organiser un projet de groupe avec Git'),
      findsOneWidget,
    );
    expect(find.text('2 réponses'), findsOneWidget);
    expect(find.text('Solution validée'), findsOneWidget);
  });

  testWidgets('submitting the composer adds a real answer (US7)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo, 'q5')); // q5 has 0 answers
    await settle(tester);

    expect(find.text('0 réponse'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Voici une reponse de test bien detaillee.',
    );
    await settle(tester);
    await tester.tap(find.text('Publier ma réponse'));
    await settle(tester);

    expect(
      repo.questionById('q5')!.answers.any(
        (a) => a.content == 'Voici une reponse de test bien detaillee.',
      ),
      isTrue,
    );
    expect(find.text('1 réponse'), findsOneWidget);
  });

  testWidgets('"Je ne peux pas aider" toggles dismissal (US7)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    // q1 is authored by bob, not the current user (wall), so the
    // response actions row is shown.
    await tester.pumpWidget(_harness(repo, 'q1'));
    await settle(tester);

    expect(repo.questionById('q1')!.isDismissed, isFalse);
    await tester.tap(find.text('Je ne peux pas aider'));
    await settle(tester);

    expect(repo.questionById('q1')!.isDismissed, isTrue);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets(
    'author can mark an answer as the validated solution (US4)',
    (tester) async {
      final repo = (await tester.runAsync(buildTestRepository))!;
      addTearDown(() => tester.runAsync(repo.close));
      useTallTestViewport(tester);
      // q2 is authored by wall (current user) and has two unvalidated
      // answers (a3 by alice, a6 by charles) — the author sees "Marquer
      // comme solution" on both; a3 renders first (created earlier).
      await tester.pumpWidget(_harness(repo, 'q2'));
      await settle(tester);

      expect(repo.questionById('q2')!.isSolved, isFalse);
      await tester.tap(find.text('Marquer comme solution').first);
      await settle(tester);

      expect(repo.questionById('q2')!.isSolved, isTrue);
      expect(
        repo.questionById('q2')!.answers.firstWhere((a) => a.id == 'a3').isValidated,
        isTrue,
      );
    },
  );

  testWidgets('shows "Question introuvable" for an unknown id', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo, 'does-not-exist'));
    await settle(tester);

    expect(find.text('Question introuvable'), findsOneWidget);
  });
}
