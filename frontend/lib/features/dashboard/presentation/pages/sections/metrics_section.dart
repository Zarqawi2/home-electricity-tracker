import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../../core/formatters/currency_formatter.dart';
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
    final outageMinutesToday = summary?.outageMinutesToday ?? 0;
    final isOutageTrackingActive = summary?.outageTrackingActive ?? false;
    final outageTrackingStartedAt = summary?.outageTrackingStartedAt;
    final liveOutageMinutes =
        isOutageTrackingActive && outageTrackingStartedAt != null
        ? math.max(
            0,
            DateTime.now().difference(outageTrackingStartedAt).inMinutes,
          )
        : 0;
    final outageSubtitle = isOutageTrackingActive
        ? 'تۆمارکردن چالاکە. کۆی ئەمڕۆ: $outageMinutesToday خولەک'
        : 'تۆمارکردن ناچالاکە. کۆی ئەمڕۆ: $outageMinutesToday خولەک';

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
            icon: Icons.electric_meter_outlined,
          ),
        ),
        SizedBox(
          width: grid.widthForColumns(grid.summaryColumns),
          child: MetricCard(
            title: 'خەرجی مانگانە',
            value: '${summary?.monthlyKwh.toStringAsFixed(2) ?? '0.00'} kWh',
            subtitle: 'kWh',
            icon: Icons.show_chart_outlined,
          ),
        ),
        SizedBox(
          width: grid.widthForColumns(grid.summaryColumns),
          child: MetricCard(
            title: 'تێچووی مانگانە',
            value: formatIqd(summary?.estimatedCost ?? 0),
            subtitle: costChangeText,
            icon: Icons.payments_outlined,
          ),
        ),
        SizedBox(
          width: grid.widthForColumns(grid.summaryColumns),
          child: MetricCard(
            title: 'قەطعبوونی ئێستا',
            value: '$liveOutageMinutes خولەک',
            subtitle: outageSubtitle,
            icon: Icons.power_off_outlined,
          ),
        ),
      ],
    );
  }
}
