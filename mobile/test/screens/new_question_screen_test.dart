import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/screens/new_question/new_question_screen.dart';

import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

Widget _harness(AppRepository repo, {String? questionId}) {
  final router = GoRouter(
    initialLocation: '/questions/new',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Text('home-after-pop')),
      ),
      GoRoute(
        path: '/questions/new',
        builder: (context, state) =>
            NewQuestionScreen(questionId: questionId),
      ),
    ],
  );
  return ChangeNotifierProvider.value(
    value: repo,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('submit button disabled until title/tag/content filled', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    final submitButtonFinder = find.widgetWithText(
      ElevatedButton,
      'Publier ma question',
    );
    expect(
      tester.widget<ElevatedButton>(submitButtonFinder).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Un titre de question suffisamment clair',
    );
    await tester.tap(find.text('Informatique'));
    await tester.enterText(
      find.byType(TextField).last,
      'Une description détaillée du problème rencontré.',
    );
    await settle(tester);

    expect(
      tester.widget<ElevatedButton>(submitButtonFinder).onPressed,
      isNotNull,
    );
  });

  testWidgets('submitting creates a real question (US1)', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    final before = repo.questionsCount;
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.enterText(
      find.byType(TextField).first,
      'Comment tester un formulaire Flutter ?',
    );
    await tester.tap(find.text('Informatique'));
    await tester.enterText(
      find.byType(TextField).last,
      'Contenu de la question de test end-to-end.',
    );
    await settle(tester);
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Publier ma question'),
    );
    await settle(tester);

    expect(repo.questionsCount, before + 1);
    expect(
      repo.questions.any(
        (q) => q.title == 'Comment tester un formulaire Flutter ?',
      ),
      isTrue,
    );
    // Submit navigates back (context.pop()).
    expect(find.text('home-after-pop'), findsOneWidget);
  });

  testWidgets('edit mode prefills fields and updates instead of creating (US4)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    final before = repo.questionsCount;
    await tester.pumpWidget(_harness(repo, questionId: 'q1'));
    await settle(tester);

    final titleField = tester.widget<TextField>(find.byType(TextField).first);
    expect(
      titleField.controller!.text,
      'Comment organiser un projet de groupe avec Git quand on débute ?',
    );
    final saveButtonFinder = find.widgetWithText(
      ElevatedButton,
      'Enregistrer',
    );
    expect(saveButtonFinder, findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'Titre modifié pour le test',
    );
    await settle(tester);
    await tester.tap(saveButtonFinder);
    await settle(tester);

    expect(repo.questionsCount, before); // no new question created
    expect(repo.questionById('q1')!.title, 'Titre modifié pour le test');
  });
}
