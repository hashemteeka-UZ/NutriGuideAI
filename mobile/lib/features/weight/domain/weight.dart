/// What happened to a weight the user entered (Decisions #271, #275).
enum WeightSaveStatus {
  created,
  updated,

  /// The server keeps a newer weight for that day.
  staleIgnored,

  /// No connection: queued in the outbox.
  queued,
}

class WeightSaveResult {
  const WeightSaveResult({
    required this.status,
    this.goalReached = false,
    this.newTargetId,
    this.targetStatus,
  });

  final WeightSaveStatus status;
  final bool goalReached;
  final int? newTargetId;

  /// NOT_TRIGGERED, NO_CURRENT_TARGET, CREATED, INELIGIBLE or GOAL_INVALID.
  final String? targetStatus;
}

class StoredWeight {
  const StoredWeight({
    required this.measuredOn,
    required this.weightKg,
    required this.pending,
  });

  final String measuredOn;
  final double weightKg;
  final bool pending;
}

/// The wheel of the weight sheet.
const weightMinKg = 30.0;
const weightMaxKg = 250.0;
const weightStepKg = 0.1;

class WeightException implements Exception {
  const WeightException(this.code);

  final String code;

  @override
  String toString() => 'WeightException($code)';
}
