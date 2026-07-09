import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/screens/search/search_screen.dart';

import '../support/pump_helpers.dart';
import '../support/test_repository.dart';

Widget _harness(AppRepository repo) {
  final router = GoRouter(
    initialLocation: '/search',
    routes: [
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
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
  testWidgets('shows all 4 seed questions with an empty query', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    expect(find.text('5 résultats'), findsOneWidget);
  });

  testWidgets('typing a keyword matches content, not just title (US6)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'XGBoost');
    await settle(tester);

    expect(find.text('1 résultat'), findsOneWidget);
    expect(
      find.textContaining('Différence entre Random Forest'),
      findsOneWidget,
    );
  });

  testWidgets('a query with no match shows the empty state', (tester) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'zzz-inexistant-zzz');
    await settle(tester);

    expect(find.text('Aucun résultat'), findsOneWidget);
  });

  testWidgets('tag filter combines with the text query (US6)', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    // The tall test viewport also reveals q3's own tag badge — the
    // filter chip is first in the tree (renders above the results).
    await tester.tap(find.text('IA / ML').first);
    await settle(tester);

    expect(find.text('1 résultat'), findsOneWidget);
    expect(
      find.textContaining('Différence entre Random Forest'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a result navigates to its detail route', (
    tester,
  ) async {
    final repo = (await tester.runAsync(buildTestRepository))!;
    addTearDown(() => tester.runAsync(repo.close));
    useTallTestViewport(tester);
    await tester.pumpWidget(_harness(repo));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'XGBoost');
    await settle(tester);
    await tester.tap(find.textContaining('Différence entre Random Forest'));
    await settle(tester);

    expect(find.text('question-detail-q3'), findsOneWidget);
  });
}
