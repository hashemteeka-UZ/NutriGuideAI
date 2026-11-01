import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/motion.dart';
import '../data/display_name.dart';

/// «ماذا نناديك؟»: the optional first page of onboarding (prototype step
/// `name`). The name is kept on this phone only.
class NamePage extends ConsumerStatefulWidget {
  const NamePage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  ConsumerState<NamePage> createState() => _NamePageState();
}

class _NamePageState extends ConsumerState<NamePage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    await ref.read(displayNameProvider.notifier).save(_controller.text);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.appColors;
    final filled = cleanDisplayName(_controller.text) != null;
    return Column(
      key: const Key('onb-name-page'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            key: const Key('onb-name-skip'),
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: widget.onDone,
            child: Text(l10n.onbNameSkip),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.onbNameTitle,
                  style: TextStyle(
                    fontSize: 27,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: colors.fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(l10n.onbNameSubtitle, style: TextStyle(color: colors.fg2)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: Emoji('waving-hand', size: 92)),
                ),
                TextField(
                  key: const Key('onb-name-field'),
                  controller: _controller,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  maxLength: displayNameMaxLength,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colors.fg,
                  ),
                  decoration: InputDecoration(
                    hintText: l10n.onbNameHint,
                    hintStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: colors.fg3,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: colors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: colors.line, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: colors.brand, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (filled) {
                      unawaited(_continue());
                    }
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.onbNamePrivacy,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: colors.fg3),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: FilledButton(
            key: const Key('onb-name-continue'),
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: filled ? () => unawaited(_continue()) : null,
            child: Text(l10n.onbContinue),
          ),
        ),
      ],
    );
  }
}

/// Edits the name from the account header; an empty name removes it.
Future<void> showNameSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController(
    text: ref.read(displayNameProvider) ?? '',
  );
  return showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          child: Padding(
            key: const Key('name-sheet'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  l10n.onbNameTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(l10n.onbNamePrivacy),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('name-sheet-field'),
                  controller: controller,
                  autofocus: true,
                  maxLength: displayNameMaxLength,
                  decoration: InputDecoration(hintText: l10n.onbNameHint),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  key: const Key('name-sheet-save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  onPressed: () {
                    unawaited(
                      ref
                          .read(displayNameProvider.notifier)
                          .save(controller.text),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(l10n.waterGoalSave),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
