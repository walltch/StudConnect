import 'package:go_router/go_router.dart';

import '../data/repository.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/welcome_screen.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/new_question/new_question_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/question_detail/question_detail_screen.dart';
import '../screens/search/search_screen.dart';
import '../widgets/shared/app_scaffold.dart';

const _authRoutes = {'/login', '/signup'};

/// Routes mirror the web app's URL shape (/, /questions/:id,
/// /questions/new, /profile, /search) so both clients share the same
/// mental model of navigation. `/login` and `/signup` sit outside the
/// bottom-nav shell and are gated by [repo.isLoggedIn] via `redirect`:
/// every screen that assumes a signed-in AppRepository.currentUser is
/// unreachable while logged out.
GoRouter buildAppRouter(AppRepository repo) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: repo,
    redirect: (context, state) {
      final loggedIn = repo.isLoggedIn;
      final onAuthRoute = _authRoutes.contains(state.matchedLocation);
      if (!loggedIn && !onAuthRoute) return '/login';
      if (loggedIn && onAuthRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
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
