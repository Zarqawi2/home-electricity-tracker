import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const meterCycleHistoryPrefsKey = 'meter_cycle_history_v1';
const _defaultMaxCycleHistory = 36;

class MeterCycleRecord {
  const MeterCycleRecord({
    required this.id,
    required this.fromReadingKwh,
    required this.toReadingKwh,
    required this.usageKwh,
    required this.costIqd,
    required this.profileId,
    required this.profileTitle,
    required this.days,
    required this.createdAt,
  });

  final String id;
  final double fromReadingKwh;
  final double toReadingKwh;
  final double usageKwh;
  final double costIqd;
  final String profileId;
  final String profileTitle;
  final int days;
  final DateTime createdAt;

  factory MeterCycleRecord.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    double parseNum(dynamic raw) {
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '') ?? 0;
    }

    int parseInt(dynamic raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    return MeterCycleRecord(
      id: (json['id'] ?? '').toString(),
      fromReadingKwh: parseNum(json['fromReadingKwh']),
      toReadingKwh: parseNum(json['toReadingKwh']),
      usageKwh: parseNum(json['usageKwh']),
      costIqd: parseNum(json['costIqd']),
      profileId: (json['profileId'] ?? '').toString(),
      profileTitle: (json['profileTitle'] ?? '').toString(),
      days: parseInt(json['days']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'fromReadingKwh': fromReadingKwh,
    'toReadingKwh': toReadingKwh,
    'usageKwh': usageKwh,
    'costIqd': costIqd,
    'profileId': profileId,
    'profileTitle': profileTitle,
    'days': days,
    'createdAt': createdAt.toIso8601String(),
  };
}

Future<List<MeterCycleRecord>> readSavedMeterCycleHistory() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(meterCycleHistoryPrefsKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <MeterCycleRecord>[];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <MeterCycleRecord>[];
    }
    final parsed = decoded
        .whereType<Map>()
        .map(
          (item) => MeterCycleRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id.isNotEmpty && item.usageKwh > 0)
        .toList(growable: false);
    return _sortByCreatedAtDesc(parsed);
  } catch (_) {
    return const <MeterCycleRecord>[];
  }
}

Future<List<MeterCycleRecord>> saveMeterCycleRecord(
  MeterCycleRecord record, {
  int maxItems = _defaultMaxCycleHistory,
}) async {
  final existing = await readSavedMeterCycleHistory();
  final deduped = existing.where((item) => item.id != record.id).toList();
  final merged = <MeterCycleRecord>[record, ...deduped];
  final sorted = _sortByCreatedAtDesc(merged);
  final normalized = sorted.length > maxItems
      ? sorted.sublist(0, maxItems)
      : sorted;

  try {
    final prefs = await SharedPreferences.getInstance();
    final payload = normalized.map((item) => item.toJson()).toList();
    await prefs.setString(meterCycleHistoryPrefsKey, jsonEncode(payload));
  } catch (_) {
    // Ignore persistence failures; callers still receive in-memory merged list.
  }
  return normalized;
}

Future<List<MeterCycleRecord>> clearMeterCycleHistory() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(meterCycleHistoryPrefsKey);
  } catch (_) {
    // Ignore persistence failures.
  }
  return const <MeterCycleRecord>[];
}

List<MeterCycleRecord> _sortByCreatedAtDesc(List<MeterCycleRecord> entries) {
  final sorted = List<MeterCycleRecord>.from(entries);
  sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return sorted;
}
