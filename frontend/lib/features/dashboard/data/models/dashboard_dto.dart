import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/appliance.dart';
import '../../domain/entities/appliance_breakdown.dart';
import '../../domain/entities/chart_point.dart';
import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/view_mode.dart';

class DashboardDto {
  DashboardDto({
    required this.summary,
    required this.lineChart,
    required this.pieChart,
    required this.appliances,
    required this.tips,
  });

  final SummaryDto summary;
  final LineChartDto lineChart;
  final List<PieSliceDto> pieChart;
  final List<ApplianceDto> appliances;
  final List<String> tips;

  factory DashboardDto.fromJson(Map<String, dynamic> json) {
    return DashboardDto(
      summary: SummaryDto.fromJson(json['summary'] as Map<String, dynamic>),
      lineChart: LineChartDto.fromJson(
        json['line_chart'] as Map<String, dynamic>,
      ),
      pieChart: (json['pie_chart'] as List<dynamic>? ?? [])
          .map((e) => PieSliceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      appliances: (json['appliances'] as List<dynamic>? ?? [])
          .map((e) => ApplianceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: (json['tips'] as List<dynamic>? ?? []).cast<String>(),
    );
  }

  DashboardData toDomain() {
    final chartPoints = <ChartPoint>[];
    for (var i = 0; i < lineChart.points.length; i++) {
      chartPoints.add(
        ChartPoint(
          x: (i + 1).toDouble(),
          y: lineChart.points[i].y,
          label: lineChart.points[i].x,
        ),
      );
    }

    final breakdown = pieChart
        .map(
          (slice) => ApplianceBreakdown(
            name: slice.name,
            percentage: slice.pct,
            dailyKwh: slice.dailyKwh,
            color: _colorForName(slice.name),
          ),
        )
        .toList();

    final applianceCosts = <String, double>{
      for (final appliance in appliances)
        if (appliance.monthlyCostIqd != null)
          appliance.id: appliance.monthlyCostIqd!.toDouble(),
    };

    return DashboardData(
      summary: summary.toDomain(),
      chartPoints: chartPoints,
      breakdown: breakdown,
      applianceMonthlyCosts: applianceCosts,
      chartMode: lineChart.mode,
      tips: tips,
    );
  }
}

class SummaryDto {
  SummaryDto({
    required this.dailyKwh,
    required this.monthlyEstimateKwh,
    required this.monthlyCostIqd,
    required this.dailyChangePct,
    required this.costChangePct,
    required this.outageMinutesToday,
    required this.outageTrackingActive,
    this.outageTrackingStartedAt,
  });

  final double dailyKwh;
  final double monthlyEstimateKwh;
  final double monthlyCostIqd;
  final double dailyChangePct;
  final double costChangePct;
  final int outageMinutesToday;
  final bool outageTrackingActive;
  final DateTime? outageTrackingStartedAt;

  factory SummaryDto.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) =>
        value is int ? value.toDouble() : (value as num?)?.toDouble() ?? 0;
    DateTime? parseDateTime(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) {
        return null;
      }
      return DateTime.tryParse(raw)?.toLocal();
    }

    return SummaryDto(
      dailyKwh: parseNum(json['daily_kwh']),
      monthlyEstimateKwh: parseNum(json['monthly_estimate_kwh']),
      monthlyCostIqd: parseNum(json['monthly_cost_iqd']),
      dailyChangePct: parseNum(json['daily_change_pct']),
      costChangePct: parseNum(json['cost_change_pct']),
      outageMinutesToday: (json['outage_minutes_today'] as num?)?.toInt() ?? 0,
      outageTrackingActive: json['outage_tracking_active'] == true,
      outageTrackingStartedAt: parseDateTime(
        json['outage_tracking_started_at'],
      ),
    );
  }

  DashboardSummary toDomain() {
    return DashboardSummary(
      dailyKwh: dailyKwh,
      monthlyKwh: monthlyEstimateKwh,
      estimatedCost: monthlyCostIqd,
      dailyChangePct: dailyChangePct,
      costChangePct: costChangePct,
      outageMinutesToday: outageMinutesToday,
      outageTrackingActive: outageTrackingActive,
      outageTrackingStartedAt: outageTrackingStartedAt,
    );
  }
}

class LineChartDto {
  LineChartDto({required this.mode, required this.points});

  final DashboardViewMode mode;
  final List<ChartPointDto> points;

  factory LineChartDto.fromJson(Map<String, dynamic> json) {
    final modeStr = (json['mode'] as String?) ?? 'daily';
    return LineChartDto(
      mode: modeStr == 'monthly'
          ? DashboardViewMode.monthly
          : DashboardViewMode.daily,
      points: (json['points'] as List<dynamic>? ?? [])
          .map((e) => ChartPointDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ChartPointDto {
  ChartPointDto({required this.x, required this.y});

  final String x;
  final double y;

  factory ChartPointDto.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) =>
        value is int ? value.toDouble() : (value as num?)?.toDouble() ?? 0;

    return ChartPointDto(
      x: json['x']?.toString() ?? '',
      y: parseNum(json['y']),
    );
  }
}

class PieSliceDto {
  PieSliceDto({
    required this.applianceId,
    required this.name,
    required this.pct,
    required this.dailyKwh,
  });

  final String applianceId;
  final String name;
  final double pct;
  final double dailyKwh;

  factory PieSliceDto.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) =>
        value is int ? value.toDouble() : (value as num?)?.toDouble() ?? 0;

    return PieSliceDto(
      applianceId: json['appliance_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      pct: parseNum(json['pct']),
      dailyKwh: parseNum(json['daily_kwh']),
    );
  }
}

class ApplianceDto {
  ApplianceDto({
    required this.id,
    required this.name,
    required this.category,
    required this.powerWatts,
    required this.dailyUseHours,
    required this.isOn,
    this.monthlyCostIqd,
  });

  final String id;
  final String name;
  final String category;
  final int powerWatts;
  final double dailyUseHours;
  final bool isOn;
  final double? monthlyCostIqd;

  factory ApplianceDto.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic value) =>
        value is int ? value.toDouble() : (value as num?)?.toDouble() ?? 0;

    return ApplianceDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      powerWatts: (json['power_watts'] as num?)?.toInt() ?? 0,
      dailyUseHours: parseNum(json['daily_use_hours']),
      isOn: json['is_on'] == true || json['is_on'] == 1,
      monthlyCostIqd: json['monthly_cost_iqd'] != null
          ? parseNum(json['monthly_cost_iqd'])
          : null,
    );
  }

  Appliance toDomain() {
    return Appliance(
      id: id,
      name: name,
      category: category,
      powerW: powerWatts.toDouble(),
      dailyUseHours: dailyUseHours,
      isOn: isOn,
    );
  }
}

Color _colorForName(String name) {
  const palette = <Color>[
    AppColors.primary,
    AppColors.warning,
    AppColors.positive,
    AppColors.chartLine2,
    AppColors.info,
    AppColors.negative,
  ];
  final hash = name.runes.fold<int>(0, (sum, rune) => sum + rune);
  return palette[hash % palette.length];
}
