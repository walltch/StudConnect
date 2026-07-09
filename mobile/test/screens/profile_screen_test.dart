import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/screens/profile/profile_screen.dart';

import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

Widget _harness(AppRepository repo) {
  final router = GoRouter(
    initialLocation: '/profile',
    refreshListenable: repo,
    redirect: (context, state) {
      if (!repo.isLoggedIn && state.matchedLocation != '/login') {
        return '/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/questions/new',
        builder: (context, state) => Scaffold(
          body: Text(
            'edit-question-${state.uri.queryParameters['questionId']}',
          ),
        ),
      ),
      GoRoute(
        path: '/questions/:id',
        builder: (context, state) => Scaffold(
          body: Text('question-detail-${state.pathParameters['id']}'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const Scaffold(body: Text('login-screen')),
      ),
    ],
  );
  return ChangeNotifierProvider.value(
    value: repo,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders wall\'s profile with live stats and skills (US2)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    expect(find.text('Wall Fatah T.'), findsOneWidget);
    expect(find.text('Python'), findsOneWidget);
    expect(find.text('Mes questions (2)'), findsOneWidget);
    // wall doesn't author any seed answer (a1-a4 are alice/clara).
    expect(find.text('Mes réponses (0)'), findsOneWidget);
  });

  testWidgets('editing profile persists year/field/school (US5)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await settle(tester);

    final yearField = find.widgetWithText(TextField, 'M1');
    await tester.enterText(yearField, 'M2');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
    await settle(tester);

    expect(repo.currentUser.year, 'M2');
  });

  testWidgets('editing profile can also change the name and avatar color', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await settle(tester);

    final nameField = find.widgetWithText(TextField, 'Wall Fatah T.');
    await tester.enterText(nameField, 'Wall Renamed');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
    await settle(tester);

    expect(repo.currentUser.name, 'Wall Renamed');
    expect(repo.currentUser.avatar, 'WR');
  });

  testWidgets('logging out routes back to the login screen', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.tap(find.byIcon(Icons.logout));
    await settle(tester);

    expect(repo.isLoggedIn, isFalse);
    expect(find.text('login-screen'), findsOneWidget);
  });

  testWidgets('adding a skill persists it (US2)', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    final before = repo.currentUser.skills.length;
    await tester.tap(find.text('Ajouter'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Kotlin');
    await tester.tap(find.text('Ajouter').last);
    await settle(tester);

    expect(repo.currentUser.skills.length, before + 1);
    expect(repo.currentUser.skills.contains('Kotlin'), isTrue);
  });

  testWidgets('deleting one of my questions removes it (US4)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    final before = repo.questionsCount;
    await tester.tap(find.text('Supprimer').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer').last);
    await settle(tester);

    expect(repo.questionsCount, before - 1);
  });

  testWidgets('tapping "Modifier" on a question navigates to edit (US4)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    final questionId = repo.myQuestions.first.id;
    await tester.tap(find.text('Modifier').first);
    await settle(tester);

    expect(find.text('edit-question-$questionId'), findsOneWidget);
  });

  testWidgets(
    'switching to "Mes réponses" shows the answers empty state',
    (tester) async {
      final repo = (await tester.runAsync(buildTestRepository))!;
      addTearDown(() => tester.runAsync(repo.close));
      useTallTestViewport(tester);
      await tester.pumpWidget(_harness(repo));
      await settle(tester);

      // wall doesn't author any seed answer.
      expect(
        find.text("Tu n'as pas encore répondu à une question."),
        findsNothing,
      );
      await tester.tap(find.textContaining('Mes réponses'));
      await settle(tester);

      expect(
        find.text("Tu n'as pas encore répondu à une question."),
        findsOneWidget,
      );
    },
  );
}
