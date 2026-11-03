import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'server_wake.dart';

/// Lays the app out under a short notice while the hosted server wakes up,
/// so a slow first call reads as waiting rather than as a broken network.
class ServerWakeBanner extends ConsumerWidget {
  const ServerWakeBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waking = ref.watch(serverWakeProvider) == ServerWake.waking;
    return Stack(
      children: <Widget>[
        child,
        if (waking)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Center(child: _Notice(key: Key('server-waking'))),
            ),
          ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: colors.warn.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.fg,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  AppLocalizations.of(context).serverWaking,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
