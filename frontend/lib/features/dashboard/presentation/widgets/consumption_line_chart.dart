import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chart_point.dart';

class ConsumptionLineChart extends StatelessWidget {
  const ConsumptionLineChart({
    super.key,
    required this.points,
    required this.isMonthly,
  });

  final List<ChartPoint> points;
  final bool isMonthly;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 300);
    }
    final spots = points.map((point) => FlSpot(point.x, point.y)).toList();
    final maxVal = points.map((p) => p.y).reduce(max);
    final minVal = points.map((p) => p.y).reduce(min);
    final padding = (maxVal * 0.2).clamp(0.2, 10.0);
    final maxY = maxVal + padding;
    final minY = max(0.0, minVal - padding);
    final range = (maxY - minY).clamp(0.5, double.infinity);
    final yInterval = isMonthly
        ? (range / 5).clamp(2.0, 50.0)
        : (range / 5).clamp(0.2, 5.0);
    const axisTextColor = AppColors.textPrimary;
    final screenWidth = MediaQuery.of(context).size.width;
    final chartWidth = max(
      screenWidth * 0.95,
      points.length * (isMonthly ? 28.0 : 20.0),
    );
    const bottomLabelPadding = EdgeInsets.only(top: 10);
    const leftLabelPadding = EdgeInsets.only(top: 8, right: 6);

    return SizedBox(
      height: 300,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Center(
          child: SizedBox(
            width: chartWidth,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots
                          .map(
                            (spot) => LineTooltipItem(
                              spot.y.toStringAsFixed(isMonthly ? 1 : 2),
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                          .toList();
                    },
                  ),
                ),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.cardBorder, strokeWidth: 1),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.cardBorder),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: isMonthly ? 1 : 5,
                      getTitlesWidget: (value, meta) => isMonthly
                          ? Padding(
                              padding: bottomLabelPadding,
                              child: _monthTitle(value, axisTextColor),
                            )
                          : Padding(
                              padding: bottomLabelPadding,
                              child:
                                  _dayTitle(value, points.length, axisTextColor),
                            ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: yInterval,
                      getTitlesWidget: (value, meta) {
                        // Hide the bottom-most tick to keep it from colliding with X labels.
                        final isMinTick = (value - minY).abs() < yInterval * 0.4;
                        if (isMinTick) return const SizedBox.shrink();
                        return Padding(
                          padding: leftLabelPadding,
                          child: Text(
                            value.toStringAsFixed(isMonthly ? 0 : 1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: axisTextColor,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayTitle(double value, int total, Color axisColor) {
    if (value < 1 || value > total) {
      return const SizedBox.shrink();
    }
    if (value % 5 != 0 && value != 1 && value != total) {
      return const SizedBox.shrink();
    }
    return Text(
      'ڕۆژ ${value.toInt()}',
      style: TextStyle(
        fontSize: 11,
        color: axisColor,
      ),
    );
  }

  Widget _monthTitle(double value, Color axisColor) {
    return Text(
      'مانگ ${value.toInt()}',
      style: TextStyle(fontSize: 11, color: axisColor),
    );
  }
}
