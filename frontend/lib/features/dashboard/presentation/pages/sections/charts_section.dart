import 'package:flutter/material.dart';

import '../../../../../../core/widgets/app_card.dart';
import '../../../domain/entities/appliance_breakdown.dart';
import '../../../domain/entities/chart_point.dart';
import '../../../domain/entities/view_mode.dart';
import '../../widgets/appliance_pie_chart.dart';
import '../../widgets/consumption_line_chart.dart';
import '../../viewmodels/dashboard_state.dart';
import 'grid_calculator.dart';

class ChartsSection extends StatelessWidget {
  const ChartsSection({
    super.key,
    required this.dashboardState,
    required this.chartPoints,
    required this.breakdown,
    required this.grid,
    required this.spacing,
  });

  final DashboardUIState dashboardState;
  final List<ChartPoint> chartPoints;
  final List<ApplianceBreakdown> breakdown;
  final GridCalculator grid;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final data = dashboardState.data;
    final isMonthly = data?.chartMode == DashboardViewMode.monthly;
    final hasLineData = chartPoints.isNotEmpty;
    final hasPieData = breakdown.isNotEmpty;
    final showLineLoader = dashboardState.isLoading && !hasLineData;
    final showPieLoader = dashboardState.isLoading && !hasPieData;
    final showLineUpdating = dashboardState.isLoading && hasLineData;
    final showPieUpdating = dashboardState.isLoading && hasPieData;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: grid.widthForColumns(grid.chartColumns),
          child: AppCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMonthly
                        ? 'خەرجی کارەبا (12 مانگ)'
                        : 'خەرجی کارەبا (30 ڕۆژ)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (showLineLoader)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!hasLineData)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        height: 250,
                        child: Center(
                          child: Text(
                            'هێشتا داتای خەرجی بوونی نییە.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        if (showLineUpdating)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              height: 3,
                              child: LinearProgressIndicator(),
                            ),
                          ),
                        ConsumptionLineChart(
                          points: chartPoints,
                          isMonthly: isMonthly,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(
          width: grid.widthForColumns(grid.chartColumns),
          child: AppCard(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMonthly
                        ? 'دابەشکردنی ئامێرەکان (مانگانە)'
                        : 'دابەشکردنی ئامێرەکان (ڕۆژانە)',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (showPieLoader)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (!hasPieData)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: SizedBox(
                        height: 250,
                        child: Center(
                          child: Text(
                            'داتای دابەشکردنی ئامێر نییە.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        if (showPieUpdating)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              height: 3,
                              child: LinearProgressIndicator(),
                            ),
                          ),
                        AppliancePieChart(breakdown: breakdown),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
