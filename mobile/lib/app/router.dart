import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/session.dart';
import '../features/auth/presentation/auth_form_screen.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/catalog/presentation/favourites_screen.dart';
import '../features/catalog/presentation/meal_detail_screen.dart';
import '../features/catalog/presentation/meals_screen.dart';
import '../features/home/presentation/placeholder_screens.dart';
import '../features/profile/presentation/onboarding_screen.dart';
import '../features/server_check/presentation/server_check_screen.dart';

String? authRedirect({
  required SessionState session,
  required String location,
  required bool allowServerCheck,
}) {
  if (allowServerCheck && location == '/dev/server-check') {
    return null;
  }
  switch (session) {
    case SessionUnknown():
      return location == '/splash' ? null : '/splash';
    case SignedOut(:final reason):
      const allowed = <String>{'/welcome', '/register', '/login'};
      final expired = reason == SignOutReason.sessionExpired;
      if (allowed.contains(location)) {
        if (expired && location != '/login') {
          return '/login';
        }
        return null;
      }
      return expired ? '/login' : '/welcome';
    case SignedIn():
      if (!session.hasProfile) {
        return location == '/onboarding' ? null : '/onboarding';
      }
      if (location == '/home' ||
          location == '/meals' ||
          location.startsWith('/meals/')) {
        return null;
      }
      return '/home';
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(sessionControllerProvider, (_, _) {
    refresh.value++;
  });
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      return authRedirect(
        session: ref.read(sessionControllerProvider),
        location: state.uri.path,
        allowServerCheck: kDebugMode,
      );
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/welcome',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (BuildContext context, GoRouterState state) {
          return const OnboardingScreen();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (BuildContext context, GoRouterState state) {
          return const HomePlaceholderScreen();
        },
      ),
      GoRoute(
        path: '/meals',
        builder: (BuildContext context, GoRouterState state) {
          return const MealsScreen();
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'favourites',
            builder: (BuildContext context, GoRouterState state) {
              return const FavouritesScreen();
            },
          ),
          GoRoute(
            path: ':mealId',
            builder: (BuildContext context, GoRouterState state) {
              return MealDetailScreen(
                mealId: int.tryParse(state.pathParameters['mealId'] ?? ''),
              );
            },
          ),
        ],
      ),
      if (kDebugMode)
        GoRoute(
          path: '/dev/server-check',
          builder: (BuildContext context, GoRouterState state) {
            return const ServerCheckScreen();
          },
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
