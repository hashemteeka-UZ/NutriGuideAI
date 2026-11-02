import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/motion.dart';
import 'emoji.dart';

/// Shared look of the approved prototype (prototype_v3, 1_head.html):
/// soft cards, tinted cards per data type, gradient hero, emoji tiles,
/// rings with a percent and thin bars. Look only: no behaviour lives here.

/// `color-mix(in srgb, tint share%, base)`.
Color mixColor(Color tint, double share, Color base) {
  return Color.lerp(base, tint, share)!;
}

const double cardRadius = 24;

List<BoxShadow> softShadow(AppColors colors) {
  return <BoxShadow>[
    BoxShadow(
      color: colors.shadow.withValues(alpha: colors.shadow.a * 0.6),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(color: colors.shadow, blurRadius: 24, offset: const Offset(0, 8)),
  ];
}

/// `.card` and `.card.tint`: white card, or a card tinted by one data colour.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.tint,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = cardRadius,
    this.borderColor,
    this.background,
    this.flat = false,
    super.key,
  });

  final Widget child;
  final Color? tint;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? borderColor;
  final Color? background;
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = this.tint;
    final fill =
        background ??
        (tint == null ? colors.surface : mixColor(tint, 0.10, colors.surface));
    final border =
        borderColor ??
        (tint == null ? colors.line : mixColor(tint, 0.22, colors.line));
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: border),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: flat ? null : softShadow(colors),
      ),
      child: Material(
        color: fill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(
                onTap: onTap,
                child: Padding(padding: padding, child: child),
              ),
      ),
    );
  }
}

/// `.card.hero`: the brand gradient with two soft circles, white text.
class GradientHero extends StatelessWidget {
  const GradientHero({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final body = Stack(
      children: <Widget>[
        PositionedDirectional(
          start: -80,
          top: -120,
          child: IgnorePointer(
            child: Container(
              width: 240,
              height: 240,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0x38FFFFFF), Color(0x00FFFFFF)],
                  stops: <double>[0, 0.65],
                ),
              ),
            ),
          ),
        ),
        PositionedDirectional(
          end: -60,
          bottom: -110,
          child: IgnorePointer(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x14FFFFFF), width: 30),
              ),
            ),
          ),
        ),
        Padding(
          padding: padding,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: IconTheme.merge(
              data: const IconThemeData(color: Colors.white),
              child: child,
            ),
          ),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: softShadow(colors),
      ),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(cardRadius),
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(gradient: gradient ?? colors.heroGradient),
          child: onTap == null ? body : InkWell(onTap: onTap, child: body),
        ),
      ),
    );
  }
}

/// `.thumb` / `.emobox`: an emoji on a rounded tile tinted by [tint].
class EmojiTile extends StatelessWidget {
  const EmojiTile(
    this.name, {
    this.size = 46,
    this.emojiSize,
    this.tint,
    this.background,
    this.radius,
    super.key,
  });

  final String name;
  final double size;
  final double? emojiSize;
  final Color? tint;
  final Color? background;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fill =
        background ?? mixColor(tint ?? colors.brand, 0.16, colors.surface2);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius ?? size * 0.33),
      ),
      child: Emoji(name, size: emojiSize ?? size * 0.66),
    );
  }
}

/// `.bar`: a thin rounded bar on a track of the same colour at 16%.
class TintBar extends StatelessWidget {
  const TintBar({
    required this.value,
    required this.color,
    this.height = 8,
    this.track,
    super.key,
  });

