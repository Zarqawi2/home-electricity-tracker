import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/formatters/currency_formatter.dart';
import '../../data/datasources/local_appliance_store.dart';

final NumberFormat _kwhFormatter = NumberFormat('#,##0.###', 'en_US');
final NumberFormat _intFormatter = NumberFormat.decimalPattern('en_US');

const _canvas = Color(0xFFF8FAFC);
const _surface = Colors.white;
const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _line = Color(0xFFE2E8F0);

class OutageLogPage extends StatefulWidget {
  const OutageLogPage({super.key});

  @override
  State<OutageLogPage> createState() => _OutageLogPageState();
}

class _OutageLogPageState extends State<OutageLogPage> {
  final LocalApplianceStore _store = LocalApplianceStore();
  late Future<List<_OutageLogItem>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _loadLogs();
  }

  Future<List<_OutageLogItem>> _loadLogs() async {
    final rows = await _store.listOutageLogs(limit: 240);
    return rows.map(_OutageLogItem.fromMap).toList(growable: false);
  }

  Future<void> _refresh() async {
    final future = _loadLogs();
    setState(() {
      _logsFuture = future;
    });
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        title: const Text('تۆماری قەطعبوونی کارەبا'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _surface,
        foregroundColor: _ink,
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: _line)),
      ),
      body: RefreshIndicator(
        color: _ink,
        backgroundColor: _surface,
        onRefresh: _refresh,
        child: FutureBuilder<List<_OutageLogItem>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _ink),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _StateCard(
                    icon: Icons.error_outline,
                    title: 'هەڵە ڕوویدا',
                    subtitle: 'ناتوانرێت تۆمارەکان بخوێندرێنەوە.',
                  ),
                ],
              );
            }

            final logs = snapshot.data ?? const <_OutageLogItem>[];
            if (logs.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: const [
                  _StateCard(
                    icon: Icons.history_toggle_off_outlined,
                    title: 'هیچ تۆمارێک نییە',
                    subtitle:
                        'کاتێک دەست بە تۆمارکردنی قەطعبوون بکەیت یان دەستکاری بکەیت، لێرە دەر دەکەوێت.',
                  ),
                ],
              );
            }

            final summary = _OutageLogSummary.fromLogs(logs);
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              itemCount: logs.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _OutageSummaryCard(summary: summary);
                }
                return _OutageLogCard(item: logs[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}

class _OutageSummaryCard extends StatelessWidget {
  const _OutageSummaryCard({required this.summary});

  final _OutageLogSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _canvas,
                    border: Border.all(color: _line),
                  ),
                  child: const Icon(
                    Icons.insights_outlined,
                    size: 17,
                    color: _ink,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'پوختەی تۆمارەکان',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  label: 'کۆی تۆمار',
                  value: _intFormatter.format(summary.totalEvents),
                  icon: Icons.history_outlined,
                ),
                _SummaryChip(
                  label: 'کۆی گۆڕان',
                  value: _formatMinutes(summary.totalEventMinutes),
                  icon: Icons.access_time_outlined,
                ),
                _SummaryChip(
                  label: 'پاشەکەوتی kWh',
                  value: _signedKwh(summary.totalKwhSaved),
                  icon: Icons.electric_meter_outlined,
                ),
                _SummaryChip(
                  label: 'پاشەکەوتی نرخ',
                  value: _signedIqd(summary.totalIqdSaved),
                  icon: Icons.savings_outlined,
                ),
                _SummaryChip(
                  label: 'باری چالاک',
                  value:
                      '${_intFormatter.format(summary.averageActivePowerWatts)} W',
                  icon: Icons.electrical_services_outlined,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'دەستپێکردن: ${summary.startCount}  •  وەستاندن: ${summary.stopCount}  •  دەستکاری: ${summary.manualCount}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutageLogCard extends StatelessWidget {
  const _OutageLogCard({required this.item});

  final _OutageLogItem item;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd  HH:mm');
    final createdLabel = item.createdAt != null
        ? dateFormat.format(item.createdAt!)
        : '--';

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _canvas,
                    border: Border.all(color: _line),
                  ),
                  child: Icon(item.icon, color: _ink, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  createdLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _muted),
                ),
              ],
            ),
            if (item.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final detail in item.details) ...[
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
              ],
            ],
            if (item.stats.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: item.stats
                    .map(
                      (stat) => _SummaryChip(
                        label: stat.label,
                        value: stat.value,
                        icon: stat.icon,
                        dense: true,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: _ink),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _OutageLogItem {
  const _OutageLogItem({
    required this.type,
    required this.createdAt,
    required this.trackingStartAt,
    required this.trackingEndAt,
    required this.minutesAdded,
    required this.eventMinutes,
    required this.estimatedKwhSaved,
    required this.estimatedIqdSaved,
    required this.activePowerWatts,
    required this.date,
    required this.previousMinutes,
    required this.currentMinutes,
    required this.source,
  });

  factory _OutageLogItem.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) {
        return null;
      }
      return DateTime.tryParse(value.toString())?.toLocal();
    }

    return _OutageLogItem(
      type: map['type']?.toString() ?? 'manual_set',
      createdAt: parseDate(map['created_at']),
      trackingStartAt: parseDate(map['tracking_start_at']),
      trackingEndAt: parseDate(map['tracking_end_at']),
      minutesAdded: (map['minutes_added'] as num?)?.toInt(),
      eventMinutes: (map['event_minutes'] as num?)?.toInt(),
      estimatedKwhSaved: (map['estimated_kwh_saved'] as num?)?.toDouble(),
      estimatedIqdSaved: (map['estimated_iqd_saved'] as num?)?.toInt(),
      activePowerWatts: (map['active_power_watts'] as num?)?.toInt(),
      date: map['date']?.toString(),
      previousMinutes: (map['previous_minutes'] as num?)?.toInt(),
      currentMinutes: (map['current_minutes'] as num?)?.toInt(),
      source: map['source']?.toString() ?? '',
    );
  }

  final String type;
  final DateTime? createdAt;
  final DateTime? trackingStartAt;
  final DateTime? trackingEndAt;
  final int? minutesAdded;
  final int? eventMinutes;
  final double? estimatedKwhSaved;
  final int? estimatedIqdSaved;
  final int? activePowerWatts;
  final String? date;
  final int? previousMinutes;
  final int? currentMinutes;
  final String source;

  IconData get icon {
    switch (type) {
      case 'start':
        return Icons.play_circle_outline_rounded;
      case 'stop':
        return Icons.stop_circle_outlined;
      case 'manual_set':
        return Icons.edit_outlined;
      default:
        return Icons.history_outlined;
    }
  }

  String get title {
    switch (type) {
      case 'start':
        return 'دەستپێکردنی تۆمارکردن';
      case 'stop':
        return 'وەستاندنی تۆمارکردن';
      case 'manual_set':
        return 'دەستکاری دەستی';
      default:
        return 'تۆمار';
    }
  }

  List<String> get details {
    final dateFormat = DateFormat('yyyy/MM/dd  HH:mm');
    switch (type) {
      case 'start':
        final startLabel = trackingStartAt != null
            ? dateFormat.format(trackingStartAt!)
            : '--';
        return [
          'دەستی پێکرد لە: $startLabel',
          'سەرچاوە: ${_sourceLabel(source)}',
        ];
      case 'stop':
        final startLabel = trackingStartAt != null
            ? dateFormat.format(trackingStartAt!)
            : '--';
        final endLabel = trackingEndAt != null
            ? dateFormat.format(trackingEndAt!)
            : '--';
        final added = minutesAdded ?? 0;
        return [
          'لە $startLabel بۆ $endLabel',
          'خولەکی زیادکراو: $added',
          'سەرچاوە: ${_sourceLabel(source)}',
        ];
      case 'manual_set':
        final previous = previousMinutes ?? 0;
        final current = currentMinutes ?? 0;
        final dateLabel = date ?? '--';
        return [
          'ڕۆژ: $dateLabel',
          'گۆڕان: $previous -> $current خولەک',
          'سەرچاوە: ${_sourceLabel(source)}',
        ];
      default:
        return source.isEmpty ? const [] : ['سەرچاوە: ${_sourceLabel(source)}'];
    }
  }

  List<_OutageEventStat> get stats {
    final values = <_OutageEventStat>[];
    final minuteDelta = eventMinutes ?? minutesAdded;
    if (minuteDelta != null && minuteDelta != 0) {
      values.add(
        _OutageEventStat(
          label: 'گۆڕان',
          value: _formatMinutes(minuteDelta),
          icon: Icons.access_time_outlined,
        ),
      );
    }

    final kwhSaved = estimatedKwhSaved;
    if (kwhSaved != null && kwhSaved != 0) {
      values.add(
        _OutageEventStat(
          label: 'پاشەکەوتی kWh',
          value: _signedKwh(kwhSaved),
          icon: Icons.electric_meter_outlined,
        ),
      );
    }

    final iqdSaved = estimatedIqdSaved;
    if (iqdSaved != null && iqdSaved != 0) {
      values.add(
        _OutageEventStat(
          label: 'پاشەکەوتی نرخ',
          value: _signedIqd(iqdSaved),
          icon: Icons.savings_outlined,
        ),
      );
    }

    final activeWatts = activePowerWatts;
    if (activeWatts != null && activeWatts > 0) {
      values.add(
        _OutageEventStat(
          label: 'باری چالاک',
          value: '${_intFormatter.format(activeWatts)} W',
          icon: Icons.electrical_services_outlined,
        ),
      );
    }
    return values;
  }
}

