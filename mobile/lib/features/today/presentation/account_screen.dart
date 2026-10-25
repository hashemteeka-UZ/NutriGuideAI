import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/session_controller.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Scaffold(
      key: const Key('account-screen'),
      backgroundColor: colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              l10n.tabMe,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: colors.fg, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            _Row(
              key: const Key('account-language'),
              label: l10n.accountLanguage,
              onTap: () {
                unawaited(ref.read(localeProvider.notifier).toggle());
              },
            ),
            _Row(
              key: const Key('account-favourites'),
              label: l10n.mealFavouritesTitle,
              onTap: () => context.push('/meals/favourites'),
            ),
            _Row(
              key: const Key('account-meals'),
              label: l10n.browseMeals,
              onTap: () => context.push('/meals'),
            ),
            _Row(
              key: const Key('account-logout'),
              label: l10n.logout,
              onTap: () {
                unawaited(
                  ref.read(sessionControllerProvider.notifier).logout(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