  final double value;
  final Color color;
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) {
    final share = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: track ?? color.withValues(alpha: 0.16),
        alignment: AlignmentDirectional.centerStart,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: share),
          duration: animationsEnabled(context)
              ? const Duration(milliseconds: 900)
              : Duration.zero,
          curve: const Cubic(0.3, 0.7, 0.2, 1),
          builder: (BuildContext context, double v, Widget? _) {
            return FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// `ring()`: a progress ring on a tinted track with content in the middle.
/// It fills clockwise in LTR and counter-clockwise in RTL, as the prototype.
class RingPercent extends StatelessWidget {
  const RingPercent({
    required this.value,
    required this.color,
    this.size = 108,
    this.stroke = 12,
    this.track,
    this.center,
    super.key,
  });

  final double value;
  final Color color;
  final double size;
  final double stroke;
  final Color? track;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final share = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: share),
        duration: animationsEnabled(context)
            ? const Duration(milliseconds: 1100)
            : Duration.zero,
        curve: const Cubic(0.3, 0.7, 0.2, 1),
        builder: (BuildContext context, double v, Widget? child) {
          return CustomPaint(
            painter: _RingPainter(
              value: v,
              color: color,
              track: track ?? color.withValues(alpha: 0.16),
              stroke: stroke,
              reverse: rtl,
            ),
            child: child,
          );
        },
        child: center == null ? null : Center(child: center),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.color,
    required this.track,
    required this.stroke,
    required this.reverse,
  });

  final double value;
  final Color color;
  final Color track;
  final double stroke;
  final bool reverse;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - stroke / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint..color = track);
    if (value <= 0) {
      return;
    }
    final sweep = math.pi * 2 * value * (reverse ? -1 : 1);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.track != track ||
        oldDelegate.reverse != reverse;
  }
}

/// Percent label for the middle of a ring.
String percentLabel(double share) {
  final value = share.isNaN ? 0 : (share.clamp(0.0, 1.0) * 100).round();
  return '$value%';
}

/// `.badge`: a small pill in one state colour.
class StateBadge extends StatelessWidget {
  const StateBadge({
    required this.label,
    required this.color,
    this.icon,
    super.key,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.card.tint` with an emoji, a label and one figure: the insight tiles.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.tint,
    this.caption,
    this.onTap,
    super.key,
  });

  final String emoji;
  final String label;
  final String value;
  final String? caption;
  final Color tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return AppCard(
      tint: tint,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          EmojiTile(emoji, size: 46, tint: tint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.fg3),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.fg,
                  ),
                ),
                if (caption != null)
                  Text(
                    caption!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.fg2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One macro on Today: emoji, label, a bar and «eaten / target غ».
class MacroCard extends StatelessWidget {
  const MacroCard({
    required this.emoji,
    required this.label,
    required this.shown,
    required this.share,
    required this.targetText,
    required this.shownText,
    required this.color,
    super.key,
  });

  final String emoji;
  final String label;

  /// The bold figure (eaten or left).
  final String shownText;
  final double shown;

  /// Bar fill, 0 to 1.
  final double share;

  /// « / 120غ».
  final String targetText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      tint: color,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Emoji(emoji, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colors.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TintBar(value: share, color: color, height: 6),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: shownText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(text: targetText),
                ],
              ),
              style: colors.numeric.copyWith(fontSize: 13, color: colors.fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// `.seg`: two or three equal options on a soft track.
class SegToggle<T> extends StatelessWidget {
  const SegToggle({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final (option, label) in options)
            Semantics(
              button: true,
              selected: option == value,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: animationsEnabled(context)
                      ? const Duration(milliseconds: 200)
                      : Duration.zero,
                  constraints: const BoxConstraints(
                    minHeight: 36,
                    minWidth: 72,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: option == value ? colors.surface : null,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: option == value ? softShadow(colors) : null,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: option == value ? colors.fg : colors.fg2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// `.sec`: a section title with an optional trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.action, super.key});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 2, end: 2, top: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// A dashed or solid rounded border, for day chips and the eat button.
class DashedBorderPainter extends CustomPainter {
  DashedBorderPainter({
    required this.color,
    required this.dashed,
    this.radius = 16,
    this.width = 1.5,
  });

  final Color color;
  final bool dashed;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius),
    );
    if (!dashed) {
      canvas.drawRRect(rect, paint);
      return;
    }
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + 4, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += 8;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashed != dashed ||
        oldDelegate.radius != radius;
  }
}
