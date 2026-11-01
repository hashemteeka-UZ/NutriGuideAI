import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/motion.dart';

/// Motion of the app (P2d): tab fade-through, RTL-aware shared axis for
/// pushed routes, slide + fade sheets. Every duration is zero when the
/// system asks for reduced motion.

const Duration tabSwitchDuration = Duration(milliseconds: 300);
const Duration pushDuration = Duration(milliseconds: 300);
const Curve emphasized = Curves.easeInOutCubicEmphasized;

/// Hero tag of a plan item's meal icon (Today, Plan -> plan item screen).
Object mealHeroTag(int planItemId) => 'meal-item-$planItemId';

/// Hero tag of a catalog meal's icon (browse, favourites -> meal details).
Object catalogMealHeroTag(int mealId) => 'meal-$mealId';

/// A go_router page that enters along the reading direction: from the end
/// side in LTR (right) and from the left in RTL, like Material shared axis X.
Page<void> sharedAxisPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final duration = animationsEnabled(context) ? pushDuration : Duration.zero;
  return CustomTransitionPage<void>(
    key: state.pageKey,
    name: state.name,
    arguments: state.extra,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          if (!animationsEnabled(context)) {
            return child;
          }
          return SharedAxisX(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
  );
}

/// Shared axis X: the incoming page fades in while it moves 30 px from the
/// reading end; the outgoing page fades out moving 30 px the other way.
class SharedAxisX extends StatelessWidget {
  const SharedAxisX({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  static const double _shift = 30;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sign = rtl ? -1.0 : 1.0;
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[animation, secondaryAnimation]),
      builder: (BuildContext context, Widget? child) {
        final enter = emphasized.transform(animation.value);
        final exit = emphasized.transform(secondaryAnimation.value);
        final fadeIn = const Interval(0.3, 1).transform(animation.value);
        final fadeOut =
            1 - const Interval(0, 0.3).transform(secondaryAnimation.value);
        final dx = sign * (_shift * (1 - enter) - _shift * exit);
        return Opacity(
          opacity: (fadeIn * fadeOut).clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(dx, 0), child: child),
        );
      },
      child: child,
    );
  }
}

/// Branch container for the bottom tabs: every branch stays alive (as in an
/// IndexedStack); switching plays a Material fade-through.
class FadeThroughBranches extends StatefulWidget {
  const FadeThroughBranches({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<FadeThroughBranches> createState() => _FadeThroughBranchesState();
}

class _FadeThroughBranchesState extends State<FadeThroughBranches>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: tabSwitchDuration,
    value: 1,
  );
  late final Animation<double> _curved = CurvedAnimation(
    parent: _controller,
    curve: emphasized,
  );
  int? _previous;

  @override
  void didUpdateWidget(FadeThroughBranches oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex == widget.currentIndex) {
      return;
    }
    if (!animationsEnabled(context)) {
      _previous = null;
      _controller.value = 1;
      return;
    }
    _previous = oldWidget.currentIndex;
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) {
        setState(() => _previous = null);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.currentIndex;
    final previous = _previous;
    final order = <int>[
      for (var i = 0; i < widget.children.length; i++)
        if (i != current && i != previous) i,
      ?previous,
      current,
    ];
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (final i in order)
          _BranchSlot(
            key: ValueKey<int>(i),
            visible: i == current || i == previous,
            interactive: i == current,
            animation: i == current ? _curved : kAlwaysCompleteAnimation,
            secondaryAnimation: i == previous
                ? _curved
                : kAlwaysDismissedAnimation,
            child: widget.children[i],
          ),
      ],
    );
  }
}

/// The same widget tree for a visible and a hidden branch, so a branch keeps
/// its state when it is shown again.
class _BranchSlot extends StatelessWidget {
  const _BranchSlot({
    required this.visible,
    required this.interactive,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
    super.key,
  });

  final bool visible;
  final bool interactive;
  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: HeroMode(
          enabled: interactive,
          child: IgnorePointer(
            ignoring: !interactive,
            child: FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              fillColor: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// `showModalBottomSheet` that also fades its content in and out with the
/// slide (P2d). With reduced motion the route itself has no animation.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool? showDragHandle,
  Color? backgroundColor,
}) {
  final animate = animationsEnabled(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    sheetAnimationStyle: animate
        ? const AnimationStyle(
            duration: Duration(milliseconds: 300),
            reverseDuration: Duration(milliseconds: 220),
          )
        : AnimationStyle.noAnimation,
    builder: (BuildContext sheetContext) =>
        SheetFade(child: builder(sheetContext)),
  );
}

/// Fades a sheet's content with its route animation.
class SheetFade extends StatelessWidget {
  const SheetFade({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || !animationsEnabled(context)) {
      return child;
    }
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
      ),
      child: child,
    );
  }
}
