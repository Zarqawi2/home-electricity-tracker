import 'dart:math';

import '../../../../core/settings/electricity_tariff.dart';
import '../../../../core/settings/electricity_tariff_storage.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/services/consumption_calculator.dart';
import '../models/dashboard_dto.dart';
import 'local_appliance_store.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._store);

  final LocalApplianceStore _store;
  static const _minutesPerDay = 1440;

  Future<DashboardDto> fetchDashboard({
    required DateTime date,
    required DashboardViewMode mode,
  }) async {
    final targetDate = DateTime(date.year, date.month, date.day);
    final tariffProfile = await readSavedElectricityTariffProfile();
    final monthlyStartDate = DateTime(
      targetDate.year,
      targetDate.month - 11,
      1,
    );
    final appliances = await _store.listAppliances();
    final activeAppliances = appliances
        .where((item) => item['is_on'] == true)
        .toList();
    final persistedOutageByDate = await _store.getOutageMinutesInRange(
      from: monthlyStartDate,
      to: targetDate,
    );
    final trackingStart = await _store.getOutageTrackingStart();
    final outageByDate = _mergeLiveOutageMinutes(
      base: persistedOutageByDate,
      trackingStart: trackingStart,
      from: monthlyStartDate,
      to: targetDate,
      now: DateTime.now(),
    );
    final isOutageTrackingActive = trackingStart != null;

    final baseDailyKwh = activeAppliances.fold<double>(0, (sum, appliance) {
      final power = (appliance['power_watts'] as num?)?.toDouble() ?? 0;
      final dailyHours =
          (appliance['daily_use_hours'] as num?)?.toDouble() ?? 0;
      return sum +
          scheduledDailyKwh(
            powerWatts: power,
            dailyUseHours: dailyHours,
            isOn: true,
          );
    });

    final dailySeries = _buildDailySeries(
      date: targetDate,
      baseDaily: baseDailyKwh,
      outagesByDate: outageByDate,
    );
    final dailyPoints = dailySeries.points;
    final dailyToday = dailySeries.todayKwh;
    final monthDays = daysInCalendarMonth(targetDate);
    // Project this month's configured schedule using its recorded outage rate.
    // Neither these projections nor the chart points are measured history.
    final monthlyUptimeFactor = _monthlyUptimeFactor(
      targetDate,
      outageByDate,
      observedDays: targetDate.day,
    );
    final monthlyEstimateKwh = baseDailyKwh * monthDays * monthlyUptimeFactor;
    final todayOutageMinutes = outageByDate[_formatDate(targetDate)] ?? 0;

    final monthlyChartPoints = _buildMonthlyPoints(
      targetDate,
      baseDailyKwh,
      outageByDate,
    );
    final monthlyCost = _roundTo(
      _calculateTariff(monthlyEstimateKwh, tariffProfile),
      2,
    );
    final lineChart = mode == DashboardViewMode.monthly
        ? {'mode': 'monthly', 'points': monthlyChartPoints}
        : {'mode': 'daily', 'points': dailyPoints};

    final monthlyUsageById = <String, double>{};
    for (final appliance in appliances) {
      final power = (appliance['power_watts'] as num?)?.toDouble() ?? 0;
      final dailyHours =
          (appliance['daily_use_hours'] as num?)?.toDouble() ?? 0;
      monthlyUsageById[appliance['id'] as String] =
          scheduledDailyKwh(
            powerWatts: power,
            dailyUseHours: dailyHours,
            isOn: appliance['is_on'] == true,
          ) *
          monthDays *
          monthlyUptimeFactor;
    }
    final allocatedCosts = allocateBillByUsage(
      usageById: monthlyUsageById,
      totalCostIqd: monthlyCost,
    );
    final appliancePayload = appliances.map((appliance) {
      final id = appliance['id'] as String;
      return {
        ...appliance,
        'monthly_kwh': monthlyUsageById[id] ?? 0,
        'monthly_cost_iqd': allocatedCosts[id] ?? 0,
      };
    }).toList();

    final pieChart = _buildPieChart(activeAppliances, baseDailyKwh);

    final prevDaily = dailyPoints.length > 1
        ? (dailyPoints[dailyPoints.length - 2]['y'] as num).toDouble()
        : dailyToday;
    final dailyChange = prevDaily > 0
        ? ((dailyToday - prevDaily) / prevDaily) * 100
        : 0.0;

    final lastMonthly = monthlyChartPoints.isNotEmpty
        ? (monthlyChartPoints.last['y'] as num).toDouble()
        : monthlyEstimateKwh;
    final prevMonthly = monthlyChartPoints.length > 1
        ? (monthlyChartPoints[monthlyChartPoints.length - 2]['y'] as num)
              .toDouble()
        : lastMonthly;
    final lastMonthlyCost = _calculateTariff(lastMonthly, tariffProfile);
    final prevMonthlyCost = _calculateTariff(prevMonthly, tariffProfile);
    final costChange = prevMonthlyCost > 0
        ? ((lastMonthlyCost - prevMonthlyCost) / prevMonthlyCost) * 100
        : 0.0;

    final payload = <String, dynamic>{
      'summary': {
        'daily_kwh': _roundTo(dailyToday, 2),
        'monthly_estimate_kwh': _roundTo(monthlyEstimateKwh, 2),
        'monthly_cost_iqd': monthlyCost,
        'daily_change_pct': _roundTo(dailyChange, 1),
        'cost_change_pct': _roundTo(costChange, 1),
        'outage_minutes_today': todayOutageMinutes,
        'outage_tracking_active': isOutageTrackingActive,
        'outage_tracking_started_at': trackingStart?.toIso8601String(),
      },
      'line_chart': lineChart,
      'pie_chart': pieChart,
      'appliances': appliancePayload,
      'tips': _tips(),
    };

    return DashboardDto.fromJson(payload);
  }

  Future<void> setTodayOutageMinutes(int minutes) async {
    final tariffProfile = await readSavedElectricityTariffProfile();
    return _store.setOutageMinutesForDate(
      date: DateTime.now(),
      outageMinutes: minutes,
      logChange: true,
      source: 'manual',
      tariffProfileId: tariffProfile.id,
    );
  }

  Future<void> startOutageTracking() {
    return _store.startOutageTracking();
  }

  Future<int> stopOutageTracking() async {
    final tariffProfile = await readSavedElectricityTariffProfile();
    return _store.stopOutageTracking(tariffProfileId: tariffProfile.id);
  }

  _DailySeries _buildDailySeries({
    required DateTime date,
    required double baseDaily,
    required Map<String, int> outagesByDate,
  }) {
    final startDate = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(const Duration(days: 29));
    final points = <Map<String, dynamic>>[];

    for (var i = 0; i < 30; i++) {
      final current = startDate.add(Duration(days: i));
      final dateKey = _formatDate(current);
      final outageMinutes = outagesByDate[dateKey] ?? 0;
      final uptimeFactor = _uptimeFactor(outageMinutes);
      final value = max(0.0, baseDaily * uptimeFactor);
      points.add({'x': dateKey, 'y': _roundTo(value, 2)});
    }

    final todayKwh = (points.last['y'] as num?)?.toDouble() ?? 0.0;
    return _DailySeries(points: points, todayKwh: todayKwh);
  }

  List<Map<String, dynamic>> _buildMonthlyPoints(
    DateTime date,
    double baseDaily,
    Map<String, int> outagesByDate,
  ) {
    final anchor = DateTime(date.year, date.month, 1);
    final startMonth = DateTime(anchor.year, anchor.month - 11, 1);
    final points = <Map<String, dynamic>>[];

    for (var i = 0; i < 12; i++) {
      final month = DateTime(startMonth.year, startMonth.month + i, 1);
      final isCurrentMonth =
          month.year == date.year && month.month == date.month;
      final outageFactor = _monthlyUptimeFactor(
        month,
        outagesByDate,
        observedDays: isCurrentMonth ? date.day : null,
      );
      final value = max(
        0.0,
        baseDaily * daysInCalendarMonth(month) * outageFactor,
      );
      points.add({'x': _formatMonth(month), 'y': _roundTo(value, 2)});
    }

    return points;
  }

  List<Map<String, dynamic>> _buildPieChart(
    List<Map<String, dynamic>> activeAppliances,
    double totalDailyKwh,
  ) {
    if (activeAppliances.isEmpty || totalDailyKwh <= 0) {
      return <Map<String, dynamic>>[];
    }

    final raw = activeAppliances
        .map((appliance) {
          final power = (appliance['power_watts'] as num?)?.toDouble() ?? 0;
          final dailyHours =
              (appliance['daily_use_hours'] as num?)?.toDouble() ?? 0;
          final dailyKwh = scheduledDailyKwh(
            powerWatts: power,
            dailyUseHours: dailyHours,
            isOn: true,
          );
          return {
            'appliance_id': appliance['id'],
            'name': appliance['name'],
            'daily_kwh': _roundTo(dailyKwh, 3),
            'raw_pct': (dailyKwh / totalDailyKwh) * 100,
          };
        })
        .where((item) => (item['daily_kwh'] as double) > 0)
        .toList(growable: false);
    if (raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final rounded = raw
        .map((item) => _roundTo(item['raw_pct'] as double, 1))
        .toList(growable: true);
    final roundedSum = rounded.fold<double>(0, (sum, value) => sum + value);
    final correction = _roundTo(100 - roundedSum, 1);
    if (correction != 0 && rounded.isNotEmpty) {
      var targetIndex = 0;
      var maxRaw = -1.0;
      for (var i = 0; i < raw.length; i++) {
        final currentRaw = raw[i]['raw_pct'] as double;
        if (currentRaw > maxRaw) {
          maxRaw = currentRaw;
          targetIndex = i;
        }
      }
      rounded[targetIndex] = _roundTo(
        (rounded[targetIndex] + correction).clamp(0, 100).toDouble(),
        1,
      );
      final adjustedSum = rounded.fold<double>(0, (sum, value) => sum + value);
      final drift = _roundTo(100 - adjustedSum, 1);
      if (drift != 0) {
        rounded[targetIndex] = _roundTo(
          (rounded[targetIndex] + drift).clamp(0, 100).toDouble(),
          1,
        );
      }
    }

    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      result.add({
        'appliance_id': raw[i]['appliance_id'],
        'name': raw[i]['name'],
        'daily_kwh': raw[i]['daily_kwh'],
        'pct': rounded[i],
      });
    }
    result.sort((a, b) => (b['pct'] as double).compareTo(a['pct'] as double));
    return result;
  }

  double _calculateTariff(double kwh, ElectricityTariffProfile profile) {
    return calculateElectricityCostIqd(kwh: kwh, profile: profile);
  }

  double _roundTo(double value, int digits) {
    final multiplier = pow(10, digits).toDouble();
    return (value * multiplier).round() / multiplier;
  }

  double _uptimeFactor(int outageMinutes) {
    final normalized = outageMinutes.clamp(0, _minutesPerDay);
    return (((_minutesPerDay - normalized) / _minutesPerDay).clamp(
      0.0,
      1.0,
    )).toDouble();
  }

  double _monthlyUptimeFactor(
    DateTime month,
    Map<String, int> outagesByDate, {
    int? observedDays,
  }) {
    final dayCount = (observedDays ?? daysInCalendarMonth(month)).clamp(
      1,
      daysInCalendarMonth(month),
    );
    var totalUptime = 0.0;
    for (var day = 1; day <= dayCount; day++) {
      final key = _formatDate(DateTime(month.year, month.month, day));
      totalUptime += _uptimeFactor(outagesByDate[key] ?? 0);
    }
    return totalUptime / dayCount;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _formatMonth(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$year-$month';
  }

  Map<String, int> _mergeLiveOutageMinutes({
    required Map<String, int> base,
    required DateTime? trackingStart,
    required DateTime from,
    required DateTime to,
    required DateTime now,
  }) {
    if (trackingStart == null || !now.isAfter(trackingStart)) {
      return base;
    }

    final rangeStart = DateTime(from.year, from.month, from.day);
    final rangeEndExclusive = DateTime(to.year, to.month, to.day + 1);
    final effectiveStart = trackingStart.isBefore(rangeStart)
        ? rangeStart
        : trackingStart;
    final effectiveEnd = now.isAfter(rangeEndExclusive)
        ? rangeEndExclusive
        : now;
    if (!effectiveEnd.isAfter(effectiveStart)) {
      return base;
    }

    final merged = Map<String, int>.from(base);
    final additions = _splitRangeAcrossDates(
      start: effectiveStart,
      end: effectiveEnd,
    );
    for (final entry in additions.entries) {
      final current = merged[entry.key] ?? 0;
      merged[entry.key] = (current + entry.value)
          .clamp(0, _minutesPerDay)
          .toInt();
    }

    return merged;
  }

  Map<String, int> _splitRangeAcrossDates({
    required DateTime start,
    required DateTime end,
  }) {
    final result = <String, int>{};
    if (!end.isAfter(start)) {
      return result;
    }

    var cursor = start;
    while (cursor.isBefore(end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = end.isBefore(nextMidnight) ? end : nextMidnight;
      final minutes = segmentEnd.difference(cursor).inMinutes;
      if (minutes > 0) {
        final key = _formatDate(cursor);
        result[key] = (result[key] ?? 0) + minutes;
      }
      cursor = segmentEnd;
    }

    return result;
  }

  List<String> _tips() {
    return const [
      'Turn off appliances when not in use to reduce standby power consumption',
      'Use LED bulbs which consume 75% less energy than incandescent bulbs',
      'Set your thermostat 2-3 degrees lower in winter and higher in summer',
      'Use energy-efficient appliances with high Energy Star ratings',
      'Regular maintenance of AC units can improve efficiency by up to 15%',
    ];
  }
}

class _DailySeries {
  const _DailySeries({required this.points, required this.todayKwh});

  final List<Map<String, dynamic>> points;
  final double todayKwh;
}
