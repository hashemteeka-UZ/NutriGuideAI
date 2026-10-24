import 'dart:async';

import 'package:flutter/widgets.dart';

import '../theme/motion.dart';

class RiseIn extends StatefulWidget {
  const RiseIn({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  @override
  State<RiseIn> createState() => _RiseInState();
}

class _RiseInState extends State<RiseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) {
      return;
    }
    _started = true;
    if (!animationsEnabled(context)) {
      _controller.value = 1;
      return;
    }
    unawaited(_run());
  }

  Future<void> _run() async {
    await Future<void>.delayed(Duration(milliseconds: 60 * widget.index));
    if (mounted) {
      await _controller.forward();
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
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - t)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
