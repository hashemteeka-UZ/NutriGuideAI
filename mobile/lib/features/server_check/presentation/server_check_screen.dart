import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/failure_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../domain/server_status.dart';
import 'server_check_controller.dart';

class ServerCheckScreen extends ConsumerWidget {
  const ServerCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final status = ref.watch(serverCheckControllerProvider);
    final baseUrl = ref.watch(appConfigProvider).apiBaseUrl;

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewport = constraints.maxHeight;
            final minHeight = viewport.isFinite
                ? (viewport - 48).clamp(0.0, viewport).toDouble()
                : 0.0;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: status.when(
                      loading: () =>
                          _LoadingState(label: l10n.serverCheckLoading),
                      error: (error, _) => _ErrorState(
                        message: error is AppFailure
                            ? failureMessage(l10n, error)
                            : l10n.failureGeneric,
                        retryLabel: l10n.serverCheckRetry,
                        onRetry: () {
                          unawaited(
                            ref
                                .read(serverCheckControllerProvider.notifier)
                                .retry(),
                          );
                        },
                        baseUrl: baseUrl,
                      ),
                      data: (server) => server.needsUpdate
                          ? _MessageState(
                              icon: Icons.system_update_alt_rounded,
                              iconColor: colors.onBrand,
                              iconBackground: colors.warn,
                              title: l10n.serverCheckNeedsUpdate,
                              lines: _detailLines(l10n, server),
                              baseUrl: baseUrl,
                            )
                          : _MessageState(
                              icon: Icons.check_rounded,
                              iconColor: colors.onBrand,
                              iconBackground: colors.brand,
                              title: l10n.serverCheckConnected,
                              lines: _detailLines(l10n, server),
                              baseUrl: baseUrl,
                              fadeIcon: true,
                            ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<_DetailLine> _detailLines(AppLocalizations l10n, ServerStatus server) {
    return <_DetailLine>[
      _DetailLine(l10n.serverCheckApiVersionLabel, server.apiVersion),
      _DetailLine(
        l10n.serverCheckDatasetVersionLabel,
        server.datasetVersion ?? l10n.serverCheckUnknownValue,
      ),
      _DetailLine(l10n.serverCheckPlannerLabel, server.plannerName),
    ];
  }
}

class _DetailLine {
  const _DetailLine(this.label, this.value);

  final String label;
  final String value;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      label: label,
      child: CircularProgressIndicator(color: colors.brand),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    required this.baseUrl,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.cloud_off_rounded, color: colors.danger, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(color: colors.fg),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: colors.brand,
              foregroundColor: colors.onBrand,
            ),
            child: Text(retryLabel),
          ),
          _BaseUrlLine(baseUrl: baseUrl),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.lines,
    required this.baseUrl,
    this.fadeIcon = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final List<_DetailLine> lines;
  final String baseUrl;
  final bool fadeIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return _Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StatusIcon(
            icon: icon,
            color: iconColor,
            background: fadeIcon ? null : iconBackground,
            fade: fadeIcon,
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colors.fg,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          for (final line in lines) ...<Widget>[
            _ValueLine(label: line.label, value: line.value),
            const SizedBox(height: 8),
          ],
          _BaseUrlLine(baseUrl: baseUrl),
        ],
      ),
    );
  }
}

class _StatusIcon extends StatefulWidget {
  const _StatusIcon({
    required this.icon,
    required this.color,
    required this.fade,
    this.background,
  });

  final IconData icon;
  final Color color;
  final Color? background;
  final bool fade;

  @override
  State<_StatusIcon> createState() => _StatusIconState();
}

class _StatusIconState extends State<_StatusIcon> {
  var _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.fade) {
      _visible = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final animate = widget.fade && animationsEnabled(context);
    final icon = Icon(widget.icon, color: widget.color, size: 40);
    final disc = Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: widget.background,
        gradient: widget.fade ? colors.heroGradient : null,
        shape: BoxShape.circle,
      ),
      child: icon,
    );
    if (!widget.fade) {
      return disc;
    }
    return AnimatedOpacity(
      opacity: animate && !_visible ? 0 : 1,
      duration: animate ? const Duration(milliseconds: 350) : Duration.zero,
      child: disc,
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final body = Theme.of(context).textTheme.bodyLarge;
    return Text.rich(
      TextSpan(
        style: body?.copyWith(color: colors.fg2),
        children: <InlineSpan>[
          TextSpan(text: label),
          const TextSpan(text: '  '),
          TextSpan(
            text: value,
            style: colors.numeric.copyWith(color: colors.fg, fontSize: 16),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _BaseUrlLine extends StatelessWidget {
  const _BaseUrlLine({required this.baseUrl});

  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        baseUrl,
        textAlign: TextAlign.center,
        style: colors.numeric.copyWith(color: colors.fg3, fontSize: 12),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.line),
      ),
      child: Padding(padding: const EdgeInsets.all(28), child: child),
    );
  }
}