class _OutageLogSummary {
  const _OutageLogSummary({
    required this.totalEvents,
    required this.startCount,
    required this.stopCount,
    required this.manualCount,
    required this.totalEventMinutes,
    required this.totalKwhSaved,
    required this.totalIqdSaved,
    required this.averageActivePowerWatts,
  });

  factory _OutageLogSummary.fromLogs(List<_OutageLogItem> logs) {
    var startCount = 0;
    var stopCount = 0;
    var manualCount = 0;
    var totalMinutes = 0;
    var totalKwh = 0.0;
    var totalIqd = 0;
    var powerSum = 0;
    var powerCount = 0;

    for (final item in logs) {
      if (item.type == 'start') {
        startCount += 1;
      } else if (item.type == 'stop') {
        stopCount += 1;
      } else if (item.type == 'manual_set') {
        manualCount += 1;
      }

      totalMinutes += item.eventMinutes ?? item.minutesAdded ?? 0;
      totalKwh += item.estimatedKwhSaved ?? 0;
      totalIqd += item.estimatedIqdSaved ?? 0;

      final watts = item.activePowerWatts;
      if (watts != null && watts > 0) {
        powerSum += watts;
        powerCount += 1;
      }
    }

    final averagePower = powerCount == 0 ? 0 : (powerSum / powerCount).round();
    return _OutageLogSummary(
      totalEvents: logs.length,
      startCount: startCount,
      stopCount: stopCount,
      manualCount: manualCount,
      totalEventMinutes: totalMinutes,
      totalKwhSaved: totalKwh,
      totalIqdSaved: totalIqd,
      averageActivePowerWatts: averagePower,
    );
  }

