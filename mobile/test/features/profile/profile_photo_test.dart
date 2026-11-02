import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/profile/data/profile_photo.dart';

import '../../support/memory_secure.dart';

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF08875D),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

Future<(int, int)> _size(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return (frame.image.width, frame.image.height);
}

class _FakePicker implements PhotoPicker {
  _FakePicker(this.next);

  Uint8List? next;
  final List<PhotoSource> asked = <PhotoSource>[];

  @override
  Future<Uint8List?> pick(PhotoSource source) async {
    asked.add(source);
    return next;
  }
}

class _TempFolder implements PhotoFolder {
  _TempFolder(this.dir);

  final Directory dir;

  @override
  Future<Directory> directory() async => dir;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('photos are cropped to the centre square, at most 512 px', (
    tester,
  ) async {
    await tester.runAsync(() async {
      expect(await _size(await squarePhoto(await _png(300, 200))), (200, 200));
      expect(await _size(await squarePhoto(await _png(1000, 800))), (512, 512));
    });
  });

  testWidgets('choose, replace and reset keep one file on the phone only', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('photo_test');
      addTearDown(() => dir.delete(recursive: true));
      final store = MemorySecure();
      final picker = _FakePicker(await _png(640, 480));
      final container = ProviderContainer(
        overrides: [
          photoPickerProvider.overrideWithValue(picker),
          photoFolderProvider.overrideWithValue(_TempFolder(dir)),
          profilePhotoStoreProvider.overrideWithValue(store),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(profilePhotoProvider.notifier);

      expect(await controller.choose(PhotoSource.gallery), isTrue);
      final first = container.read(profilePhotoProvider)!;
      expect(File(first).existsSync(), isTrue);
      expect(first, startsWith(dir.path));
      expect(await store.read(profilePhotoKey), first);
      expect(await _size(File(first).readAsBytesSync()), (480, 480));

      expect(await controller.choose(PhotoSource.camera), isTrue);
      final second = container.read(profilePhotoProvider)!;
      expect(second, isNot(first));
      expect(File(first).existsSync(), isFalse);
      expect(picker.asked, <PhotoSource>[
        PhotoSource.gallery,
        PhotoSource.camera,
      ]);

      // Cancelling keeps the current photo.
      picker.next = null;
      expect(await controller.choose(PhotoSource.gallery), isFalse);
      expect(container.read(profilePhotoProvider), second);

      await controller.reset();
      expect(container.read(profilePhotoProvider), isNull);
      expect(File(second).existsSync(), isFalse);
      expect(await store.read(profilePhotoKey), isNull);
      expect(dir.listSync(), isEmpty);
    });
  });

  testWidgets('a stored photo is loaded at start, a missing file is not', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final dir = await Directory.systemTemp.createTemp('photo_load');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/p.png')
        ..writeAsBytesSync(await _png(10, 10));
      Future<String?> loaded(String stored) async {
        final store = MemorySecure();
        await store.write(profilePhotoKey, stored);
        final container = ProviderContainer(
          overrides: [profilePhotoStoreProvider.overrideWithValue(store)],
        );
        addTearDown(container.dispose);
        container.read(profilePhotoProvider);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return container.read(profilePhotoProvider);
      }

      expect(await loaded(file.path), file.path);
      expect(await loaded('${dir.path}/gone.png'), isNull);
    });
  });

  test('the app asks for no storage or camera permission', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    for (final permission in <String>[
      'READ_EXTERNAL_STORAGE',
      'WRITE_EXTERNAL_STORAGE',
      'READ_MEDIA_IMAGES',
      'CAMERA',
    ]) {
      expect(manifest, isNot(contains('permission.$permission')));
    }
  });
}
