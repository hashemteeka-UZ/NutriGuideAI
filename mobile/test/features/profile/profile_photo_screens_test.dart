import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/profile/data/profile_photo.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/memory_secure.dart';
import '../../support/pump_app.dart';

void main() {
  testNutriguide(
    'the photo heads Today and Account, the sheet offers three choices, and sign-out forgets it',
    (tester) async {
      final dir = Directory.systemTemp.createTempSync('photo_screens');
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // The test image loader can still hold the file on Windows.
        }
      });
      // 1x1 transparent PNG.
      final file = File('${dir.path}/profile_photo_1.png')
        ..writeAsBytesSync(const <int>[
          0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, //
          0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
          0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
          0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63,
          0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4,
          0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
          0x82,
        ]);
      final secure = MemorySecure();
      await secure.write(profilePhotoKey, file.path);
      final auth = FakeAuthRepository(
        restored: const SignedIn(account: AccountInfo(hasProfile: true)),
      );
      await pumpNutriguide(tester, auth: auth, photoStore: secure);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-photo')), findsOneWidget);

      await tester.tap(find.byKey(const Key('tab-me')));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byKey(const Key('account-header')),
          matching: find.byKey(const Key('profile-photo')),
        ),
        findsOneWidget,
      );
      // Screen readers can open it too.
      expect(
        tester.getSemantics(find.byKey(const Key('profile-avatar'))),
        matchesSemantics(
          isButton: true,
          hasTapAction: true,
          label: 'تغيير صورتك',
        ),
      );
      await tester.tap(find.byKey(const Key('profile-avatar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('photo-sheet')), findsOneWidget);
      expect(find.text('اختر صورة'), findsOneWidget);
      expect(find.text('التقط صورة'), findsOneWidget);
      expect(find.text('استخدم الرسمة'), findsOneWidget);
      // The name sheet did not open from the avatar tap.
      expect(find.byKey(const Key('name-sheet')), findsNothing);
      Navigator.of(tester.element(find.byKey(const Key('photo-sheet')))).pop();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('account-logout')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('account-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('account-logout')));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(auth.logoutCalls, 1);
      // Sign-out forgets the photo (the file delete itself is covered in
      // profile_photo_test.dart; here the test image loader holds the file).
      expect(await secure.read(profilePhotoKey), isNull);
      expect(find.byKey(const Key('profile-photo')), findsNothing);
    },
  );
}
