import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/accent.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/kit.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';
import '../../catalog/data/healthy_meals.dart';
import '../../logging/data/logging_providers.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/user_context.dart';
import '../../plan/domain/plan.dart';
import '../../plan/presentation/plan_format.dart';
import '../../profile/data/display_name.dart';
import '../../profile/presentation/name_page.dart';
import '../../progress/data/progress_providers.dart';
import '../../weight/data/weight_providers.dart';
import '../../weight/presentation/weight_sheet.dart';
import 'today_look.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final latest = ref.watch(latestWeightProvider).asData?.value;
    final user = ref.watch(userContextProvider);
    final session = ref.watch(sessionControllerProvider);
    final email = session is SignedIn ? session.account?.email : null;
    final streak = ref.watch(streakProvider).asData?.value ?? 0;
    final likes = ref.watch(likeCountProvider).asData?.value ?? 0;
    final dislikes = ref.watch(dislikeCountProvider).asData?.value ?? 0;
    final windows =
        ref.watch(todayWindowsProvider).asData?.value ??
        const <MealWindowSpan>[];
    final weightKg = latest?.weightKg ?? user?.latestWeightKg;
    final name = ref.watch(displayNameProvider);
    void edit() => context.push('/me/edit');
    return Scaffold(
      key: const Key('account-screen'),
      backgroundColor: colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: <Widget>[
            Text(
              l10n.tabMe,
              style: TextStyle(
                fontSize: 24,
                height: 1.25,
                color: colors.fg,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            GradientHero(
              key: const Key('account-header'),
              onTap: () => unawaited(showNameSheet(context, ref)),
              child: Row(
                children: <Widget>[
                  EmojiTile(
                    avatarEmoji(user?.sex),
                    size: 64,
                    emojiSize: 46,
                    radius: 20,
                    background: const Color(0x33FFFFFF),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name ?? l10n.accountHello,
                          key: const Key('account-name'),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (email != null)
                          Text(
                            email,
                            key: const Key('account-email'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xE6FFFFFF),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (streak > 0)
                    Column(
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Emoji('fire', size: 18),
                            const SizedBox(width: 4),
                            Text(
                              formatWhole(context, streak),
                              style: const TextStyle(
                                fontFamily: 'Readex Pro',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          l10n.accountStreakDays,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xD9FFFFFF),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Group(
              children: <Widget>[
                _Row(
                  key: const Key('account-edit'),
                  emoji: 'bullseye',
                  label: l10n.accountGoal,
                  value: user == null ? null : _goalLabel(l10n, user.goalType),
                  onTap: edit,
                ),
                _Row(
                  emoji: 'straight-ruler',
                  label: l10n.accountHeightWeight,
                  value: user?.heightCm == null
                      ? null
                      : '${formatWhole(context, user!.heightCm!)} · ${weightKg == null ? '—' : weightKg.toStringAsFixed(1)}',
                  onTap: edit,
                ),
                _Row(
                  emoji: 'person-biking',
                  label: l10n.accountActivity,
                  value: _activityLabel(l10n, user?.activityLevel),
                  onTap: edit,
                ),
                _Row(
                  emoji: 'stethoscope',
                  label: l10n.accountCare,
                  value: user == null
                      ? null
                      : user.conditions.isEmpty
                      ? l10n.onbCareNone
                      : formatWhole(context, user.conditions.length),
                  onTap: edit,
                ),
                _Row(
                  emoji: 'shield',
                  label: l10n.accountAvoid,
                  value: user == null
                      ? null
                      : user.allergenCodes.isEmpty
                      ? l10n.onbCareNone
                      : formatWhole(context, user.allergenCodes.length),
                  onTap: edit,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _RhythmCard(
              windows: windows,
              wake: user?.wakeMinutes,
              sleep: user?.sleepMinutes,
              onEdit: edit,
            ),
            const SizedBox(height: 14),
            _Group(
              children: <Widget>[
                _Row(
                  key: const Key('account-favourites'),
                  emoji: 'red-heart',
                  label: l10n.mealFavouritesTitle,
                  value: formatWhole(context, likes),
                  onTap: () => context.push('/meals/favourites'),
                ),
                _Row(
                  key: const Key('account-dislikes'),
                  emoji: 'thumbs-down',
                  label: l10n.accountDislikes,
                  value: formatWhole(context, dislikes),
                  onTap: () => context.push('/meals/favourites'),
                ),
                _Row(
                  key: const Key('account-meals'),
                  emoji: 'fork-and-knife-with-plate',
                  label: l10n.browseMeals,
                  onTap: () => context.push('/meals'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Group(
              children: <Widget>[
                _Row(
                  key: const Key('account-weight'),
                  emoji: 'balance-scale',
                  label: latest == null
                      ? l10n.weightNone
                      : l10n.weightLatest(latest.weightKg.toStringAsFixed(1)),
                  action: l10n.weightTitle,
                  onTap: () => unawaited(showWeightSheet(context)),
                ),
                _Row(
                  key: const Key('account-reminders'),
                  emoji: 'bell',
                  label: l10n.accountReminders,
                  onTap: () => context.push('/me/reminders'),
                ),
                _Row(
                  key: const Key('account-language'),
                  emoji: 'world-map',
                  label: l10n.accountLanguage,
                  onTap: () {
                    unawaited(ref.read(localeProvider.notifier).toggle());
                  },
                ),
                _Row(
                  key: const Key('account-appearance'),
                  emoji: 'artist-palette',
                  label: l10n.accountAppearance,
                  onTap: () => unawaited(showAppearanceSheet(context, ref)),
                ),
                _Row(
                  key: const Key('account-about'),
                  emoji: 'scroll',
                  label: l10n.accountAbout,
                  onTap: () => context.push('/me/about'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colors.signalSoft,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.signal.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Emoji('seedling', size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.accountDisclaimer,
                      style: TextStyle(fontSize: 13.5, color: colors.fg),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _Group(
              children: <Widget>[
                _Row(
                  key: const Key('account-logout'),
                  emoji: 'waving-hand',
                  label: l10n.logout,
                  onTap: () => unawaited(confirmLogout(context, ref)),
                ),
                _Row(
                  key: const Key('account-delete'),
                  emoji: 'warning',
                  label: l10n.accountDelete,
                  color: colors.danger,
                  onTap: () => context.push('/me/delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _goalLabel(AppLocalizations l10n, String goal) {
  return switch (goal) {
    'LOSE' => l10n.onbGoalLose,
    'GAIN' => l10n.onbGoalGain,
    _ => l10n.onbGoalMaintain,
  };
}

String? _activityLabel(AppLocalizations l10n, String? level) {
  return switch (level) {
    'SEDENTARY' => l10n.onbActSedentary,
    'LIGHT' => l10n.onbActLight,
    'MODERATE' => l10n.onbActModerate,
    'HIGH' => l10n.onbActHigh,
    'ATHLETE' => l10n.onbActAthlete,
    _ => null,
  };
}

String _clock(BuildContext context, int minutes) {
  final value = minutes % (24 * 60);
  final hours = (value ~/ 60).toString().padLeft(2, '0');
  final mins = (value % 60).toString().padLeft(2, '0');
  return formatHm(context, '$hours:$mins');
}

/// «مواعيد يومي»: the start of each meal window, and wake and sleep.
class _RhythmCard extends StatelessWidget {
  const _RhythmCard({
    required this.windows,
    required this.wake,
    required this.sleep,
    required this.onEdit,
  });

  final List<MealWindowSpan> windows;
  final int? wake;
  final int? sleep;
  final VoidCallback onEdit;

  static const _slots = <(String, String)>[
    ('BREAKFAST', 'sunrise'),
    ('LUNCH', 'sun'),
    ('SNACK', 'red-apple'),
    ('DINNER', 'crescent-moon'),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    String? startOf(String slot) {
      for (final window in windows) {
        if (window.slot == slot) {
          return formatHm(context, window.start);
        }
      }
      return null;
    }

    final shown = <(String, String, String)>[
      for (final (slot, emoji) in _slots)
        if (startOf(slot) case final String start) (slot, emoji, start),
    ];
    return AppCard(
      key: const Key('account-rhythm'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Emoji('alarm-clock', size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.accountRhythm,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                key: const Key('account-rhythm-edit'),
                onPressed: onEdit,
                child: Text(
                  l10n.accountEditShort,
                  style: TextStyle(
                    color: colors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (shown.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                for (final (slot, emoji, start) in shown)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Semantics(
                        label: '${slotLabel(l10n, slot)} $start',
                        excludeSemantics: true,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: colors.surface2,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: <Widget>[
                              Emoji(emoji, size: 22),
                              const SizedBox(height: 2),
                              Text(
                                start,
                                style: colors.numeric.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colors.fg,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (wake != null && sleep != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(
              l10n.accountWakeSleep(
                _clock(context, sleep!),
                _clock(context, wake!),
              ),
              style: TextStyle(fontSize: 13, color: colors.fg3),
            ),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) Divider(height: 1, color: colors.line),
            children[i],
          ],
        ],
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

/// «المظهر»: device, light or dark (#310), and the app colour (V5).
Future<void> showAppearanceSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Consumer(
        builder: (BuildContext context, WidgetRef ref, Widget? _) {
          final colors = context.appColors;
          final current = ref.watch(themeModeProvider);
          final accent = ref.watch(accentChoiceProvider);
          final dark = Theme.of(context).brightness == Brightness.dark;
          final labels = <ThemeMode, String>{
            ThemeMode.system: l10n.themeSystem,
            ThemeMode.light: l10n.themeLight,
            ThemeMode.dark: l10n.themeDark,
          };
          final swatches = <AccentChoice, (AccentPalette, String)>{
            AccentChoice.emerald: (AccentPalette.emerald, l10n.accentEmerald),
            AccentChoice.teal: (AccentPalette.teal, l10n.accentTeal),
            AccentChoice.plum: (AccentPalette.plum, l10n.accentPlum),
          };
          return SafeArea(
            child: SingleChildScrollView(
              child: RadioGroup<ThemeMode>(
                groupValue: current,
                onChanged: (ThemeMode? mode) {
                  if (mode != null) {
                    unawaited(
                      ref.read(themeModeProvider.notifier).select(mode),
                    );
                  }
                },
                child: Column(
                  key: const Key('appearance-sheet'),
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (final entry in labels.entries)
                      RadioListTile<ThemeMode>(
                        key: Key('theme-${entry.key.name}'),
                        value: entry.key,
                        title: Text(entry.value),
                      ),
                    Divider(height: 1, color: colors.line),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                      child: Row(
                        children: <Widget>[
                          const Emoji('artist-palette', size: 22),
                          const SizedBox(width: 8),
                          Text(
                            l10n.accentTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: <Widget>[
                          ChoiceChip(
                            key: const Key('accent-auto'),
                            avatar: const Emoji('sparkles', size: 16),
                            label: Text(l10n.accentAuto),
                            selected: accent == AccentChoice.auto,
                            onSelected: (_) => unawaited(
                              ref
                                  .read(accentChoiceProvider.notifier)
                                  .select(AccentChoice.auto),
                            ),
                          ),
                          for (final entry in swatches.entries)
                            _Swatch(
                              key: Key('accent-${entry.key.name}'),
                              color: dark
                                  ? entry.value.$1.dark.$1
                                  : entry.value.$1.light.$1,
                              check: dark
                                  ? entry.value.$1.dark.$3
                                  : entry.value.$1.light.$3,
                              label: entry.value.$2,
                              selected: accent == entry.key,
                              onTap: () => unawaited(
                                ref
                                    .read(accentChoiceProvider.notifier)
                                    .select(entry.key),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Text(
                        l10n.accentNote,
                        style: TextStyle(fontSize: 12.5, color: colors.fg3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.check,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Color color;
  final Color check;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface, width: 2),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 20, color: check)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.onTap,
    required this.emoji,
    this.value,
    this.action,
    this.color,
    super.key,
  });

  final String label;
  final VoidCallback onTap;
  final String emoji;

  /// The current value, faint, before the chevron.
  final String? value;

  /// Label color; the danger color for «حذف الحساب».
  final Color? color;

  /// A short call to action shown at the end of the row.
  final String? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          child: Row(
            children: <Widget>[
              Emoji(emoji, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? colors.fg,
                  ),
                ),
              ),
              if (value != null) ...<Widget>[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: colors.numeric.copyWith(
                      fontSize: 13,
                      color: colors.fg3,
                    ),
                  ),
                ),
              ],
              if (action != null) ...<Widget>[
                const SizedBox(width: 8),
                Text(action!, style: TextStyle(color: colors.brand)),
              ],
              const SizedBox(width: 6),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: colors.fg3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
