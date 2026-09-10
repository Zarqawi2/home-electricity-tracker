import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
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
    final isMonthly =
        dashboardState.data?.chartMode == DashboardViewMode.monthly;
    final hasLineData = chartPoints.any((point) => point.y > 0);
    final hasPieData = breakdown.any((item) => item.dailyKwh > 0);

    if (!hasLineData && !hasPieData) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: dashboardState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Text(
                'بۆ بینینی خەمڵاندن، ئامێرێکی چالاک زیاد بکە.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                ),
              ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, size: 18, color: Color(0xFF0F172A)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'ئەم چارتانە خەمڵاندنن بە پێی ڕێکخستنی ئێستای ئامێرەکان؛ تۆماری ڕاستەقینەی کنتۆر نین.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (dashboardState.isLoading) ...[
          LinearProgressIndicator(
            color: AppColors.textPrimaryFor(context),
            backgroundColor: AppColors.borderFor(context),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            if (hasLineData)
              SizedBox(
                width: grid.widthForColumns(hasPieData ? grid.chartColumns : 1),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChartCardTitle(
                        title: isMonthly
                            ? 'خەمڵاندنی ١٢ مانگ'
                            : 'خەمڵاندنی ٣٠ ڕۆژ',
                        icon: Icons.show_chart_outlined,
                      ),
                      const SizedBox(height: 16),
                      ConsumptionLineChart(
                        points: chartPoints,
                        isMonthly: isMonthly,
                      ),
                    ],
                  ),
                ),
              ),
            if (hasPieData)
              SizedBox(
                width: grid.widthForColumns(
                  hasLineData ? grid.chartColumns : 1,
                ),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ChartCardTitle(
                        title: 'بەشی هەر ئامێر لە بەکارهێنان',
                        icon: Icons.pie_chart_outline,
                      ),
                      const SizedBox(height: 16),
                      AppliancePieChart(breakdown: breakdown),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ChartCardTitle extends StatelessWidget {
  const _ChartCardTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: const Color(0xFF0F172A)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
