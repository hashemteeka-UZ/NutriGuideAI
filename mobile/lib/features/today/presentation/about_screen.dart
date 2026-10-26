import 'package:flutter/material.dart';

import '../../../core/config/app_version.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/l10n/bidi.dart';
import '../../../core/theme/app_colors.dart';

/// «عن التطبيق والخصوصية» (#312).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final sections = <(Key, String, String)>[
      (
        const Key('about-disclaimer'),
        l10n.aboutDisclaimerTitle,
        l10n.aboutDisclaimer,
      ),
      (
        const Key('about-data'),
        l10n.aboutDataTitle,
        l10n.aboutData(isolate('USDA FoodData Central')),
      ),
      (const Key('about-learning'), l10n.aboutLearnTitle, l10n.aboutLearn),
    ];
    return Scaffold(
      key: const Key('about-screen'),
      backgroundColor: colors.bg,
      appBar: AppBar(
        backgroundColor: colors.bg,
        foregroundColor: colors.fg,
        title: Text(l10n.accountAbout),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              l10n.appTitle,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            // The version is laid out left to right on its own, so the
            // digits keep their order inside Arabic text (#315).
            Row(
              key: const Key('about-version'),
              children: <Widget>[
                Text(
                  l10n.aboutVersionLabel,
                  style: TextStyle(color: colors.fg2),
                ),
                const SizedBox(width: 6),
                Text(
                  appVersion,
                  key: const Key('about-version-number'),
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: colors.fg2),
                ),
              ],
            ),
            for (final (key, title, body) in sections) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                key: key,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
