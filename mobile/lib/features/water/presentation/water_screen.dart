import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/motion.dart';
import '../../../core/ui/rise_in.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/data/user_context.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/water_providers.dart';
import '../domain/water.dart';

/// The Water tab (Decisions #269, #270), looking like prototype water().
class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      await ref
          .read(waterRepositoryProvider)
          .refresh(ref.read(planClockProvider)());
    } on Object {
      // The cached total stays on screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final view = ref.watch(todayWaterProvider);
    final today = ref.watch(planClockProvider)();
    final user = ref.watch(userContextProvider);
    final goal = view.goalMl;
    final sessions = goal == null || view.mode == WaterGoalMode.clinician
        ? const <WaterSession>[]
        : waterSessions(
            goalMl: goal,
            totalMl: view.totalMl,
            wakeMinutes: user?.wakeMinutes,
            sleepMinutes: user?.sleepMinutes,
          );
    return Scaffold(
      key: const Key('water-screen'),
      backgroundColor: colors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            children: staggered(<Widget>[
              Text(
                l10n.tabWater,
                style: TextStyle(
                  fontSize: 24,
                  height: 1.25,
                  color: colors.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatDayHeading(context, today),
                style: TextStyle(fontSize: 13, color: colors.fg3),
              ),
              const SizedBox(height: 14),
              if (view.mode == WaterGoalMode.clinician)
                _ClinicianCard(totalMl: view.totalMl)
              else
                _BottleCard(view: view),
              if (view.provisional)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.provisionalNote,
                    key: const Key('water-provisional'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: colors.fg2),
                  ),
                ),
              if (sessions.isNotEmpty) ...<Widget>[
                const SizedBox(height: 14),
                SectionHeader(
                  title: l10n.waterSessions,
                  action: Text(
                    l10n.waterSessionsCount(
                      formatWhole(
                        context,
                        sessions.where((WaterSession s) => s.done).length,
                      ),
                      formatWhole(context, sessions.length),
                    ),
                    style: TextStyle(fontSize: 13, color: colors.fg3),
                  ),
                ),
                const SizedBox(height: 8),
                _SessionStrip(sessions: sessions),
              ],
              const SizedBox(height: 14),
              const _QuickButtons(),
              const SizedBox(height: 14),
              _Tip(text: l10n.waterSessionTip),
              const SizedBox(height: 14),
              AppCard(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        l10n.waterTodayList,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (view.entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          l10n.waterEmpty,
                          style: TextStyle(color: colors.fg3),
                        ),
                      ),
                    for (final entry in view.entries) ...<Widget>[
                      Divider(height: 1, color: colors.line),
                      _EntryRow(entry: entry),
                    ],
                  ],
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BottleCard extends ConsumerWidget {
  const _BottleCard({required this.view});

  final WaterView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final goal = view.goalMl;
    final total = formatWhole(context, view.totalMl);
    final label = switch (view.mode) {
      WaterGoalMode.goal when view.requiresClinician => l10n.waterDoctorGoal,
      WaterGoalMode.goal => l10n.waterTodayGoal,
      _ => l10n.waterTotalOnly,
    };
    final number = goal == null
        ? l10n.waterAmountMl(total)
        // Generated placeholders are in alphabetical order: goal, total.
        : l10n.waterTotalOfGoal(formatWhole(context, goal), total);
    final fill = goal == null ? 0.0 : view.progress;
    final light = fill > 0.45;
    return AppCard(
      key: const Key('water-bottle-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            label: '$label: $number',
            excludeSemantics: true,
            child: Center(
              child: SizedBox(
                width: 150,
                height: 200,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    WaterBottle(progress: fill),
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              total,
                              style: colors.numeric.copyWith(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                color: light ? Colors.white : colors.fg,
                              ),
                            ),
                            Text(
                              l10n.waterMlUnit,
                              style: TextStyle(
                                fontSize: 12,
                                color: light
                                    ? const Color(0xD9FFFFFF)
                                    : colors.fg2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(label, style: TextStyle(color: colors.fg2)),
              ),
              Text(
                number,
                key: const Key('water-total'),
                style: colors.numeric.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.fg,
                ),
              ),
            ],
          ),
          if (goal != null) ...<Widget>[
            const SizedBox(height: 8),
            TintBar(value: view.progress, color: colors.water, height: 9),
            const SizedBox(height: 6),
            Text(
              view.totalMl >= goal
                  ? l10n.waterGoalReached
                  : l10n.waterRemaining(
                      formatWhole(context, goal - view.totalMl),
                    ),
              key: const Key('water-remaining'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: colors.fg3),
            ),
          ],
          if (view.mode == WaterGoalMode.none)
            TextButton(
              key: const Key('water-set-goal'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => unawaited(showWaterGoalSheet(context)),
              child: Text(l10n.waterSetGoal),
            ),
        ],
      ),
    );
  }
}

