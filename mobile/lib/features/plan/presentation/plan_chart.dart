import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ChartDay {
  const ChartDay({required this.label, required this.selected, this.kcal});

  final String label;
  final int? kcal;
  final bool selected;
}

class PlanChart extends StatelessWidget {
  const PlanChart({
    required this.days,
    required this.targetKcal,
    required this.summary,
    super.key,
  });

  final List<ChartDay> days;
  final int? targetKcal;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      key: const Key('plan-chart'),
      container: true,
      label: summary,
      child: SizedBox(
        height: 160,
        child: CustomPaint(
          painter: _ChartPainter(
            days: days,
            targetKcal: targetKcal,
            direction: Directionality.of(context),
            bar: colors.brand,
            selected: colors.brand2,
            band: colors.brand.withValues(alpha: 0.16),
            line: colors.line,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.days,
    required this.targetKcal,
    required this.direction,
    required this.bar,
    required this.selected,
    required this.band,
    required this.line,
  });

  final List<ChartDay> days;
  final int? targetKcal;
  final TextDirection direction;
  final Color bar;
  final Color selected;
  final Color band;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    final count = days.length;
    if (count == 0) {
      return;
    }
    final maxBar = days.fold<double>(
      0,
      (double maxValue, ChartDay day) =>
          math.max(maxValue, (day.kcal ?? 0).toDouble()),
    );
    final ceiling = math.max(maxBar, (targetKcal ?? 0) * 1.1);
    final scale = ceiling <= 0 ? 1.0 : ceiling;
    final slot = size.width / count;
    final rtl = direction == TextDirection.rtl;

    if (targetKcal != null && targetKcal! > 0) {
      final low = size.height * (1 - (targetKcal! * 0.9) / scale);
      final high = size.height * (1 - (targetKcal! * 1.1) / scale);
      canvas.drawRect(
        Rect.fromLTRB(0, high, size.width, low),
        Paint()..color = band,
      );
    }
    canvas.drawLine(
      Offset(0, size.height - 1),
      Offset(size.width, size.height - 1),
      Paint()..color = line,
    );

    for (var index = 0; index < count; index++) {
      final day = days[index];
      final kcal = day.kcal;
      if (kcal == null) {
        continue;
      }
      final visual = rtl ? count - 1 - index : index;
      final height = size.height * (kcal / scale);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          visual * slot + slot * 0.22,
          size.height - height,
          slot * 0.56,
          height,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, Paint()..color = day.selected ? selected : bar);
    }
  }

  @override
  bool shouldRepaint(_ChartPainter oldDelegate) => true;
}
