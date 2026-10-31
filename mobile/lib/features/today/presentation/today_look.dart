import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../plan/domain/meal_timing.dart';
import '../../plan/domain/plan.dart';

/// Look helpers shared by Today, Plan and the account header.

/// The avatar emoji by sex, as home() in the prototype.
String avatarEmoji(String? sex) {
  return switch (sex) {
    'FEMALE' => 'woman',
    'MALE' => 'man',
    _ => 'seedling',
  };
}

/// The meal's own emoji, or a plate while the catalog row is missing.
String mealEmoji(PlanItem item) {
  final name = item.iconName;
  return name == null || name.isEmpty ? 'fork-and-knife-with-plate' : name;
}

/// The tile tint of a meal slot.
Color slotTint(AppColors colors, String slot) {
  return switch (slot) {
    'BREAKFAST' => colors.fat,
    'LUNCH' => colors.kcal,
    'DINNER' => colors.carb,
    'SNACK' => colors.protein,
    _ => colors.brand,
  };
}

/// `.tldot`: done is filled, now pulses in the energy colour, missed is
/// outlined in warn, the rest is an empty ring.
class TimelineDot extends StatefulWidget {
  const TimelineDot({required this.when, super.key});

  final MealWhen when;

  @override
  State<TimelineDot> createState() => _TimelineDotState();
}

class _TimelineDotState extends State<TimelineDot>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TimelineDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final wanted = widget.when == MealWhen.now && animationsEnabled(context);
    if (wanted && _pulse == null) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
    } else if (!wanted && _pulse != null) {
      _pulse!.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (Color fill, Color border) = switch (widget.when) {
      MealWhen.logged => (colors.ok, colors.ok),
      MealWhen.now => (colors.surface, colors.kcal),
      MealWhen.missed => (colors.surface, colors.warn),
      MealWhen.upcoming || MealWhen.untimed => (colors.surface, colors.line),
    };
    final dot = Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 3),
      ),
    );
    final pulse = _pulse;
    if (pulse == null) {
      return dot;
    }
    return AnimatedBuilder(
      animation: pulse,
      builder: (BuildContext context, Widget? child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: colors.kcal.withValues(alpha: 0.55 * (1 - pulse.value)),
                spreadRadius: 14 * pulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: dot,
    );
  }
}
