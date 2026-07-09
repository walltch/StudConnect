import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/screens/feed/feed_screen.dart';

import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

Widget _harness(AppRepository repo) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
      GoRoute(
        path: '/questions/new',
        builder: (context, state) =>
            const Scaffold(body: Text('new-question-screen')),
      ),
      GoRoute(
        path: '/questions/:id',
        builder: (context, state) => Scaffold(
          body: Text('question-detail-${state.pathParameters['id']}'),
        ),
      ),
    ],
  );
  return ChangeNotifierProvider.value(
    value: repo,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('renders the seed questions and live stats', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    expect(find.text('Bienvenue sur StudConnect 👋'), findsOneWidget);
    // Both questionsCount and answersCount happen to be 4 in seed data,
    // so this stat renders at least once rather than exactly once.
    expect(find.text('${repo.questionsCount}'), findsWidgets);
    // Default sort is "recent": q4 is the newest, so it's the only
    // card guaranteed to be within the initial viewport (the ListView
    // doesn't build off-screen siblings).
    expect(
      find.textContaining('Comment structurer mon rapport de stage'),
      findsOneWidget,
    );
  });

  testWidgets('"Non résolues" filter hides solved questions', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    // q3 (Random Forest) is solved and, being 2nd most recent, is
    // reachable in the initial viewport without scrolling.
    expect(
      find.textContaining('Différence entre Random Forest'),
      findsOneWidget,
    );

    await tester.tap(find.text('Non résolues'));
    await settle(tester);

    expect(
      find.textContaining('Différence entre Random Forest'),
      findsNothing,
    );
    // q4 (unsolved, most recent) stays visible after filtering.
    expect(
      find.textContaining('Comment structurer mon rapport de stage'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a tag filters the feed to that tag', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    // With the tall test viewport, q3's own tag badge is also visible
    // and shares the same text as the filter chip — the chip is first
    // in the tree (filter row renders above the question list).
    await tester.tap(find.text('IA / ML').first);
    await settle(tester);

    expect(
      find.textContaining('Différence entre Random Forest'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Comment structurer mon rapport de stage'),
      findsNothing,
    );
  });

  testWidgets('tapping a question card navigates to its detail route', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.tap(
      find.textContaining('Comment structurer mon rapport de stage'),
    );
    await settle(tester);

    expect(find.text('question-detail-q4'), findsOneWidget);
  });

  testWidgets('upvoting a question updates its count immediately', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    // Default sort is "recent": q4 (2026-03-10) renders first.
    final before = repo.questionById('q4')!.upvotes;
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up).first);
    await settle(tester);

    expect(repo.questionById('q4')!.upvotes, before + 1);
  });
}
