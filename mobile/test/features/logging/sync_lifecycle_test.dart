import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutriguide/core/sync/sync_engine.dart';
import 'package:nutriguide/features/auth/data/auth_repository_impl.dart';
import 'package:nutriguide/features/auth/domain/account_info.dart';
import 'package:nutriguide/features/auth/domain/session.dart';
import 'package:nutriguide/features/auth/presentation/session_controller.dart';
import 'package:nutriguide/features/logging/data/logging_providers.dart';
import 'package:nutriguide/features/logging/presentation/sync_lifecycle.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<bool> network;
  late _CountingTrigger trigger;

  ProviderContainer start({required bool hasProfile}) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            restored: SignedIn(account: AccountInfo(hasProfile: hasProfile)),
          ),
        ),
        networkUpProvider.overrideWithValue(network.stream),
        syncTriggerProvider.overrideWithValue(trigger),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle(ProviderContainer container) async {
    container.read(sessionControllerProvider);
    await pumpEventQueue();
    container.read(syncLifecycleProvider);
    await pumpEventQueue();
  }

  setUp(() {
    network = StreamController<bool>();
    trigger = _CountingTrigger();
  });

  tearDown(() => network.close());

  test('a sync starts when the network comes back', () async {
    final container = start(hasProfile: true);
    await settle(container);
    final before = trigger.soonCalls;

    network.add(false);
    await pumpEventQueue();
    expect(trigger.soonCalls, before);

    network.add(true);
    await pumpEventQueue();
    expect(trigger.soonCalls, before + 1);
  });

  test('the first network report alone does not sync again', () async {
    final container = start(hasProfile: true);
    await settle(container);

    network
      ..add(true)
      ..add(true);
    await pumpEventQueue();

    expect(trigger.soonCalls, 0);
  });

  test('no sync before the profile exists', () async {
    final container = start(hasProfile: false);
    await settle(container);

    network
      ..add(false)
      ..add(true);
    await pumpEventQueue();

    expect(trigger.soonCalls, 0);
    expect(trigger.nowCalls, 0);
  });
}

class _CountingTrigger implements SyncTrigger {
  @override
  Duration get delay => Duration.zero;

  @override
  void dispose() {}

  int soonCalls = 0;
  int nowCalls = 0;

  @override
  void soon() => soonCalls += 1;

  @override
  Future<SyncOutcome> now() async {
    nowCalls += 1;
    return SyncOutcome.done;
  }
}
