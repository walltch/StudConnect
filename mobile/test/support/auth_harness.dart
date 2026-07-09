import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:studconnect/data/repository.dart';
import 'package:studconnect/screens/auth/login_screen.dart';
import 'package:studconnect/screens/auth/signup_screen.dart';

const _authRoutes = {'/login', '/signup'};

/// Mirrors app_router.dart's redirect logic (the `repo.isLoggedIn` gate)
/// but with a dummy '/' destination, so login/signup screen tests can
/// prove the "signing in navigates away automatically" behavior without
/// pulling in the whole shell/feed/profile stack.
Widget authTestHarness(AppRepository repo) {
  final router = GoRouter(
    initialLocation: '/login',
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: Text('home-feed')),
      ),
    ],
  );
  return ChangeNotifierProvider.value(
    value: repo,
    child: MaterialApp.router(routerConfig: router),
  );
}
