import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../plan/data/plan_providers.dart';
import '../../plan/presentation/plan_format.dart';
import '../data/water_providers.dart';
import '../domain/water.dart';

/// The Water tab (Decisions #269, #270).
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
    return Scaffold(
      key: const Key('water-screen'),
      backgroundColor: colors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              Text(
                formatDayHeading(context, today),
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: colors.fg2),
              ),
              Text(
                l10n.tabWater,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: colors.fg, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              const _QuickButtons(),
              const SizedBox(height: 16),
              Text(
                l10n.waterTodayList,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (view.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l10n.waterEmpty),
                ),
              for (final entry in view.entries) _EntryRow(entry: entry),
            ],
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
    return Container(
      key: const Key('water-bottle-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: <Widget>[
          Semantics(
            label: '$label: $number',
            child: SizedBox(
              width: 120,
              height: 180,
              child: WaterBottle(progress: view.progress),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            number,
            key: const Key('water-total'),
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: colors.fg),
          ),
          Text(label, style: TextStyle(color: colors.fg2)),
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

/// Doctor-set amount with none stored: no number, no ring (#270).
class _ClinicianCard extends StatelessWidget {
  const _ClinicianCard({required this.totalMl});

  final int totalMl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Container(
      key: const Key('water-clinician-card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(Icons.medical_services_outlined, color: colors.brand, size: 32),
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
          const SizedBox(height: 8),
          FilledButton(
            key: const Key('water-doctor-goal'),
            style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
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
    final labels = <int, String>{
      150: l10n.waterQuickSmall,
      250: l10n.waterQuickCup,
      500: l10n.waterQuickBottle,
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (final amount in waterQuickAmounts)
          OutlinedButton(
            key: Key('water-add-$amount'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(96, 56)),
            onPressed: () => unawaited(addWater(context, ref, amount)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(labels[amount]!),
                Text(l10n.waterAmountMl(formatWhole(context, amount))),
              ],
            ),
          ),
        OutlinedButton(
          key: const Key('water-custom'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(96, 56)),
          onPressed: () => unawaited(showWaterCustomSheet(context)),
          child: Text(l10n.waterCustom),
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
      leading: Icon(Icons.water_drop_outlined, color: colors.brand),
      title: Text(l10n.waterAmountMl(formatWhole(context, entry.amountMl))),
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
  return showModalBottomSheet<void>(
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
  return showModalBottomSheet<void>(
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

/// A bottle filled to [progress]. The wave moves only when motion is on.
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
    duration: const Duration(seconds: 3),
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
    return AnimatedBuilder(
      animation: _wave,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          key: Key(moving ? 'water-wave-on' : 'water-wave-off'),
          painter: BottlePainter(
            progress: widget.progress,
            phase: moving ? _wave.value : 0,
            wave: moving,
            water: colors.brand,
            glass: colors.line,
          ),
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
  });

  final double progress;
  final double phase;
  final bool wave;
  final Color water;
  final Color glass;

  @override
  void paint(Canvas canvas, Size size) {
    final neck = size.width * 0.3;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height * 0.18, size.width, size.height * 0.82),
      const Radius.circular(24),
    );
    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH((size.width - neck) / 2, 0, neck, size.height * 0.2),
      const Radius.circular(6),
    );
    final outline = Path()
      ..addRRect(body)
      ..addRRect(cap);
    canvas.save();
    canvas.clipPath(Path()..addRRect(body));
    final level = body.bottom - body.height * progress.clamp(0, 1);
    final fill = Path()..moveTo(0, level);
    const waves = 2;
    final amplitude = wave && progress > 0 ? 6.0 : 0.0;
    for (var x = 0.0; x <= size.width; x += 4) {
      final y =
          level +
          amplitude * math.sin((x / size.width * waves + phase) * 2 * math.pi);
      fill.lineTo(x, y);
    }
    fill
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = water.withValues(alpha: 0.8));
    canvas.restore();
    canvas.drawPath(
      outline,
      Paint()
        ..color = glass
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(BottlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.wave != wave;
  }
}
