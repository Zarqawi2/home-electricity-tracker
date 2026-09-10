import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/appliance_breakdown.dart';
import '../utils/dashboard_responsive.dart';

class AppliancePieChart extends StatefulWidget {
  const AppliancePieChart({super.key, required this.breakdown});

  final List<ApplianceBreakdown> breakdown;

  @override
  State<AppliancePieChart> createState() => _AppliancePieChartState();
}

class _AppliancePieChartState extends State<AppliancePieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final sectionLabelSize = DashboardResponsive.sp(
      context,
      11,
      min: 9,
      max: 12,
    );
    if (widget.breakdown.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(child: Text('داتای شیکردنەوەی ئامێرەکان نییە')),
      );
    }

    final slices = [...widget.breakdown]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final totalPercent = slices.fold<double>(
      0,
      (sum, item) => sum + item.percentage,
    );

    final chart = SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < slices.length; i++)
                  PieChartSectionData(
                    color: _neutralSliceColor(
                      i,
                      slices.length,
                      selected: i == _touchedIndex,
                    ),
                    value: slices[i].percentage,
                    title: i == _touchedIndex
                        ? _formatPercent(slices[i].percentage)
                        : '',
                    titleStyle: TextStyle(
                      fontSize: sectionLabelSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryFor(context),
                    ),
                    radius: i == _touchedIndex ? 78 : 70,
                  ),
              ],
              sectionsSpace: 2.5,
              centerSpaceRadius: 34,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  final touched = response?.touchedSection?.touchedSectionIndex;
                  if (!event.isInterestedForInteractions || touched == null) {
                    if (_touchedIndex != -1) {
                      setState(() => _touchedIndex = -1);
                    }
                    return;
                  }
                  if (_touchedIndex != touched) {
                    setState(() => _touchedIndex = touched);
                  }
                },
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatPercent(totalPercent),
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '${slices.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final legend = _PieLegend(
          slices: slices,
          touchedIndex: _touchedIndex,
          scrollable: true,
          onTap: (index) {
            setState(() => _touchedIndex = index == _touchedIndex ? -1 : index);
          },
        );

        if (compact) {
          return SizedBox(
            height: 380,
            child: Column(
              children: [
                chart,
                const SizedBox(height: 10),
                Expanded(child: legend),
              ],
            ),
          );
        }

        return SizedBox(
          height: 250,
          child: Row(
            children: [
              Expanded(flex: 3, child: chart),
              const SizedBox(width: 14),
              Expanded(flex: 4, child: legend),
            ],
          ),
        );
      },
    );
  }

  String _formatPercent(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) {
      return '${rounded.toStringAsFixed(0)}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}

class _PieLegend extends StatelessWidget {
  const _PieLegend({
    required this.slices,
    required this.touchedIndex,
    required this.scrollable,
    required this.onTap,
  });

  final List<ApplianceBreakdown> slices;
  final int touchedIndex;
  final bool scrollable;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final nameSize = DashboardResponsive.sp(context, 11, min: 9.5, max: 12);
    final detailSize = DashboardResponsive.sp(context, 10, min: 9, max: 11);
    return ListView.separated(
      shrinkWrap: !scrollable,
      physics: scrollable
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      itemCount: slices.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final slice = slices[index];
        final selected = index == touchedIndex;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onTap(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: selected ? const Color(0xFFEFF6FF) : Colors.white,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _neutralSliceColor(
                        index,
                        slices.length,
                        selected: selected,
                      ),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slice.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: nameSize,
                            color: AppColors.textPrimaryFor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${_formatPercent(slice.percentage)} - ${slice.dailyKwh.toStringAsFixed(2)} kWh',
                          style: TextStyle(
                            fontSize: detailSize,
                            color: AppColors.textSecondaryFor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: const Color(0xFF0F172A),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static String _formatPercent(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) {
      return '${rounded.toStringAsFixed(0)}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}

Color _neutralSliceColor(int index, int total, {required bool selected}) {
  if (selected) return const Color(0xFF2563EB);
  if (total <= 1) return const Color(0xFF64748B);
  return Color.lerp(
    const Color(0xFFCBD5E1),
    const Color(0xFF334155),
    index / (total - 1),
  )!;
}
