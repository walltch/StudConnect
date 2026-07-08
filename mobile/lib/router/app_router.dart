import 'package:go_router/go_router.dart';

import '../screens/feed/feed_screen.dart';
import '../screens/new_question/new_question_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/question_detail/question_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../widgets/shared/app_scaffold.dart';

/// Routes mirror the web app's URL shape (/, /questions/:id,
/// /questions/new, /profile, /search) so both clients share the same
/// mental model of navigation.
GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (context, state) => const FeedScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                builder: (context, state) => const SearchScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/questions/new',
        builder: (context, state) => NewQuestionScreen(
          questionId: state.uri.queryParameters['questionId'],
        ),
      ),
      GoRoute(
        path: '/questions/:id',
        builder: (context, state) =>
            QuestionDetailScreen(questionId: state.pathParameters['id']!),
      ),
    ],
  );
}
