import '../../plan/domain/plan.dart';

/// One glass of water as the phone knows it.
class WaterEntry {
  const WaterEntry({
    required this.clientUuid,
    required this.amountMl,
    required this.consumedAt,
    required this.state,
    this.serverLogId,
  });

  final String clientUuid;
  final int? serverLogId;
  final int amountMl;
  final DateTime consumedAt;

  /// PENDING, CONFIRMED, REJECTED or DELETING.
  final String state;

  bool get pending => state == 'PENDING';
  bool get deleting => state == 'DELETING';
  bool get rejected => state == 'REJECTED';
}

/// How the goal is shown (Decision #270).
enum WaterGoalMode {
  /// A number from the server.
  goal,

  /// The doctor sets the amount and none is stored: no number at all.
  clinician,

  /// No goal: the total only, with «حدد هدفًا».
  none,
}

class WaterView {
  const WaterView({
    required this.totalMl,
    required this.entries,
    required this.provisional,
    required this.requiresClinician,
    this.goalMl,
    this.source,
  });

  /// Server total plus glasses not sent yet, minus glasses being deleted.
  final int totalMl;
  final int? goalMl;
  final bool requiresClinician;

  /// USER, DEFAULT or NONE.
  final String? source;

  /// Today's glasses, newest first, without those being deleted.
  final List<WaterEntry> entries;

  /// True while a water operation waits for the server.
  final bool provisional;

  WaterGoalMode get mode {
    if (goalMl != null) {
      return WaterGoalMode.goal;
    }
    if (requiresClinician) {
      return WaterGoalMode.clinician;
    }
    return WaterGoalMode.none;
  }

  /// Share of the goal, 0 to 1; zero without a goal.
  double get progress {
    final goal = goalMl;
    if (goal == null || goal <= 0) {
      return 0;
    }
    return (totalMl / goal).clamp(0, 1).toDouble();
  }
}

WaterView waterView(DaySummary? summary, List<WaterEntry> rows) {
  var total = summary?.totalMl ?? 0;
  var provisional = false;
  for (final row in rows) {
    if (row.pending) {
      total += row.amountMl;
      provisional = true;
    } else if (row.deleting) {
      total -= row.amountMl;
      provisional = true;
    }
  }
  final shown = rows.where((WaterEntry row) => !row.deleting).toList()
    ..sort(
      (WaterEntry a, WaterEntry b) => b.consumedAt.compareTo(a.consumedAt),
    );
  return WaterView(
    totalMl: total < 0 ? 0 : total,
    goalMl: summary?.goalMl,
    requiresClinician: summary?.requiresClinician ?? false,
    source: summary?.waterSource,
    entries: shown,
    provisional: provisional,
  );
}

/// The quick buttons: amount and label key.
const waterQuickAmounts = <int>[150, 250, 500];

/// The custom sheet: slider range and chips.
const waterMinMl = 50;
const waterMaxMl = 1000;
const waterStepMl = 50;
const waterChips = <int>[100, 200, 330, 750];

/// Above this one glass gets the neutral «split it» tip.
const waterLargeMl = 500;

/// The goal sheet: what the doctor set.
const waterGoalMinMl = 500;
const waterGoalMaxMl = 5000;
const waterGoalStepMl = 50;

class WaterException implements Exception {
  const WaterException(this.code, {this.network = false});

  final String code;
  final bool network;

  @override
  String toString() => 'WaterException($code, network: $network)';
}
