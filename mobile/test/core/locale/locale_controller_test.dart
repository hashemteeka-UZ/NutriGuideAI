import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/locale/locale_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('locale code is updated before listeners see the change', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    String? seen;
    container.listen(localeProvider, (previous, next) {
      seen = container.read(localeCodeProvider).code;
    });

    await container.read(localeProvider.notifier).toggle();

    expect(container.read(localeProvider).languageCode, 'en');
    expect(seen, 'en');
  });
}
