import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/server_check_repository.dart';
import '../domain/server_status.dart';

final serverCheckControllerProvider =
    AsyncNotifierProvider<ServerCheckController, ServerStatus>(
      ServerCheckController.new,
      retry: _noRetry,
    );

Duration? _noRetry(int retryCount, Object error) => null;

class ServerCheckController extends AsyncNotifier<ServerStatus> {
  @override
  Future<ServerStatus> build() {
    return ref.watch(serverCheckRepositoryProvider).load();
  }

  Future<void> retry() async {
    state = const AsyncLoading<ServerStatus>();
    state = await AsyncValue.guard<ServerStatus>(
      () => ref.read(serverCheckRepositoryProvider).load(),
    );
  }
}
