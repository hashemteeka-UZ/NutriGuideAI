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
import '../features/logging/presentation/other_meal_screen.dart';
import '../features/logging/presentation/view_event.dart';
import '../features/plan/data/plan_providers.dart';
import '../features/plan/presentation/plan_item_screen.dart';
import '../features/plan/presentation/plan_screen.dart';
import '../features/plan/presentation/showcase_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/profile/presentation/onboarding_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/server_check/presentation/server_check_screen.dart';
import '../features/shopping/presentation/shopping_screen.dart';
import '../features/today/presentation/about_screen.dart';
import '../features/today/presentation/account_screen.dart';
import '../features/today/presentation/delete_account_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/water/presentation/water_screen.dart';
import 'shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

String? authRedirect({
  required SessionState session,
  required String location,
  required bool allowServerCheck,
  bool openShowcase = false,
  bool recheck = false,
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
      if (recheck && location == '/onboarding') {
        return null;
      }
      if (openShowcase && location != '/generate') {
        return '/generate';
      }
      if (_signedInLocation(location)) {
        return null;
      }
      return '/today';
  }
}

bool _signedInLocation(String location) {
  const exact = <String>{
    '/today',
    '/plan',
    '/water',
    '/progress',
    '/me',
    '/generate',
    '/plan/shopping',
  };
  if (exact.contains(location)) {
    return true;
  }
  if (location == '/log/meal' || location.startsWith('/plan/item/')) {
    return true;
  }
  if (location == '/me/edit' ||
      location == '/me/delete' ||
      location == '/me/about') {
    return true;
  }
  return location == '/meals' || location.startsWith('/meals/');
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(sessionControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.listen(launchShowcaseProvider, (_, _) {
    refresh.value++;
  });
  ref.listen(recheckOnboardingProvider, (_, _) {
    refresh.value++;
  });
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (BuildContext context, GoRouterState state) {
      return authRedirect(
        session: ref.read(sessionControllerProvider),
        location: state.uri.path,
        allowServerCheck: kDebugMode,
        openShowcase: ref.read(launchShowcaseProvider),
        recheck: ref.read(recheckOnboardingProvider),
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
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return AppShell(navigationShell: navigationShell);
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/today',
                builder: (BuildContext context, GoRouterState state) {
                  return const TodayScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/plan',
                builder: (BuildContext context, GoRouterState state) {
                  return const PlanScreen();
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'shopping',
                    builder: (BuildContext context, GoRouterState state) {
                      return const ShoppingScreen();
                    },
                  ),
                  GoRoute(
                    path: 'item/:planItemId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (BuildContext context, GoRouterState state) {
                      return PlanItemScreen(
                        planItemId: int.tryParse(
                          state.pathParameters['planItemId'] ?? '',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/water',
                builder: (BuildContext context, GoRouterState state) {
                  return const WaterScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/progress',
                builder: (BuildContext context, GoRouterState state) {
                  return const ProgressScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/me',
                builder: (BuildContext context, GoRouterState state) {
                  return const AccountScreen();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/me/edit',
        builder: (BuildContext context, GoRouterState state) {
          return const EditProfileScreen();
        },
      ),
      GoRoute(
        path: '/me/delete',
        builder: (BuildContext context, GoRouterState state) {
          return const DeleteAccountScreen();
        },
      ),
      GoRoute(
        path: '/me/about',
        builder: (BuildContext context, GoRouterState state) {
          return const AboutScreen();
        },
      ),
      GoRoute(
        path: '/log/meal',
        builder: (BuildContext context, GoRouterState state) {
          return const OtherMealScreen();
        },
      ),
      GoRoute(
        path: '/generate',
        builder: (BuildContext context, GoRouterState state) {
          return const ShowcaseScreen();
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
              final mealId = int.tryParse(state.pathParameters['mealId'] ?? '');
              return ViewEvent(
                mealId: mealId,
                child: MealDetailScreen(mealId: mealId),
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
