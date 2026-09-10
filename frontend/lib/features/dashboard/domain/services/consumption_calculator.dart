import 'dart:math';

/// Estimated energy from the configured daily schedule, not a meter reading.
double scheduledDailyKwh({
  required double powerWatts,
  required double dailyUseHours,
  required bool isOn,
}) {
  if (!isOn || !powerWatts.isFinite || !dailyUseHours.isFinite) return 0;
  return max(0.0, powerWatts) / 1000 * dailyUseHours.clamp(0.0, 24.0);
}

int daysInCalendarMonth(DateTime date) =>
    DateTime(date.year, date.month + 1, 0).day;

/// Shares a single household bill by usage. Tariff tiers must be applied to the
/// household total first, never restarted for individual appliances.
///
/// Largest-remainder allocation keeps the shares equal to the rounded bill in
/// hundredths of IQD. Stable IDs break ties independently of display ordering.
Map<String, double> allocateBillByUsage({
  required Map<String, double> usageById,
  required double totalCostIqd,
}) {
  final result = {for (final id in usageById.keys) id: 0.0};
  final positive = usageById.entries
      .where((entry) => entry.value.isFinite && entry.value > 0)
      .toList();
  final totalUsage = positive.fold<double>(
    0,
    (sum, entry) => sum + entry.value,
  );
  if (positive.isEmpty || !totalCostIqd.isFinite || totalCostIqd <= 0) {
    return result;
  }

  final totalCents = (totalCostIqd * 100).round();
  final centsById = <String, int>{};
  final remainders = <({String id, double fraction})>[];
  var assignedCents = 0;
  for (final entry in positive) {
    final exactCents = totalCents * (entry.value / totalUsage);
    final cents = exactCents.floor();
    centsById[entry.key] = cents;
    assignedCents += cents;
    remainders.add((id: entry.key, fraction: exactCents - cents));
  }
  remainders.sort((a, b) {
    final byFraction = b.fraction.compareTo(a.fraction);
    return byFraction != 0 ? byFraction : a.id.compareTo(b.id);
  });
  for (var i = 0; i < totalCents - assignedCents; i++) {
    final id = remainders[i % remainders.length].id;
    centsById[id] = centsById[id]! + 1;
  }
  for (final entry in centsById.entries) {
    result[entry.key] = entry.value / 100;
  }
  return result;
}
