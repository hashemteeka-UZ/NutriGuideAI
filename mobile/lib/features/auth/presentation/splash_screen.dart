import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/motion.dart';
import '../../../core/ui/emoji.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final animate = animationsEnabled(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: colors.heroGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Emoji('seedling', size: 72),
              const SizedBox(height: 28),
              Semantics(
                label: l10n.splashLoading,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    value: animate ? null : 0,
                    strokeWidth: 3,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