  final int totalEvents;
  final int startCount;
  final int stopCount;
  final int manualCount;
  final int totalEventMinutes;
  final double totalKwhSaved;
  final int totalIqdSaved;
  final int averageActivePowerWatts;
}

class _OutageEventStat {
  const _OutageEventStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    this.dense = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.circular(dense ? 11 : 12),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 13 : 14, color: _ink),
          SizedBox(width: dense ? 5 : 6),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatMinutes(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final absMinutes = minutes.abs();
  final hours = absMinutes ~/ 60;
  final remainingMinutes = absMinutes % 60;

  if (hours == 0) {
    return '$sign$remainingMinutes خولەک';
  }
  if (remainingMinutes == 0) {
    return '$sign$hours کاتژمێر';
  }
  return '$sign$hours کاتژمێر و $remainingMinutes خولەک';
}

String _signedKwh(double value) {
  final sign = value < 0 ? '-' : '+';
  return '$sign${_kwhFormatter.format(value.abs())} kWh';
}

String _signedIqd(num value) {
  final sign = value < 0 ? '-' : '+';
  return '$sign${formatIqd(value.abs())}';
}

String _sourceLabel(String source) {
  switch (source.toLowerCase()) {
    case 'manual':
      return 'دەستی';
    case 'tracker':
      return 'تۆمارکەر';
    case 'notification':
      return 'نوتیفیکەیشن';
    default:
      return source.trim().isEmpty ? 'ناسراو' : source;
  }
}
