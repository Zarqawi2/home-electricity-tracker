import 'dashboard_summary.dart';
import 'chart_point.dart';
import 'appliance_breakdown.dart';
import 'view_mode.dart';

class DashboardData {
  const DashboardData({
    required this.summary,
    required this.chartPoints,
    required this.breakdown,
    required this.applianceMonthlyCosts,
    required this.chartMode,
    required this.tips,
  });

  final DashboardSummary summary;
  final List<ChartPoint> chartPoints;
  final List<ApplianceBreakdown> breakdown;
  final Map<String, double> applianceMonthlyCosts;
  final DashboardViewMode chartMode;
  final List<String> tips;
}
