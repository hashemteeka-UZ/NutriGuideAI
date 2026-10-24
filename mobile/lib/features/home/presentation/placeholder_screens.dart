import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';

// K.4
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final session = ref.watch(sessionControllerProvider);
    final email = session is SignedIn ? session.account?.email : null;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: _PlaceholderBody(
          children: <Widget>[
            Text(
              l10n.homeGreeting,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(color: colors.fg, fontWeight: FontWeight.w700),
            ),
            if (email != null && email.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                email,
                key: const Key('home-email'),
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: colors.fg2),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('browse-meals'),
              style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => context.push('/meals'),
              child: Text(l10n.browseMeals),
            ),
            const SizedBox(height: 12),
            TextButton(
              key: const Key('home-language'),
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () {
                unawaited(ref.read(localeProvider.notifier).toggle());
              },
              child: Text(arabic ? 'English' : 'العربية'),
            ),
            const SizedBox(height: 12),
            _LogoutButton(label: l10n.logout),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      onPressed: () {
        unawaited(ref.read(sessionControllerProvider.notifier).logout());
      },
      child: Text(label),
    );
  }
}
