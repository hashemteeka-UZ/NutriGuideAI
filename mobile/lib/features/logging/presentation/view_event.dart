import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/logging_providers.dart';

/// Queues one VIEW for [mealId] when [child] opens (Decision #267).
class ViewEvent extends ConsumerStatefulWidget {
  const ViewEvent({required this.mealId, required this.child, super.key});

  final int? mealId;
  final Widget child;

  @override
  ConsumerState<ViewEvent> createState() => _ViewEventState();
}

class _ViewEventState extends ConsumerState<ViewEvent> {
  @override
  void initState() {
    super.initState();
    final mealId = widget.mealId;
    if (mealId == null) {
      return;
    }
    unawaited(
      ref
          .read(interactionQueueProvider)
          .view(mealId: mealId)
          .catchError((Object _) {}),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
