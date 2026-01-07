class DashboardSummary {
  const DashboardSummary({
    required this.dailyKwh,
    required this.monthlyKwh,
    required this.estimatedCost,
    required this.dailyChangePct,
    required this.costChangePct,
  });

  final double dailyKwh;
  final double monthlyKwh;
  final double estimatedCost;
  final double dailyChangePct;
  final double costChangePct;

  DashboardSummary copyWith({
    double? dailyKwh,
    double? monthlyKwh,
    double? estimatedCost,
    double? dailyChangePct,
    double? costChangePct,
  }) {
    return DashboardSummary(
      dailyKwh: dailyKwh ?? this.dailyKwh,
      monthlyKwh: monthlyKwh ?? this.monthlyKwh,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      dailyChangePct: dailyChangePct ?? this.dailyChangePct,
      costChangePct: costChangePct ?? this.costChangePct,
    );
  }
}
