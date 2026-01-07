import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/dashboard_summary.dart';
import '../../widgets/metric_card.dart';
import 'grid_calculator.dart';

class MetricsSection extends StatelessWidget {
  const MetricsSection({
    super.key,
    required this.grid,
    required this.summary,
    required this.dailyChangeText,
    required this.costChangeText,
    required this.spacing,
  });

  final GridCalculator grid;
  final DashboardSummary? summary;
  final String dailyChangeText;
  final String costChangeText;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        SizedBox(
          width: grid.widthForColumns(grid.summaryColumns),
          child: MetricCard(
            title: 'خەرجی ڕۆژانە',
            value: '${summary?.dailyKwh.toStringAsFixed(2) ?? '0.00'} kWh',
            subtitle: dailyChangeText,
            icon: Icons.bolt,
            badgeColor: const Color(0xFFFFF8E1),
            iconColor: Colors.orange,
            subtitleColor: AppColors.negative,
          ),
        ),
        SizedBox(
          width: grid.widthForColumns(grid.summaryColumns),
          child: MetricCard(
            title: 'خەرجی مانگانە',
            value: '${summary?.monthlyKwh.toStringAsFixed(0) ?? '0'} kWh',
            subtitle: 'kWh',
            icon: Icons.auto_graph,
            badgeColor: const Color(0xFFEFF6FF),
            iconColor: AppColors.primary,
            subtitleColor: AppColors.textSecondary,
          ),
        ),
        SizedBox(
          width: grid.widthForColumns(grid.summaryColumns),
          child: MetricCard(
            title: 'تێچوی مانگانە',
            value:
                '${summary?.estimatedCost.toStringAsFixed(0) ?? '0'} مانگ/دینار',
            subtitle: costChangeText,
            icon: Icons.attach_money,
            badgeColor: const Color(0xFFE8F5E9),
            iconColor: AppColors.positive,
            subtitleColor: AppColors.positive,
          ),
        ),
      ],
    );
  }
}
