import '../../plan/domain/plan.dart';

/// One consumption log as the phone knows it.
class LoggedMeal {
  const LoggedMeal({
    required this.clientUuid,
    required this.kind,
    required this.logDate,
    required this.consumedAt,
    required this.state,
    this.serverLogId,
    this.planItemId,
    this.mealId,
    this.slot,
    this.servingsConsumed,
    this.name,
    this.kcal,
    this.proteinG,
    this.carbG,
    this.fatG,
  });

  final String clientUuid;
  final int? serverLogId;
  final String kind;
  final int? planItemId;
  final int? mealId;
  final String logDate;
  final String? slot;
  final double? servingsConsumed;
  final DateTime consumedAt;
  final String? name;
  final double? kcal;
  final double? proteinG;
  final double? carbG;
  final double? fatG;

  /// PENDING, CONFIRMED, REJECTED or DELETING.
  final String state;

  bool get pending => state == 'PENDING';
  bool get confirmed => state == 'CONFIRMED';
  bool get rejected => state == 'REJECTED';
  bool get deleting => state == 'DELETING';
}

enum PlanItemLogState {
  /// Not eaten yet, or the log was undone.
  none,

  /// Logged on the phone, not on the server yet.
  pending,

  /// The server has the log.
  confirmed,

  /// The server refused the log.
  rejected,
}

/// The log of [planItemId] that decides its state: an undone log only
/// counts when there is no other.
LoggedMeal? logForItem(int planItemId, List<LoggedMeal> logs) {
  LoggedMeal? undone;
  for (final log in logs) {
    if (log.planItemId != planItemId) {
      continue;
    }
    if (!log.deleting) {
      return log;
    }
    undone = log;
  }
  return undone;
}

PlanItemLogState logStateOf(PlanItem item, List<LoggedMeal> logs) {
  final log = logForItem(item.planItemId, logs);
  if (log == null) {
    // A log from another device the change feed has not brought yet.
    return item.logged ? PlanItemLogState.confirmed : PlanItemLogState.none;
  }
  if (log.deleting) {
    return PlanItemLogState.none;
  }
  if (log.pending) {
    return PlanItemLogState.pending;
  }
  if (log.rejected) {
    return PlanItemLogState.rejected;
  }
  return PlanItemLogState.confirmed;
}

bool isEaten(PlanItem item, List<LoggedMeal> logs) {
  final state = logStateOf(item, logs);
  return state == PlanItemLogState.pending ||
      state == PlanItemLogState.confirmed;
}

/// Portions offered by «كمية مختلفة», as a share of the planned portion.
const portionFactors = <double>[0.5, 1, 1.5];

/// What Today adds to the server totals until the server has the logs
/// (Decision #266). Every number is a server value: the plan item's
/// nutrients scaled by the share of the planned portion that was eaten.
class ProvisionalTotals {
  const ProvisionalTotals({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
    required this.active,
  });

  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  /// True while a pending log or a pending undo exists.
  final bool active;

  static const none = ProvisionalTotals(
    kcal: 0,
    proteinG: 0,
    carbG: 0,
    fatG: 0,
    active: false,
  );
}

ProvisionalTotals provisionalTotals(
  List<PlanItem> items,
  List<LoggedMeal> logs,
) {
  final byId = <int, PlanItem>{for (final item in items) item.planItemId: item};
  var kcal = 0.0;
  var protein = 0.0;
  var carb = 0.0;
  var fat = 0.0;
  var active = false;
  for (final log in logs) {
    if (!log.pending && !log.deleting) {
      continue;
    }
    active = true;
    final item = byId[log.planItemId];
    if (log.deleting) {
      // An undo not sent yet: the server totals still count this log.
      final share = _share(item, log);
      kcal -= log.kcal ?? (item == null ? 0 : item.kcal * share);
      protein -= log.proteinG ?? (item == null ? 0 : item.proteinG * share);
      carb -= log.carbG ?? (item == null ? 0 : item.carbG * share);
      fat -= log.fatG ?? (item == null ? 0 : item.fatG * share);
      continue;
    }
    if (item == null) {
      // A MEAL log: its row holds the snapshot's per-serving server values
      // × servings (#272).
      kcal += log.kcal ?? 0;
      protein += log.proteinG ?? 0;
      carb += log.carbG ?? 0;
      fat += log.fatG ?? 0;
      continue;
    }
    final share = _share(item, log);
    kcal += item.kcal * share;
    protein += item.proteinG * share;
    carb += item.carbG * share;
    fat += item.fatG * share;
  }
  return ProvisionalTotals(
    kcal: kcal,
    proteinG: protein,
    carbG: carb,
    fatG: fat,
    active: active,
  );
}

double _share(PlanItem? item, LoggedMeal log) {
  final eaten = log.servingsConsumed;
  if (item == null || eaten == null || item.servingsMultiplier <= 0) {
    return 1;
  }
  return eaten / item.servingsMultiplier;
}

/// What the sync status in Today's header shows.
enum SyncBadge { hidden, uploading, waiting, rejected }

class SyncStatusView {
  const SyncStatusView({
    required this.uploading,
    required this.pending,
    required this.rejected,
  });

  final bool uploading;
  final int pending;
  final int rejected;

  SyncBadge get badge {
    if (rejected > 0) {
      return SyncBadge.rejected;
    }
    if (uploading && pending > 0) {
      return SyncBadge.uploading;
    }
    if (pending > 0) {
      return SyncBadge.waiting;
    }
    return SyncBadge.hidden;
  }

  static const idle = SyncStatusView(uploading: false, pending: 0, rejected: 0);
}

enum RejectedKind { meal, water, weight }

/// A record the server refused, as listed under the red status.
class RejectedLog {
  const RejectedLog({
    required this.opId,
    required this.kind,
    required this.code,
    this.clientUuid,
    this.mealName,
    this.slot,
    this.amountMl,
    this.weightKg,
  });

  final String opId;
  final RejectedKind kind;
  final String code;
  final String? clientUuid;
  final String? mealName;
  final String? slot;
  final int? amountMl;
  final double? weightKg;
}

/// Thrown when an action cannot be queued.
class LoggingException implements Exception {
  const LoggingException(this.reason);

  final String reason;

  @override
  String toString() => 'LoggingException($reason)';
}
