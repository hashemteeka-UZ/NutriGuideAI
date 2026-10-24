import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import 'generated/clients/account_client.dart';
import 'generated/clients/auth_client.dart';
import 'generated/clients/health_client.dart';
import 'generated/clients/reference_client.dart';

final healthClientProvider = Provider<HealthClient>((ref) {
  return HealthClient(ref.watch(dioProvider));
});

final authClientProvider = Provider<AuthClient>((ref) {
  return AuthClient(ref.watch(dioProvider));
});

final accountClientProvider = Provider<AccountClient>((ref) {
  return AccountClient(ref.watch(dioProvider));
});

final referenceClientProvider = Provider<ReferenceClient>((ref) {
  return ReferenceClient(ref.watch(dioProvider));
});
