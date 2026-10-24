import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/ui/emoji.dart';

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    required this.emoji,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.enabled = true,
    this.semanticLabel,
    super.key,
  });

  final String emoji;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final background = selected
        ? Color.alphaBlend(colors.brand.withValues(alpha: 0.10), colors.surface)
        : colors.surface;
    final label =
        semanticLabel ?? (subtitle == null ? title : '$title. $subtitle');
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: enabled ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected ? colors.brand : colors.line,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    ExcludeSemantics(child: _EmojiBox(emoji: emoji)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.fg,
                            ),
                          ),
                          if (subtitle != null) ...<Widget>[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.fg3,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Check(selected: selected),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiBox extends StatelessWidget {
  const _EmojiBox({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.brandSoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Emoji(emoji, size: 30),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? colors.brand : Colors.transparent,
        border: Border.all(
          color: selected ? colors.brand : colors.line,
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check, size: 16, color: colors.onBrand)
          : null,
    );
  }
}

class StepIntro extends StatelessWidget {
  const StepIntro({
    required this.title,
    required this.subtitle,
    this.badge,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (badge != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.signalSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Emoji('sparkles', size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.signal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          title,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: colors.fg,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.fg2,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class ExplainTile extends StatefulWidget {
  const ExplainTile({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  State<ExplainTile> createState() => _ExplainTileState();
}

class _ExplainTileState extends State<ExplainTile> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: colors.brand2,
            alignment: AlignmentDirectional.centerStart,
            minimumSize: const Size(48, 48),
          ),
          onPressed: () => setState(() => _open = !_open),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  widget.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(_open ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              widget.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.fg2,
                height: 1.45,
              ),
            ),
          ),
      ],
    );
  }
}

class TipBanner extends StatelessWidget {
  const TipBanner({required this.emoji, required this.text, super.key});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Emoji(emoji, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.fg2, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