/// `.sess`: the horizontal strip of drinking sessions.
class _SessionStrip extends StatelessWidget {
  const _SessionStrip({required this.sessions});

  final List<WaterSession> sessions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return SingleChildScrollView(
      key: const Key('water-sessions'),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          for (var index = 0; index < sessions.length; index++)
            Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == sessions.length - 1 ? 0 : 10,
              ),
              child: _sessionTile(context, l10n, colors, sessions, index),
            ),
        ],
      ),
    );
  }

  Widget _sessionTile(
    BuildContext context,
    AppLocalizations l10n,
    AppColors colors,
    List<WaterSession> sessions,
    int index,
  ) {
    final session = sessions[index];
    final done = session.done;
    final hours = (session.minutes ~/ 60).toString().padLeft(2, '0');
    final minutes = (session.minutes % 60).toString().padLeft(2, '0');
    return Container(
      key: Key('water-session-$index'),
      width: 66,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: done
            ? mixColor(colors.water, 0.14, colors.surface)
            : colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: done ? mixColor(colors.water, 0.4, colors.line) : colors.line,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: <Widget>[
          Text(
            formatHm(context, '$hours:$minutes'),
            style: colors.numeric.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.fg3,
            ),
          ),
          Emoji(done ? 'droplet' : 'potable-water', size: 26),
          Text(
            formatWhole(context, session.amountMl),
            style: colors.numeric.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.fg,
            ),
          ),
          Text(
            done ? l10n.waterSessionDone : l10n.waterSessionLater,
            style: TextStyle(fontSize: 10.5, color: colors.fg3),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.signalSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.signal.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Emoji('light-bulb', size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              key: const Key('water-session-tip'),
              style: TextStyle(fontSize: 13.5, color: colors.fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Doctor-set amount with none stored: no number, no ring (#270).
class _ClinicianCard extends StatelessWidget {
  const _ClinicianCard({required this.totalMl});

  final int totalMl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      key: const Key('water-clinician-card'),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Center(child: Emoji('stethoscope', size: 40)),
          const SizedBox(height: 8),
          Text(
            l10n.waterClinicianTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${l10n.waterTotalOnly}: ${l10n.waterAmountMl(formatWhole(context, totalMl))}',
            key: const Key('water-total'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('water-doctor-goal'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () => unawaited(showWaterGoalSheet(context)),
            child: Text(l10n.waterClinicianAction),
          ),
        ],
      ),
    );
  }
}

class _QuickButtons extends ConsumerWidget {
  const _QuickButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final labels = <int, (String, String)>{
      150: (l10n.waterQuickSmall, 'teacup-without-handle'),
      250: (l10n.waterQuickCup, 'tumbler-glass'),
      500: (l10n.waterQuickBottle, 'potable-water'),
    };
    Widget tile({
      required Key key,
      required String emoji,
      required String top,
      required String bottom,
      required VoidCallback onTap,
      Color? topColor,
    }) {
      return Expanded(
        child: AppCard(
          key: key,
          radius: 20,
          flat: true,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          onTap: onTap,
          child: Column(
            children: <Widget>[
              Emoji(emoji, size: 30),
              const SizedBox(height: 4),
              Text(
                top,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: colors.numeric.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: topColor ?? colors.fg,
                ),
              ),
              Text(
                bottom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.fg3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        for (final amount in waterQuickAmounts) ...<Widget>[
          tile(
            key: Key('water-add-$amount'),
            emoji: labels[amount]!.$2,
            top: formatWhole(context, amount),
            bottom: labels[amount]!.$1,
            onTap: () => unawaited(addWater(context, ref, amount)),
          ),
          const SizedBox(width: 8),
        ],
        tile(
          key: const Key('water-custom'),
          emoji: 'straight-ruler',
          top: l10n.waterCustom,
          bottom: l10n.waterAnyAmount,
          topColor: colors.water,
          onTap: () => unawaited(showWaterCustomSheet(context)),
        ),
      ],
    );
  }
}

Future<void> addWater(BuildContext context, WidgetRef ref, int amount) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    await ref.read(waterRepositoryProvider).add(amount);
    messenger?.showSnackBar(SnackBar(content: Text(l10n.waterSaved)));
  } on WaterException {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.waterRangeError)));
  }
}

