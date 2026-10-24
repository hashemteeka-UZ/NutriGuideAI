# NutriGuide

Android app for NutriGuideAI. The HTTP contract is `docs/api/openapi.json`. This folder is the Flutter client.

## Run

Start the API first (`http://localhost:8000` from this machine). Then start an Android emulator and, from `mobile/`:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

`10.0.2.2` is the emulator's alias for the host. The debug build allows cleartext HTTP only for `10.0.2.2` and `localhost`. Release builds do not. If `API_BASE_URL` is omitted, the app uses `http://10.0.2.2:8000`.

## Regenerate the API client

From `mobile/`, after `docs/api/openapi.json` changes:

```powershell
.\tool\regenerate_api.ps1
```

```bash
bash tool/regenerate_api.sh
```

That runs `dart run swagger_parser`, `dart run build_runner build --delete-conflicting-outputs`, and `dart run tool/gen_contract_examples_test.dart`. Do not edit `lib/core/api/generated/` by hand.

## Emoji

Fluent Emoji Flat (MIT) is stored in `assets/emoji/`. After `docs/project/ui/prototype_v3/2_fe.js` changes, regenerate it from `mobile/`:

```powershell
dart run tool/extract_emoji.dart
```

See `assets/emoji/LICENSE`.

## Checks

From `mobile/`:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

`dart format` and `flutter analyze` skip `lib/core/api/generated/` and `*.g.dart`. The contract example test checks every component schema that has an `example`.
