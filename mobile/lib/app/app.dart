import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../core/locale/locale_controller.dart';
import '../core/network/dio_provider.dart';
import '../core/network/server_wake_banner.dart';
import '../core/theme/accent.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/auth/data/auth_interceptor.dart';
import '../features/auth/domain/session.dart';
import '../features/auth/presentation/session_controller.dart';
import '../features/catalog/presentation/catalog_lifecycle.dart';
import '../features/logging/presentation/sync_lifecycle.dart';
import '../features/plan/data/user_context.dart';
import '../features/plan/presentation/plan_lifecycle.dart';
import '../features/reminders/data/reminders_controller.dart';
import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    ref.watch(authInterceptorProvider);
    ref.watch(serverWarmUpProvider);
    ref.watch(catalogLifecycleProvider);
    ref.watch(planLifecycleProvider);
    ref.watch(syncLifecycleProvider);
    ref.watch(remindersLifecycleProvider);
    // The accent follows the goal once the profile is known (V5); signed
    // out, the app keeps its default identity.
    final signedIn = ref.watch(sessionControllerProvider) is SignedIn;
    final goal = ref.watch(
      userContextProvider.select((user) => user?.goalType),
    );
    final accent = signedIn
        ? accentFor(ref.watch(accentChoiceProvider), goal: goal)
        : null;
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (BuildContext context, Widget? child) =>
          ServerWakeBanner(child: child ?? const SizedBox.shrink()),
      theme: AppTheme.light(accent: accent),
      darkTheme: AppTheme.dark(accent: accent),
      themeMode: ref.watch(themeModeProvider),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