class _EntryRow extends ConsumerWidget {
  const _EntryRow({required this.entry});

  final WaterEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final local = entry.consumedAt.toLocal();
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return ListTile(
      key: Key('water-entry-${entry.clientUuid}'),
      contentPadding: EdgeInsets.zero,
      minTileHeight: 48,
      leading: const Emoji('droplet', size: 22),
      title: Text(
        l10n.waterAmountMl(formatWhole(context, entry.amountMl)),
        style: colors.numeric.copyWith(
          fontWeight: FontWeight.w700,
          color: colors.fg,
        ),
      ),
      subtitle: Text(
        <String>[
          formatHm(context, time),
          if (entry.pending) l10n.extraPending,
          if (entry.rejected) l10n.syncRejected,
        ].join(' · '),
      ),
      trailing: TextButton(
        key: Key('water-delete-${entry.clientUuid}'),
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        onPressed: () {
          unawaited(ref.read(waterRepositoryProvider).remove(entry.clientUuid));
        },
        child: Text(l10n.syncDelete),
      ),
    );
  }
}

/// «مخصص»: 50-1000 ml in steps of 50, with chips.
Future<void> showWaterCustomSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => const _CustomSheet(),
  );
}

class _CustomSheet extends ConsumerStatefulWidget {
  const _CustomSheet();

  @override
  ConsumerState<_CustomSheet> createState() => _CustomSheetState();
}

class _CustomSheetState extends ConsumerState<_CustomSheet> {
  var _amount = 300;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return SafeArea(
      child: Padding(
        key: const Key('water-custom-sheet'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.waterCustomTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              l10n.waterAmountMl(formatWhole(context, _amount)),
              key: const Key('water-custom-value'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Slider(
              key: const Key('water-custom-slider'),
              min: waterMinMl.toDouble(),
              max: waterMaxMl.toDouble(),
              divisions: (waterMaxMl - waterMinMl) ~/ waterStepMl,
              value: _amount.toDouble(),
              label: l10n.waterAmountMl(formatWhole(context, _amount)),
              onChanged: (double value) {
                setState(() => _amount = value.round());
              },
            ),
            Wrap(
              spacing: 8,
              alignment: WrapAlignment.center,
              children: <Widget>[
                for (final chip in waterChips)
                  ChoiceChip(
                    key: Key('water-chip-$chip'),
                    label: Text(l10n.waterAmountMl(formatWhole(context, chip))),
                    selected: _amount == chip,
                    onSelected: (_) => setState(() => _amount = chip),
                  ),
              ],
            ),
            if (_amount > waterLargeMl)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.waterLargeTip,
                  key: const Key('water-large-tip'),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.fg2),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('water-custom-add'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await addWater(context, ref, _amount);
                navigator.pop();
              },
              child: Text(l10n.waterAdd),
            ),
          ],
        ),
      ),
    );
  }
}

