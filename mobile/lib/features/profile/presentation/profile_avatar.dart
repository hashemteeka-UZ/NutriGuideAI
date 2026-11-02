import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/emoji.dart';
import '../../../core/ui/kit.dart';
import '../../../core/ui/motion.dart';
import '../data/profile_photo.dart';

/// The person's photo when one is set on this phone (P2f), otherwise the
/// drawn avatar. With [onTap] it opens the photo sheet.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({
    required this.emoji,
    required this.size,
    required this.emojiSize,
    required this.radius,
    required this.background,
    this.onTap,
    super.key,
  });

  final String emoji;
  final double size;
  final double emojiSize;
  final double radius;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = ref.watch(profilePhotoProvider);
    final drawn = EmojiTile(
      emoji,
      size: size,
      emojiSize: emojiSize,
      radius: radius,
      background: background,
    );
    final Widget avatar = path == null
        ? drawn
        : ClipRRect(
            key: const Key('profile-photo'),
            borderRadius: BorderRadius.circular(radius),
            child: Image.file(
              File(path),
              width: size,
              height: size,
              fit: BoxFit.cover,
              cacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (BuildContext context, Object error, _) => drawn,
            ),
          );
    final tap = onTap;
    if (tap == null) {
      return avatar;
    }
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).photoChange,
      excludeSemantics: true,
      onTap: tap,
      child: GestureDetector(
        key: const Key('profile-avatar'),
        behavior: HitTestBehavior.opaque,
        onTap: tap,
        child: avatar,
      ),
    );
  }
}

/// «اختر صورة» · «التقط صورة» · «استخدم الرسمة».
Future<void> showPhotoSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  Future<void> choose(BuildContext sheet, PhotoSource source) async {
    Navigator.pop(sheet);
    // Cancelling the picker keeps the current avatar, as does a picture
    // that cannot be read.
    await ref.read(profilePhotoProvider.notifier).choose(source);
  }

  return showAppSheet<void>(
    context: context,
    builder: (BuildContext sheet) {
      final colors = sheet.appColors;
      final hasPhoto = ref.read(profilePhotoProvider) != null;
      Widget option(String key, String emoji, String label, VoidCallback tap) {
        return ListTile(
          key: Key(key),
          leading: EmojiTile(emoji, size: 40, emojiSize: 26, radius: 12),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          onTap: tap,
        );
      }

      return SafeArea(
        child: Padding(
          key: const Key('photo-sheet'),
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.photoSheetTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              option(
                'photo-gallery',
                'artist-palette',
                l10n.photoGallery,
                () => unawaited(choose(sheet, PhotoSource.gallery)),
              ),
              option(
                'photo-camera',
                'sparkles',
                l10n.photoCamera,
                () => unawaited(choose(sheet, PhotoSource.camera)),
              ),
              if (hasPhoto)
                option('photo-reset', 'waving-hand', l10n.photoReset, () {
                  Navigator.pop(sheet);
                  unawaited(ref.read(profilePhotoProvider.notifier).reset());
                }),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: <Widget>[
                    const Emoji('shield', size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.photoPrivacy,
                        style: TextStyle(fontSize: 12.5, color: colors.fg3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
