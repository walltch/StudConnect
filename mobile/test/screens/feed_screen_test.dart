import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/screens/feed/feed_screen.dart';

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
    final repo = await buildTestRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur StudConnect 👋'), findsOneWidget);
    expect(find.text('${repo.questionsCount}'), findsOneWidget);
    expect(
      find.textContaining(
        'Comment organiser un projet de groupe avec Git',
      ),
      findsOneWidget,
    );
  });

  testWidgets('"Non résolues" filter hides solved questions', (tester) async {
    final repo = await buildTestRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    // q1 (Git) and q3 (Random Forest) are solved in seed data.
    expect(
      find.textContaining('Comment organiser un projet de groupe avec Git'),
      findsOneWidget,
    );

    await tester.tap(find.text('Non résolues'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Comment organiser un projet de groupe avec Git'),
      findsNothing,
    );
    expect(
      find.textContaining('Alternance : comment gérer'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a tag filters the feed to that tag', (tester) async {
    final repo = await buildTestRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('IA / ML'));
    await tester.pumpAndSettle();

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
    final repo = await buildTestRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(
      find.textContaining('Comment organiser un projet de groupe avec Git'),
    );
    await tester.pumpAndSettle();

    expect(find.text('question-detail-q1'), findsOneWidget);
  });

  testWidgets('upvoting a question updates its count immediately', (
    tester,
  ) async {
    final repo = await buildTestRepository();
    await tester.pumpWidget(_harness(repo));
    await tester.pumpAndSettle();

    // Default sort is "recent": q4 (2026-03-10) renders first.
    final before = repo.questionById('q4')!.upvotes;
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up).first);
    await tester.pumpAndSettle();

    expect(repo.questionById('q4')!.upvotes, before + 1);
  });
}
