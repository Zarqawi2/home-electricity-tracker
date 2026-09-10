import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chart_point.dart';
import '../utils/dashboard_responsive.dart';

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
    final padding = max((maxVal - minVal) * 0.14, 0.2);
    final maxY = maxVal + padding;
    final minY = max(0.0, minVal - padding);
    final range = (maxY - minY).clamp(0.5, double.infinity);
    final yInterval = _niceInterval(range.toDouble());
    final axisTextColor = AppColors.textPrimaryFor(context);
    final axisTickSize = DashboardResponsive.sp(context, 10, min: 8.5, max: 11);
    final axisLabelSize = DashboardResponsive.sp(
      context,
      11,
      min: 9.5,
      max: 12,
    );
    final screenWidth = MediaQuery.of(context).size.width;
    final chartWidth = max(
      screenWidth * 0.95,
      points.length * (isMonthly ? 32.0 : 24.0),
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
                    getTooltipColor: (_) => const Color(0xFF0F172A),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final point = _pointForX(spot.x);
                        final label = point == null
                            ? ''
                            : isMonthly
                            ? _formatMonthLabel(point.label)
                            : _formatDayLabel(point.label);
                        final valueLabel =
                            '${spot.y.toStringAsFixed(isMonthly ? 1 : 2)} kWh';
                        final text = label.isEmpty
                            ? valueLabel
                            : '$label\n$valueLabel';
                        return LineTooltipItem(
                          text,
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderFor(context),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.fromBorderSide(
                    BorderSide(color: AppColors.borderFor(context)),
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
                      interval: 1,
                      getTitlesWidget: (value, _) => isMonthly
                          ? Padding(
                              padding: bottomLabelPadding,
                              child: _monthTitle(
                                value,
                                axisTextColor,
                                axisLabelSize,
                              ),
                            )
                          : Padding(
                              padding: bottomLabelPadding,
                              child: _dayTitle(
                                value,
                                axisTextColor,
                                axisLabelSize,
                              ),
                            ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: yInterval,
                      getTitlesWidget: (value, _) {
                        final isMinTick =
                            (value - minY).abs() < yInterval * 0.4;
                        if (isMinTick) return const SizedBox.shrink();
                        return Padding(
                          padding: leftLabelPadding,
                          child: Text(
                            _formatAxisValue(value),
                            style: TextStyle(
                              fontSize: axisTickSize,
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
                    color: const Color(0xFF334155),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      checkToShowDot: (spot, _) => spot.y == maxVal,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 4.5,
                        color: const Color(0xFF0F172A),
                        strokeColor: AppColors.surfaceFor(context),
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFFF1F5F9),
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

  ChartPoint? _pointForX(double x) {
    final index = x.round() - 1;
    if (index < 0 || index >= points.length) {
      return null;
    }
    return points[index];
  }

  Widget _dayTitle(double value, Color axisColor, double fontSize) {
    final index = value.round() - 1;
    if (index < 0 || index >= points.length) {
      return const SizedBox.shrink();
    }
    if (index % 5 != 0 && index != 0 && index != points.length - 1) {
      return const SizedBox.shrink();
    }

    return Text(
      _formatDayLabel(points[index].label),
      style: TextStyle(fontSize: fontSize, color: axisColor),
    );
  }

  Widget _monthTitle(double value, Color axisColor, double fontSize) {
    final index = value.round() - 1;
    if (index < 0 || index >= points.length) {
      return const SizedBox.shrink();
    }
    if (points.length > 8 && index.isOdd && index != points.length - 1) {
      return const SizedBox.shrink();
    }

    return Text(
      _formatMonthLabel(points[index].label),
      style: TextStyle(fontSize: fontSize, color: axisColor),
    );
  }

  double _niceInterval(double range) {
    final rough = max(range / 5, 0.1);
    final magnitude = pow(10, (log(rough) / ln10).floor()).toDouble();
    final residual = rough / magnitude;

    double step;
    if (residual <= 1) {
      step = 1;
    } else if (residual <= 2) {
      step = 2;
    } else if (residual <= 5) {
      step = 5;
    } else {
      step = 10;
    }
    return step * magnitude;
  }

  String _formatAxisValue(double value) {
    if (value >= 1000) {
      final compact = value / 1000;
      final decimals = compact >= 10 ? 0 : 1;
      return '${compact.toStringAsFixed(decimals)}k';
    }
    if (value >= 100) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatDayLabel(String raw) {
    final date = DateTime.tryParse(raw);
    if (date != null) {
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');
      return '$month/$day';
    }
    if (raw.length >= 10) {
      return raw.substring(5, 10);
    }
    return raw;
  }

  String _formatMonthLabel(String raw) {
    if (raw.length >= 7) {
      final month = raw.substring(5, 7);
      final year = raw.substring(2, 4);
      return '$month/$year';
    }
    return raw;
  }
}
