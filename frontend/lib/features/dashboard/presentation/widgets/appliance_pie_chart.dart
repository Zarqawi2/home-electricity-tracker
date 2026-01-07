import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/appliance_breakdown.dart';

class AppliancePieChart extends StatelessWidget {
  const AppliancePieChart({super.key, required this.breakdown});

  final List<ApplianceBreakdown> breakdown;

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('هیچ داتای ئامێر نییە')),
      );
    }

    final sections = breakdown
        .map(
          (slice) => PieChartSectionData(
            color: slice.color,
            value: slice.percentage,
            title: '',
            radius: 70,
          ),
        )
        .toList();

    return SizedBox(
      height: 250,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(width:20),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final slice in breakdown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: slice.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${slice.name}: ${slice.percentage.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
