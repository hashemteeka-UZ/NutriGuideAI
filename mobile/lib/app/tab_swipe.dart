import 'package:flutter/material.dart';

/// Switches the main tabs with a horizontal swipe.
///
/// The swipe follows the tab bar's order on screen: in Arabic the next tab is
/// on the left, so moving the finger to the right opens it; in English it is
/// the other way round. Vertical scrolling is untouched, and anything inside
/// a tab that scrolls or drags sideways (day strips, charts, sliders) keeps
/// its gesture, because the inner recognizer wins the gesture arena.
class TabSwipe extends StatefulWidget {
  const TabSwipe({
    required this.index,
    required this.count,
    required this.onSwipe,
    required this.child,
    super.key,
  });

  final int index;
  final int count;
  final ValueChanged<int> onSwipe;
  final Widget child;

  /// A fling at least this fast switches, whatever its length.
  static const double minVelocity = 450;

  /// Otherwise the finger must travel this share of the width.
  static const double minShare = 0.22;

  @override
  State<TabSwipe> createState() => _TabSwipeState();
}

class _TabSwipeState extends State<TabSwipe> {
  double _dx = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dx = 0,
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        _dx += details.primaryDelta ?? 0;
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        final width = context.size?.width ?? 1;
        final velocity = details.primaryVelocity ?? 0;
        final double push;
        if (velocity.abs() >= TabSwipe.minVelocity) {
          push = velocity;
        } else if (_dx.abs() >= width * TabSwipe.minShare) {
          push = _dx;
        } else {
          return;
        }
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final forward = rtl ? push > 0 : push < 0;
        final next = widget.index + (forward ? 1 : -1);
        if (next >= 0 && next < widget.count) {
          widget.onSwipe(next);
        }
      },
      child: widget.child,
    );
  }
}
