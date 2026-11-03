import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/motion.dart';

/// Motion pieces of the plan showcase, after the prototype's `.gen` screen.
/// Every one of them stands still when the system asks for less motion.

/// `.stp.on .n`: a soft pulse around the step being worked on.
class Pulse extends StatefulWidget {
  const Pulse({required this.child, required this.color, super.key});

  final Widget child;
  final Color color;

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsEnabled(context)) {
      if (!_controller.isAnimating) {
        unawaited(_controller.repeat());
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final t = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.color.withValues(alpha: 0.45 * (1 - t)),
                spreadRadius: 8 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// `animation: pop`: grows in with a small overshoot when [child] first shows.
class PopIn extends StatelessWidget {
  const PopIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!animationsEnabled(context)) {
      return child;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (BuildContext context, double scale, Widget? child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }
}

/// `animation: rise`: fades and slides [child] up after [delay].
class Stagger extends StatefulWidget {
  const Stagger({required this.child, this.delay = Duration.zero, super.key});

  final Widget child;
  final Duration delay;

  @override
  State<Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<Stagger> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!animationsEnabled(context)) {
      _controller.value = 1;
      return;
    }
    if (_controller.value == 0 && _timer == null) {
      _timer = Timer(widget.delay, () {
        if (mounted) {
          unawaited(_controller.forward());
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(curve),
        child: widget.child,
      ),
    );
  }
}

/// `.dayc.run .o`: a spinning ring around the day being built.
class SpinRing extends StatefulWidget {
  const SpinRing({
    required this.color,
    required this.size,
    this.child,
    super.key,
  });

  final Color color;
  final double size;
  final Widget? child;

  @override
  State<SpinRing> createState() => _SpinRingState();
}

class _SpinRingState extends State<SpinRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsEnabled(context)) {
      if (!_controller.isAnimating) {
        unawaited(_controller.repeat());
      }
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          RotationTransition(
            turns: _controller,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _ArcPainter(widget.color),
            ),
          ),
          ?widget.child,
        ],
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rect = Offset.zero & size;
    canvas.drawArc(rect.deflate(1), 0, math.pi * 1.5, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}

/// The slot machine of `.slot .reel`: cycles through dish emoji while the
/// solver works, then [settled] pops in once the server chose the meal.
class Reel extends StatefulWidget {
  const Reel({
    required this.pool,
    required this.settled,
    required this.build,
    super.key,
  });

  final List<String> pool;
  final String? settled;
  final Widget Function(String emoji) build;

  @override
  State<Reel> createState() => _ReelState();
}

class _ReelState extends State<Reel> {
  Timer? _timer;
  var _tick = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Reel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final spin =
        widget.settled == null &&
        widget.pool.isNotEmpty &&
        animationsEnabled(context);
    if (spin && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 110), (_) {
        if (mounted) {
          setState(() => _tick += 1);
        }
      });
    } else if (!spin) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settled = widget.settled;
    if (settled != null) {
      return PopIn(
        key: ValueKey<String>(settled),
        child: widget.build(settled),
      );
    }
    if (widget.pool.isEmpty) {
      return widget.build('fork-and-knife-with-plate');
    }
    return Opacity(
      opacity: 0.55,
      child: widget.build(widget.pool[_tick % widget.pool.length]),
    );
  }
}

/// `.cm .bar` while the solver works: a bar that wanders, as the prototype's
/// random widths, until the result fixes it.
class SearchingBar extends StatefulWidget {
  const SearchingBar({
    required this.color,
    required this.track,
    required this.height,
    super.key,
  });

  final Color color;
  final Color track;
  final double height;

  @override
  State<SearchingBar> createState() => _SearchingBarState();
}

class _SearchingBarState extends State<SearchingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsEnabled(context)) {
      if (!_controller.isAnimating) {
        unawaited(_controller.repeat(reverse: true));
      }
    } else {
      _controller
        ..stop()
        ..value = 0.3;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final value =
            0.15 + 0.6 * Curves.easeInOut.transform(_controller.value);
        return ClipRRect(
          borderRadius: BorderRadius.circular(widget.height),
          child: SizedBox(
            height: widget.height,
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: ColoredBox(color: widget.track)),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: value,
                  child: ColoredBox(color: widget.color),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Counts from 0 to [value] once, as the prototype's countTo.
class CountUp extends StatelessWidget {
  const CountUp({
    required this.value,
    required this.format,
    required this.style,
    super.key,
  });

  final double value;
  final String Function(double value) format;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!animationsEnabled(context)) {
      return Text(format(value), style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double number, Widget? child) {
        return Text(format(number), style: style);
      },
    );
  }
}

/// Seconds since [since], ticking once a second.
class Elapsed extends StatefulWidget {
  const Elapsed({required this.since, required this.build, super.key});

  final DateTime since;
  final Widget Function(Duration elapsed) build;

  @override
  State<Elapsed> createState() => _ElapsedState();
}

class _ElapsedState extends State<Elapsed> {
  Timer? _timer;
  late Duration _offset;
  var _ticks = 0;

  @override
  void initState() {
    super.initState();
    // Counted from the start, then by the ticker: one second per tick.
    _offset = DateTime.now().difference(widget.since);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _ticks += 1);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = _offset + Duration(seconds: _ticks);
    return widget.build(elapsed.isNegative ? Duration.zero : elapsed);
  }
}

/// The prototype's confetti burst, once, from the top centre.
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key});

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  final List<_Piece> _pieces = <_Piece>[];

  @override
  void initState() {
    super.initState();
    final random = math.Random(7);
    const colors = <Color>[
      Color(0xFF2BD49A),
      Color(0xFF38BDF8),
      Color(0xFFFF9147),
      Color(0xFFFFC23D),
      Color(0xFFFF6B81),
      Color(0xFF5C9BFF),
    ];
    for (var i = 0; i < 90; i += 1) {
      _pieces.add(
        _Piece(
          vx: (random.nextDouble() - 0.5) * 1.6,
          vy: -random.nextDouble() * 1.6 - 0.4,
          size: 5 + random.nextDouble() * 7,
          spin: (random.nextDouble() - 0.5) * 12,
          color: colors[random.nextInt(colors.length)],
        ),
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationsEnabled(context) && _controller.value == 0) {
      unawaited(_controller.forward());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!animationsEnabled(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          if (_controller.isCompleted) {
            return const SizedBox.shrink();
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(_pieces, _controller.value),
          );
        },
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.vx,
    required this.vy,
    required this.size,
    required this.spin,
    required this.color,
  });

  final double vx;
  final double vy;
  final double size;
  final double spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter(this.pieces, this.t);

  final List<_Piece> pieces;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.3);
    final paint = Paint();
    final scale = size.shortestSide;
    for (final piece in pieces) {
      final x = origin.dx + piece.vx * scale * t;
      final y = origin.dy + (piece.vy * t + 1.8 * t * t) * scale * 0.6;
      paint.color = piece.color.withValues(alpha: (1 - t).clamp(0, 1));
      canvas
        ..save()
        ..translate(x, y)
        ..rotate(piece.spin * t)
        ..drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size / 2,
          ),
          paint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
