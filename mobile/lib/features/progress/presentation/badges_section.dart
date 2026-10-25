import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../plan/domain/plan_dates.dart';
import '../data/badge_service.dart';
import '../domain/badges.dart';

/// «الإنجازات»: a 2-column grid of badges computed on the phone (#305-#308).
class BadgesSection extends ConsumerStatefulWidget {
  const BadgesSection({super.key});

  @override
  ConsumerState<BadgesSection> createState() => _BadgesSectionState();
}

class _BadgesSectionState extends ConsumerState<BadgesSection> {
  /// Badges earned since the last visit, celebrated once in this view.
  Set<BadgeCode>? _fresh;
  var _shown = false;

  void _celebrate(List<BadgeItem> items) {
    if (_fresh != null) {
      return;
    }
    _fresh = <BadgeCode>{
      for (final item in items)
        if (item.earned && !item.seen) item.code,
    };
    if (_fresh!.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      setState(() => _shown = true);
      unawaited(
        ref
            .read(badgeServiceProvider)
            .markSeen(_fresh!)
            .catchError((Object _) {}),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final board = ref.watch(badgeBoardProvider);
    final items = board.asData?.value;
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    _celebrate(items);
    final fresh = _fresh ?? const <BadgeCode>{};
    final animate = animationsEnabled(context);
    return Column(
      key: const Key('badges-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final code in fresh)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AnimatedOpacity(
              key: Key('badge-celebrate-${code.code}'),
              opacity: _shown ? 1 : 0,
              duration: animate
                  ? const Duration(milliseconds: 400)
                  : Duration.zero,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.badgeCelebrate(badgeName(l10n, code)),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
          ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: <Widget>[
            for (final item in items)
              AnimatedScale(
                scale: fresh.contains(item.code) && !_shown ? 0.8 : 1,
                duration: animate
                    ? const Duration(milliseconds: 400)
                    : Duration.zero,
                curve: Curves.easeOutBack,
                child: _BadgeTile(item: item),
              ),
          ],
        ),
      ],
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.item});

  final BadgeItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final earned = item.earned;
    final progress = item.progress;
    final accent = earned ? _accent(colors, item.code) : colors.fg3;
    final String status;
    if (earned) {
      status = l10n.badgeEarnedOn(_date(context, item.earnedOn!));
    } else if (progress.needsWaterGoal) {
      status = l10n.badgeWaterHint;
    } else {
      status = l10n.badgeProgress(progress.current, progress.target);
    }
    return Semantics(
      key: Key('badge-${item.code.code}'),
      container: true,
      label: '${badgeName(l10n, item.code)}, $status',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: earned ? 0.16 : 0.10),
              ),
              child: Icon(_icon(item.code), color: accent),
            ),
            const SizedBox(height: 8),
            Text(
              badgeName(l10n, item.code),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: earned ? colors.fg : colors.fg2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                badgeDescription(l10n, item.code),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.fg2),
              ),
            ),
            if (!earned && !progress.needsWaterGoal) ...<Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: Key('badge-progress-${item.code.code}'),
                  value: progress.target == 0
                      ? 0
                      : progress.current / progress.target,
                  minHeight: 6,
                  backgroundColor: colors.surface3,
                  color: colors.brand,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              status,
              key: Key('badge-status-${item.code.code}'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colors.fg2),
            ),
          ],
        ),
      ),
    );
  }
}

String _date(BuildContext context, String iso) {
  return (DateFormat(
    'd MMMM yyyy',
    Localizations.localeOf(context).toString(),
  )..useNativeDigits = false).format(dateFromIso(iso));
}

String badgeName(AppLocalizations l10n, BadgeCode code) {
  return switch (code) {
    BadgeCode.firstLog => l10n.badgeFirstLog,
    BadgeCode.firstAchievedDay => l10n.badgeFirstAchievedDay,
    BadgeCode.streak3 => l10n.badgeStreak3,
    BadgeCode.streak7 => l10n.badgeStreak7,
    BadgeCode.streak14 => l10n.badgeStreak14,
    BadgeCode.streak30 => l10n.badgeStreak30,
    BadgeCode.balancedWeek => l10n.badgeBalancedWeek,
    BadgeCode.waterGoal3 => l10n.badgeWaterGoal3,
    BadgeCode.weightTracker => l10n.badgeWeightTracker,
    BadgeCode.explorer10 => l10n.badgeExplorer10,
  };
}

String badgeDescription(AppLocalizations l10n, BadgeCode code) {
  return switch (code) {
    BadgeCode.firstLog => l10n.badgeFirstLogDesc,
    BadgeCode.firstAchievedDay => l10n.badgeFirstAchievedDayDesc,
    BadgeCode.streak3 => l10n.badgeStreak3Desc,
    BadgeCode.streak7 => l10n.badgeStreak7Desc,
    BadgeCode.streak14 => l10n.badgeStreak14Desc,
    BadgeCode.streak30 => l10n.badgeStreak30Desc,
    BadgeCode.balancedWeek => l10n.badgeBalancedWeekDesc,
    BadgeCode.waterGoal3 => l10n.badgeWaterGoal3Desc,
    BadgeCode.weightTracker => l10n.badgeWeightTrackerDesc,
    BadgeCode.explorer10 => l10n.badgeExplorer10Desc,
  };
}

IconData _icon(BadgeCode code) {
  return switch (code) {
    BadgeCode.firstLog => Icons.flag_outlined,
    BadgeCode.firstAchievedDay => Icons.check_circle_outline,
    BadgeCode.streak3 => Icons.local_fire_department_outlined,
    BadgeCode.streak7 => Icons.whatshot_outlined,
    BadgeCode.streak14 => Icons.emoji_events_outlined,
    BadgeCode.streak30 => Icons.military_tech_outlined,
    BadgeCode.balancedWeek => Icons.balance,
    BadgeCode.waterGoal3 => Icons.water_drop_outlined,
    BadgeCode.weightTracker => Icons.monitor_weight_outlined,
    BadgeCode.explorer10 => Icons.explore_outlined,
  };
}

Color _accent(AppColors colors, BadgeCode code) {
  return switch (code) {
    BadgeCode.waterGoal3 => colors.fiber,
    BadgeCode.weightTracker => colors.fat,
    BadgeCode.explorer10 => colors.carb,
    BadgeCode.streak3 ||
    BadgeCode.streak7 ||
    BadgeCode.streak14 ||
    BadgeCode.streak30 => colors.kcal,
    _ => colors.brand,
  };
}
