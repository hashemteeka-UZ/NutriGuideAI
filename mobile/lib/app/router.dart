import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ui/motion.dart';
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
import '../features/reminders/presentation/reminders_screen.dart';
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
      location == '/me/about' ||
      location == '/me/reminders') {
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
      StatefulShellRoute(
        navigatorContainerBuilder:
            (
              BuildContext context,
              StatefulNavigationShell navigationShell,
              List<Widget> children,
            ) {
              return FadeThroughBranches(
                currentIndex: navigationShell.currentIndex,
                children: children,
              );
            },
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
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      return sharedAxisPage(
                        context,
                        state,
                        const ShoppingScreen(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'item/:planItemId',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (BuildContext context, GoRouterState state) {
                      return sharedAxisPage(
                        context,
                        state,
                        PlanItemScreen(
                          planItemId: int.tryParse(
                            state.pathParameters['planItemId'] ?? '',
                          ),
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
        pageBuilder: (BuildContext context, GoRouterState state) {
          return sharedAxisPage(context, state, const EditProfileScreen());
        },
      ),
      GoRoute(
        path: '/me/delete',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return sharedAxisPage(context, state, const DeleteAccountScreen());
        },
      ),
      GoRoute(
        path: '/me/reminders',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return sharedAxisPage(context, state, const RemindersScreen());
        },
      ),
      GoRoute(
        path: '/me/about',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return sharedAxisPage(context, state, const AboutScreen());
        },
      ),
      GoRoute(
        path: '/log/meal',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return sharedAxisPage(context, state, const OtherMealScreen());
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
        pageBuilder: (BuildContext context, GoRouterState state) {
          return sharedAxisPage(context, state, const MealsScreen());
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'favourites',
            pageBuilder: (BuildContext context, GoRouterState state) {
              return sharedAxisPage(context, state, const FavouritesScreen());
            },
          ),
          GoRoute(
            path: ':mealId',
            pageBuilder: (BuildContext context, GoRouterState state) {
              final mealId = int.tryParse(state.pathParameters['mealId'] ?? '');
              return sharedAxisPage(
                context,
                state,
                ViewEvent(
                  mealId: mealId,
                  child: MealDetailScreen(mealId: mealId),
                ),
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
