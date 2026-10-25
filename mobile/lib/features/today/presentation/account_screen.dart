import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../auth/presentation/session_controller.dart';
import '../../logging/data/logging_providers.dart';
import '../../weight/data/weight_providers.dart';
import '../../weight/presentation/weight_sheet.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final latest = ref.watch(latestWeightProvider).asData?.value;
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
              key: const Key('account-weight'),
              label: latest == null
                  ? l10n.weightNone
                  : l10n.weightLatest(latest.weightKg.toStringAsFixed(1)),
              action: l10n.weightTitle,
              onTap: () => unawaited(showWeightSheet(context)),
            ),
            _Row(
              key: const Key('account-edit'),
              label: l10n.accountEditProfile,
              onTap: () => context.push('/me/edit'),
            ),
            _Row(
              key: const Key('account-language'),
              label: l10n.accountLanguage,
              onTap: () {
                unawaited(ref.read(localeProvider.notifier).toggle());
              },
            ),
            _Row(
              key: const Key('account-appearance'),
              label: l10n.accountAppearance,
              onTap: () => unawaited(showAppearanceSheet(context, ref)),
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
              key: const Key('account-about'),
              label: l10n.accountAbout,
              onTap: () => context.push('/me/about'),
            ),
            _Row(
              key: const Key('account-logout'),
              label: l10n.logout,
              onTap: () => unawaited(confirmLogout(context, ref)),
            ),
            const SizedBox(height: 16),
            _Row(
              key: const Key('account-delete'),
              label: l10n.accountDelete,
              color: context.appColors.danger,
              onTap: () => context.push('/me/delete'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sends the outbox once more, then signs out. Logs that are still on the
/// phone are deleted only after the user agrees (Decision #263).
Future<void> confirmLogout(BuildContext context, WidgetRef ref) async {
  final empty = await ref.read(uploadBeforeLogoutProvider)();
  if (!context.mounted) {
    return;
  }
  if (!empty) {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          key: const Key('logout-pending-dialog'),
          content: Text(l10n.logoutPendingBody),
          actions: <Widget>[
            TextButton(
              key: const Key('logout-pending-cancel'),
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.planCancel),
            ),
            TextButton(
              key: const Key('logout-pending-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.logoutPendingConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }
  }
  await ref.read(sessionControllerProvider.notifier).logout();
}

/// «المظهر»: device, light or dark (#310).
Future<void> showAppearanceSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    builder: (BuildContext context) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          final current = ref.watch(themeModeProvider);
          final labels = <ThemeMode, String>{
            ThemeMode.system: l10n.themeSystem,
            ThemeMode.light: l10n.themeLight,
            ThemeMode.dark: l10n.themeDark,
          };
          return SafeArea(
            child: RadioGroup<ThemeMode>(
              groupValue: current,
              onChanged: (ThemeMode? mode) {
                if (mode != null) {
                  unawaited(ref.read(themeModeProvider.notifier).select(mode));
                }
              },
              child: Column(
                key: const Key('appearance-sheet'),
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final entry in labels.entries)
                    RadioListTile<ThemeMode>(
                      key: Key('theme-${entry.key.name}'),
                      value: entry.key,
                      title: Text(entry.value),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.onTap,
    this.action,
    this.color,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  /// Label color; the danger color for «حذف الحساب».
  final Color? color;

  /// A short call to action shown at the end of the row.
  final String? action;

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
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: color),
                    ),
                  ),
                  if (action != null)
                    Text(action!, style: TextStyle(color: colors.brand)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