/// The amount the doctor set: 500-5000 ml, saved with `PUT /me/profile`.
Future<void> showWaterGoalSheet(BuildContext context) {
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => const _GoalSheet(),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  const _GoalSheet();

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  var _goal = 1500;
  var _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        key: const Key('water-goal-sheet'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.waterGoalSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  key: const Key('water-goal-minus'),
                  onPressed: _goal <= waterGoalMinMl
                      ? null
                      : () => setState(() => _goal -= waterGoalStepMl),
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  l10n.waterAmountMl(formatWhole(context, _goal)),
                  key: const Key('water-goal-value'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  key: const Key('water-goal-plus'),
                  onPressed: _goal >= waterGoalMaxMl
                      ? null
                      : () => setState(() => _goal += waterGoalStepMl),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            Slider(
              min: waterGoalMinMl.toDouble(),
              max: waterGoalMaxMl.toDouble(),
              divisions: (waterGoalMaxMl - waterGoalMinMl) ~/ waterGoalStepMl,
              value: _goal.toDouble(),
              onChanged: (double value) {
                setState(() => _goal = value.round());
              },
            ),
            if (_error != null)
              Text(
                _error!,
                key: const Key('water-goal-error'),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('water-goal-save'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: _busy ? null : () => unawaited(_save()),
              child: Text(l10n.waterGoalSave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref.read(waterRepositoryProvider).setGoal(_goal);
      navigator.pop();
      messenger?.showSnackBar(SnackBar(content: Text(l10n.waterGoalSaved)));
    } on WaterException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error.network
            ? l10n.waterNeedsConnection
            : l10n.failureGeneric;
      });
    }
  }
}

/// A bottle filled to [progress]: the prototype outline and two waves.
/// The waves move only when motion is on.
class WaterBottle extends StatefulWidget {
  const WaterBottle({required this.progress, super.key});

  final double progress;

  @override
  State<WaterBottle> createState() => _WaterBottleState();
}

class _WaterBottleState extends State<WaterBottle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsEnabled(context)) {
      if (!_wave.isAnimating) {
        unawaited(_wave.repeat());
      }
    } else {
      _wave.stop();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final moving = animationsEnabled(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: widget.progress.clamp(0, 1).toDouble(),
      ),
      duration: moving ? const Duration(seconds: 1) : Duration.zero,
      curve: const Cubic(0.3, 0.7, 0.2, 1),
      builder: (BuildContext context, double level, Widget? _) {
        return AnimatedBuilder(
          animation: _wave,
          builder: (BuildContext context, Widget? child) {
            return CustomPaint(
              key: Key(moving ? 'water-wave-on' : 'water-wave-off'),
              painter: BottlePainter(
                progress: level,
                phase: moving ? _wave.value : 0,
                wave: moving,
                water: colors.water,
                glass: mixColor(colors.water, 0.45, colors.line),
                inside: mixColor(colors.water, 0.08, colors.surface),
              ),
            );
          },
        );
      },
    );
  }
}

class BottlePainter extends CustomPainter {
  BottlePainter({
    required this.progress,
    required this.phase,
    required this.wave,
    required this.water,
    required this.glass,
    required this.inside,
  });

  final double progress;
  final double phase;
  final bool wave;
  final Color water;
  final Color glass;
  final Color inside;

  /// The prototype bottle in its 150 x 200 box.
  static Path _outline() {
    return Path()
      ..moveTo(48, 10)
      ..lineTo(102, 10)
      ..lineTo(102, 28)
      ..cubicTo(102, 34, 120, 42, 120, 62)
      ..lineTo(120, 180)
      ..arcToPoint(const Offset(106, 194), radius: const Radius.circular(14))
      ..lineTo(44, 194)
      ..arcToPoint(const Offset(30, 180), radius: const Radius.circular(14))
      ..lineTo(30, 62)
      ..cubicTo(30, 42, 48, 34, 48, 28)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 150, size.height / 200);
    final outline = _outline();
    canvas.drawPath(outline, Paint()..color = inside);
    canvas.save();
    canvas.clipPath(outline);
    final level = 190 - 170 * progress.clamp(0, 1);
    void waveAt(double base, double shift, double alpha) {
      final amplitude = wave ? 4.0 : 0.0;
      final fill = Path()..moveTo(0, level + base);
      for (var x = 0.0; x <= 150; x += 3) {
        final y =
            level + base + amplitude * math.sin((x / 75 + shift) * 2 * math.pi);
        fill.lineTo(x, y);
      }
      fill
        ..lineTo(150, 220)
        ..lineTo(0, 220)
        ..close();
      canvas.drawPath(fill, Paint()..color = water.withValues(alpha: alpha));
    }

    if (progress > 0) {
      waveAt(4, -phase, 0.45);
      waveAt(0, phase, 0.9);
    }
    canvas.restore();
    canvas.drawPath(
      outline,
      Paint()
        ..color = glass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(52, 2, 46, 12),
        const Radius.circular(4),
      ),
      Paint()..color = glass,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(BottlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.wave != wave ||
        oldDelegate.water != water;
  }
}
