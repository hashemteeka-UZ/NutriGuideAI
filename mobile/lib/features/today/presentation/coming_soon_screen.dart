import 'package:flutter/material.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    required this.detail,
    required this.screenKey,
    super.key,
  });

  final String detail;
  final String screenKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    return Scaffold(
      key: Key(screenKey),
      backgroundColor: colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: <Widget>[
            Text(
              l10n.comingSoon,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: colors.fg, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text(
              detail,
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: colors.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
