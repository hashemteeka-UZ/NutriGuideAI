import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_provider.dart';
import 'generated/clients/health_client.dart';

final healthClientProvider = Provider<HealthClient>((ref) {
  return HealthClient(ref.watch(dioProvider));
});
