import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class MacroRing extends StatelessWidget {
  const MacroRing({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.kcalLabel,
    required this.proteinLabel,
    required this.carbLabel,
    required this.fatLabel,
    required this.gramsLabel,
    super.key,
  });

  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;
  final String kcalLabel;
  final String proteinLabel;
  final String carbLabel;
  final String fatLabel;
  final String Function(double grams) gramsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              CustomPaint(
                size: const Size.square(96),
                painter: _RingPainter(
                  protein: proteinG,
                  carb: carbG,
                  fat: fatG,
                  proteinColor: colors.protein,
                  carbColor: colors.carb,
                  fatColor: colors.fat,
                  track: colors.line,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: FittedBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _whole(kcal),
                        style: text.titleMedium?.copyWith(
                          color: colors.kcal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        kcalLabel,
                        style: text.labelSmall?.copyWith(color: colors.fg3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: <Widget>[
              _line(context, colors.protein, proteinLabel, proteinG),
              const SizedBox(height: 8),
              _line(context, colors.carb, carbLabel, carbG),
              const SizedBox(height: 8),
              _line(context, colors.fat, fatLabel, fatG),
            ],
          ),
        ),
      ],
    );
  }

  Widget _line(BuildContext context, Color color, String label, double grams) {
    final colors = context.appColors;
    return Row(
      children: <Widget>[
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.fg),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          gramsLabel(grams),
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: colors.fg, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

String _whole(double value) => value.round().toString();

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.protein,
    required this.carb,
    required this.fat,
    required this.proteinColor,
    required this.carbColor,
    required this.fatColor,
    required this.track,
  });

  final double protein;
  final double carb;
  final double fat;
  final Color proteinColor;
  final Color carbColor;
  final Color fatColor;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    final proteinK = protein * 4;
    final carbK = carb * 4;
    final fatK = fat * 9;
    final total = proteinK + carbK + fatK;
    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);
      return;
    }
    var start = -math.pi / 2;
    void segment(double share, Color color) {
      if (share <= 0) {
        return;
      }
      final sweep = share / total * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, paint..color = color);
      start += sweep;
    }

    segment(proteinK, proteinColor);
    segment(carbK, carbColor);
    segment(fatK, fatColor);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.protein != protein ||
        oldDelegate.carb != carb ||
        oldDelegate.fat != fat ||
        oldDelegate.proteinColor != proteinColor ||
        oldDelegate.carbColor != carbColor ||
        oldDelegate.fatColor != fatColor;
  }
}
