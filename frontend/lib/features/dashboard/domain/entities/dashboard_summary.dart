class DashboardSummary {
  const DashboardSummary({
    required this.dailyKwh,
    required this.monthlyKwh,
    required this.estimatedCost,
    required this.dailyChangePct,
    required this.costChangePct,
    required this.outageMinutesToday,
    required this.outageTrackingActive,
    this.outageTrackingStartedAt,
  });

  final double dailyKwh;
  final double monthlyKwh;
  final double estimatedCost;
  final double dailyChangePct;
  final double costChangePct;
  final int outageMinutesToday;
  final bool outageTrackingActive;
  final DateTime? outageTrackingStartedAt;

  DashboardSummary copyWith({
    double? dailyKwh,
    double? monthlyKwh,
    double? estimatedCost,
    double? dailyChangePct,
    double? costChangePct,
    int? outageMinutesToday,
    bool? outageTrackingActive,
    DateTime? outageTrackingStartedAt,
  }) {
    return DashboardSummary(
      dailyKwh: dailyKwh ?? this.dailyKwh,
      monthlyKwh: monthlyKwh ?? this.monthlyKwh,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      dailyChangePct: dailyChangePct ?? this.dailyChangePct,
      costChangePct: costChangePct ?? this.costChangePct,
      outageMinutesToday: outageMinutesToday ?? this.outageMinutesToday,
      outageTrackingActive: outageTrackingActive ?? this.outageTrackingActive,
      outageTrackingStartedAt:
          outageTrackingStartedAt ?? this.outageTrackingStartedAt,
    );
  }
}
