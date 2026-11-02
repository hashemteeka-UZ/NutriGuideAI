import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/storage/secure_store.dart';
import '../../auth/domain/session.dart';
import '../../auth/presentation/session_controller.dart';

/// The optional profile photo (P2f). It stays on this phone only: a square
/// PNG of at most [profilePhotoSize] px in the app documents folder, its path
/// in secure storage. It is never uploaded, and it is deleted on sign-out and
/// on account deletion (both end the session).
const profilePhotoKey = 'ng.profile_photo_path';

const profilePhotoSize = 512;

enum PhotoSource { gallery, camera }

/// Picks image bytes; null when the person cancels. Tests use a fake.
abstract interface class PhotoPicker {
  Future<Uint8List?> pick(PhotoSource source);
}

class ImagePickerPhotoPicker implements PhotoPicker {
  const ImagePickerPhotoPicker();

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    // image_picker uses the Android photo picker for the gallery and the
    // camera app for a photo, so no storage or camera permission is needed.
    // A max size makes it scale the image and apply its EXIF rotation.
    final file = await ImagePicker().pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 95,
      preferredCameraDevice: CameraDevice.front,
    );
    return file?.readAsBytes();
  }
}

/// Where photos are written; tests use a temp folder.
abstract interface class PhotoFolder {
  Future<Directory> directory();
}

class DocumentsPhotoFolder implements PhotoFolder {
  const DocumentsPhotoFolder();

  @override
  Future<Directory> directory() => getApplicationDocumentsDirectory();
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => const ImagePickerPhotoPicker(),
);

final photoFolderProvider = Provider<PhotoFolder>(
  (ref) => const DocumentsPhotoFolder(),
);

final profilePhotoStoreProvider = Provider<SecureKeyValue>(
  (ref) => ref.watch(secureStoreProvider),
);

/// Center square of [bytes], scaled down to at most [size] px, as PNG.
Future<Uint8List> squarePhoto(
  Uint8List bytes, {
  int size = profilePhotoSize,
}) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final side = math.min(image.width, image.height);
  final out = math.min(size, side);
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(
    image,
    ui.Rect.fromLTWH(
      (image.width - side) / 2,
      (image.height - side) / 2,
      side.toDouble(),
      side.toDouble(),
    ),
    ui.Rect.fromLTWH(0, 0, out.toDouble(), out.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  final square = await picture.toImage(out, out);
  final data = await square.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  square.dispose();
  picture.dispose();
  codec.dispose();
  return data!.buffer.asUint8List();
}

final profilePhotoProvider = NotifierProvider<ProfilePhotoController, String?>(
  ProfilePhotoController.new,
);

/// The path of the current photo, or null for the drawn avatar.
class ProfilePhotoController extends Notifier<String?> {
  @override
  String? build() {
    ref.listen<SessionState>(sessionControllerProvider, (
      SessionState? previous,
      SessionState next,
    ) {
      if (next is SignedOut && previous is SignedIn) {
        unawaited(reset());
      }
    });
    unawaited(_load());
    return null;
  }

  /// Picks, crops, stores. False when nothing was picked or it failed.
  Future<bool> choose(PhotoSource source) async {
    final Uint8List? picked;
    try {
      picked = await ref.read(photoPickerProvider).pick(source);
    } on Object {
      return false;
    }
    if (picked == null || !ref.mounted) {
      return false;
    }
    try {
      final png = await squarePhoto(picked);
      final folder = await ref.read(photoFolderProvider).directory();
      final file = File(
        p.join(
          folder.path,
          'profile_photo_${DateTime.now().microsecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(png, flush: true);
      final old = state;
      await ref
          .read(profilePhotoStoreProvider)
          .write(profilePhotoKey, file.path);
      if (!ref.mounted) {
        return true;
      }
      state = file.path;
      await _delete(old);
      return true;
    } on Object {
      return false;
    }
  }

  /// Back to the drawn avatar: the file and the stored path are removed.
  Future<void> reset() async {
    final old = state;
    state = null;
    String? stored;
    try {
      final store = ref.read(profilePhotoStoreProvider);
      stored = await store.read(profilePhotoKey);
      await store.delete(profilePhotoKey);
    } on Object {
      // Nothing more to forget.
    }
    await _delete(old);
    if (stored != old) {
      await _delete(stored);
    }
  }

  Future<void> _delete(String? path) async {
    if (path == null) {
      return;
    }
    final file = File(path);
    imageCache.evict(FileImage(file));
    // An image still being read can hold the file for a moment (Windows
    // locks it), so a failed delete is tried a few more times.
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (file.existsSync()) {
          await file.delete();
        }
        return;
      } on Object {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  Future<void> _load() async {
    try {
      final stored = await ref
          .read(profilePhotoStoreProvider)
          .read(profilePhotoKey);
      if (!ref.mounted || stored == null || state != null) {
        return;
      }
      if (File(stored).existsSync()) {
        state = stored;
      }
    } on Object {
      return;
    }
  }
}
