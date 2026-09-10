import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/settings/electricity_tariff.dart';
import '../../../../core/settings/electricity_tariff_storage.dart';
import '../../../../core/settings/house_profile_controller.dart';
import '../../domain/services/consumption_calculator.dart';

class LocalApplianceStore {
  LocalApplianceStore({Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final Uuid _uuid;
  final DateTime Function() _now;
  Database? _database;

  static const _dbName = 'home_electricity.db';
  static const _dbVersion = 5;
  static const _applianceTable = 'appliances';
  static const _outageTable = 'power_outages';
  static const _outageLogTable = 'power_outage_logs';
  static const _legacyAppliancesKey = 'local_appliances_v1';
  static const _legacyMigrationKey = 'local_appliances_migrated_to_sqlite_v1';
  static const _storeInitializedKey = 'local_appliance_store_initialized_v1';
  static const _legacySeedCleanupKey =
      'local_appliances_legacy_seed_cleanup_v1';
  static const _webAppliancesKey = 'local_appliances_web_v2';
  static const _webOutagesKey = 'power_outages_web_v1';
  static const _webOutageLogsKey = 'power_outage_logs_web_v1';
  static const _outageTrackingStartKey = 'power_outage_tracking_start_iso_v1';
  static const _outageTrackingBaselineKey = 'power_outage_tracking_baseline_v1';
  static const _minutesPerDay = 1440;
  static const _legacySeedNames = <String>{
    'refrigerator',
    'air conditioner',
    'led tv',
    'washing machine',
    'water heater',
    'microwave',
  };
  static final RegExp _mojibakePattern = RegExp(r'[\u00D8\u00D9\u00DA\u00DB]');
  static final RegExp _arabicScriptPattern = RegExp(r'[\u0600-\u06FF]');

  bool get _usePrefsStorage {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return false;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
    }
  }

  Future<List<Map<String, dynamic>>> listAppliances() async {
    final activeProfileId = await readSelectedHouseProfileId();
    if (_usePrefsStorage) {
      return _listAppliancesPrefs(profileId: activeProfileId);
    }

    final db = await _readyDatabase();
    final rows = await db.query(
      _applianceTable,
      where: 'profile_id = ?',
      whereArgs: [activeProfileId],
      orderBy: 'LOWER(name) ASC',
    );
    return rows.map(_fromDbRow).toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> createAppliance({
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    final activeProfileId = await readSelectedHouseProfileId();
    if (_usePrefsStorage) {
      final allAppliances = (await _listAllAppliancesPrefs()).toList();
      allAppliances.add({
        'id': _uuid.v4(),
        'name': name,
        'category': category,
        'power_watts': powerW,
        'daily_use_hours': dailyUseHours,
        'is_on': isOn,
        'profile_id': activeProfileId,
      });
      final saved = await _saveAllAppliancesPrefs(allAppliances);
      return _filterAppliancesByProfile(saved, activeProfileId);
    }

    final db = await _readyDatabase();
    final payload = _normalize({
      'id': _uuid.v4(),
      'name': name,
      'category': category,
      'power_watts': powerW,
      'daily_use_hours': dailyUseHours,
      'is_on': isOn,
      'profile_id': activeProfileId,
    });

    await db.insert(
      _applianceTable,
      _toDbRow(payload),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return listAppliances();
  }

  Future<List<Map<String, dynamic>>> updateAppliance({
    required String id,
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    final activeProfileId = await readSelectedHouseProfileId();
    if (_usePrefsStorage) {
      final allAppliances = await _listAllAppliancesPrefs();
      final index = allAppliances.indexWhere(
        (item) =>
            item['id'] == id &&
            _normalizeProfileId(item['profile_id']) == activeProfileId,
      );
      if (index == -1) {
        return _filterAppliancesByProfile(allAppliances, activeProfileId);
      }

      allAppliances[index] = {
        'id': id,
        'name': name,
        'category': category,
        'power_watts': powerW,
        'daily_use_hours': dailyUseHours,
        'is_on': isOn,
        'profile_id': activeProfileId,
      };
      final saved = await _saveAllAppliancesPrefs(allAppliances);
      return _filterAppliancesByProfile(saved, activeProfileId);
    }

    final db = await _readyDatabase();
    final payload = _normalize({
      'id': id,
      'name': name,
      'category': category,
      'power_watts': powerW,
      'daily_use_hours': dailyUseHours,
      'is_on': isOn,
      'profile_id': activeProfileId,
    });

    await db.update(
      _applianceTable,
      _toDbRow(payload),
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, activeProfileId],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return listAppliances();
  }

  Future<List<Map<String, dynamic>>> deleteAppliance(String id) async {
    final activeProfileId = await readSelectedHouseProfileId();
    if (_usePrefsStorage) {
      final allAppliances = await _listAllAppliancesPrefs();
      allAppliances.removeWhere(
        (item) =>
            item['id'] == id &&
            _normalizeProfileId(item['profile_id']) == activeProfileId,
      );
      final saved = await _saveAllAppliancesPrefs(allAppliances);
      return _filterAppliancesByProfile(saved, activeProfileId);
    }

    final db = await _readyDatabase();
    await db.delete(
      _applianceTable,
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, activeProfileId],
    );
    return listAppliances();
  }

  Future<List<Map<String, dynamic>>> toggleAppliance(String id) async {
    final activeProfileId = await readSelectedHouseProfileId();
    if (_usePrefsStorage) {
      final allAppliances = await _listAllAppliancesPrefs();
      final index = allAppliances.indexWhere(
        (item) =>
            item['id'] == id &&
            _normalizeProfileId(item['profile_id']) == activeProfileId,
      );
      if (index == -1) {
        return _filterAppliancesByProfile(allAppliances, activeProfileId);
      }

      allAppliances[index] = {
        ...allAppliances[index],
        'is_on': !(allAppliances[index]['is_on'] as bool? ?? false),
      };
      final saved = await _saveAllAppliancesPrefs(allAppliances);
      return _filterAppliancesByProfile(saved, activeProfileId);
    }

    final db = await _readyDatabase();
    final existing = await db.query(
      _applianceTable,
      columns: ['is_on'],
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, activeProfileId],
      limit: 1,
    );

    if (existing.isEmpty) {
      return listAppliances();
    }

    final current = existing.first['is_on'];
    final isOn = current == 1 || current == true || current == '1';
    await db.update(
      _applianceTable,
      {'is_on': isOn ? 0 : 1},
      where: 'id = ? AND profile_id = ?',
      whereArgs: [id, activeProfileId],
    );
    return listAppliances();
  }

  Future<void> setOutageMinutesForDate({
    required DateTime date,
    required int outageMinutes,
    bool logChange = false,
    String source = 'manual',
    String? tariffProfileId,
  }) async {
    final normalized = outageMinutes.clamp(0, _minutesPerDay).toInt();
    final dateKey = _formatDate(date);
    final resolvedTariffProfileId = await _resolveTariffProfileId(
      tariffProfileId,
    );

    if (_usePrefsStorage) {
      final outages = await _listOutagesPrefs();
      final previous = outages[dateKey] ?? 0;
      outages[dateKey] = normalized;
      await _saveOutagesPrefs(outages);
      if (logChange && previous != normalized) {
        final delta = normalized - previous;
        final baseline = await _captureOutageBaseline(
          date,
          resolvedTariffProfileId,
        );
        final savings = _buildSavingsSnapshot(
          eventMinutes: delta,
          baseline: baseline,
        );
        await _appendOutageLog(
          _createOutageLog(
            type: 'manual_set',
            createdAt: _now(),
            date: dateKey,
            previousMinutes: previous,
            currentMinutes: normalized,
            eventMinutes: savings['event_minutes'] as int?,
            estimatedKwhSaved: savings['estimated_kwh_saved'] as double?,
            estimatedIqdSaved: savings['estimated_iqd_saved'] as int?,
            activePowerWatts: savings['active_power_watts'] as int?,
            source: source,
          ),
        );
      }
      return;
    }

    final previous = await getOutageMinutesForDate(date);
    final db = await _readyDatabase();
    await db.insert(_outageTable, {
      'date': dateKey,
      'outage_minutes': normalized,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    if (logChange && previous != normalized) {
      final delta = normalized - previous;
      final baseline = await _captureOutageBaseline(
        date,
        resolvedTariffProfileId,
      );
      final savings = _buildSavingsSnapshot(
        eventMinutes: delta,
        baseline: baseline,
      );
      await _appendOutageLog(
        _createOutageLog(
          type: 'manual_set',
          createdAt: _now(),
          date: dateKey,
          previousMinutes: previous,
          currentMinutes: normalized,
          eventMinutes: savings['event_minutes'] as int?,
          estimatedKwhSaved: savings['estimated_kwh_saved'] as double?,
          estimatedIqdSaved: savings['estimated_iqd_saved'] as int?,
          activePowerWatts: savings['active_power_watts'] as int?,
          source: source,
        ),
      );
    }
  }

  Future<int> getOutageMinutesForDate(DateTime date) async {
    final dateKey = _formatDate(date);

    if (_usePrefsStorage) {
      final outages = await _listOutagesPrefs();
      return outages[dateKey] ?? 0;
    }

    final db = await _readyDatabase();
    final rows = await db.query(
      _outageTable,
      columns: ['outage_minutes'],
      where: 'date = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) {
      return 0;
    }
    return (rows.first['outage_minutes'] as num?)?.toInt() ?? 0;
  }

  Future<Map<String, int>> getOutageMinutesInRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final fromKey = _formatDate(from);
    final toKey = _formatDate(to);

    if (_usePrefsStorage) {
      final outages = await _listOutagesPrefs();
      return {
        for (final entry in outages.entries)
          if (entry.key.compareTo(fromKey) >= 0 &&
              entry.key.compareTo(toKey) <= 0)
            entry.key: entry.value,
      };
    }

    final db = await _readyDatabase();
    final rows = await db.query(
      _outageTable,
      columns: ['date', 'outage_minutes'],
      where: 'date BETWEEN ? AND ?',
      whereArgs: [fromKey, toKey],
    );

    return {
      for (final row in rows)
        (row['date'] as String): (row['outage_minutes'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> startOutageTracking({String source = 'tracker'}) async {
    final existing = await _readOutageTrackingStart();
    if (existing != null) {
      return;
    }
    final startedAt = _now();
    final tariffProfileId = await _resolveTariffProfileId(null);
    final baseline = await _captureOutageBaseline(startedAt, tariffProfileId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _outageTrackingBaselineKey,
      jsonEncode({
        'started_at': startedAt.toIso8601String(),
        'average_power_watts': baseline.averagePowerWatts,
        'monthly_kwh': baseline.monthlyKwh,
        'tariff_profile_id': baseline.tariffProfileId,
      }),
    );
    await _writeOutageTrackingStart(startedAt);
    await _appendOutageLog(
      _createOutageLog(
        type: 'start',
        createdAt: startedAt,
        trackingStartAt: startedAt,
        eventMinutes: 0,
        activePowerWatts: baseline.averagePowerWatts.round(),
        source: source,
      ),
    );
  }

  Future<int> stopOutageTracking({
    String source = 'tracker',
    String? tariffProfileId,
  }) async {
    final startedAt = await _readOutageTrackingStart();
    if (startedAt == null) {
      return 0;
    }
    final resolvedTariffProfileId = await _resolveTariffProfileId(
      tariffProfileId,
    );

    final baseline = await _readOutageBaseline(
      startedAt,
      resolvedTariffProfileId,
    );
    final stoppedAt = _now();
    if (!stoppedAt.isAfter(startedAt)) {
      await _clearOutageTrackingStart();
      return 0;
    }

    final additions = _splitRangeAcrossDates(start: startedAt, end: stoppedAt);
    if (additions.isEmpty) {
      await _clearOutageTrackingStart();
      return 0;
    }

    var appliedMinutes = 0;
    for (final entry in additions.entries) {
      final date = DateTime.parse(entry.key);
      final current = await getOutageMinutesForDate(date);
      final next = (current + entry.value).clamp(0, _minutesPerDay).toInt();
      await setOutageMinutesForDate(
        date: date,
        outageMinutes: next,
        tariffProfileId: resolvedTariffProfileId,
      );
      appliedMinutes += next - current.clamp(0, _minutesPerDay).toInt();
    }

    final savings = _buildSavingsSnapshot(
      eventMinutes: appliedMinutes,
      baseline: baseline,
    );

    await _appendOutageLog(
      _createOutageLog(
        type: 'stop',
        createdAt: stoppedAt,
        trackingStartAt: startedAt,
        trackingEndAt: stoppedAt,
        minutesAdded: appliedMinutes,
        eventMinutes: savings['event_minutes'] as int?,
        estimatedKwhSaved: savings['estimated_kwh_saved'] as double?,
        estimatedIqdSaved: savings['estimated_iqd_saved'] as int?,
        activePowerWatts: savings['active_power_watts'] as int?,
        source: source,
      ),
    );

    await _clearOutageTrackingStart();
    return appliedMinutes;
  }

  Future<bool> isOutageTrackingActive() async {
    return (await _readOutageTrackingStart()) != null;
  }

  Future<DateTime?> getOutageTrackingStart() {
    return _readOutageTrackingStart();
  }

  Future<List<Map<String, dynamic>>> listOutageLogs({int limit = 120}) async {
    final safeLimit = limit.clamp(1, 500).toInt();

    if (_usePrefsStorage) {
      return _listOutageLogsPrefs(limit: safeLimit);
    }

    final db = await _readyDatabase();
    final rows = await db.query(
      _outageLogTable,
      orderBy: 'created_at DESC',
      limit: safeLimit,
    );
    return rows
        .map((row) => _fromOutageLogDbRow(row))
        .map(_normalizeOutageLog)
        .toList(growable: false);
  }

  Future<List<Map<String, dynamic>>> _listAppliancesPrefs({
    required String profileId,
  }) async {
    final allAppliances = await _listAllAppliancesPrefs();
    return _filterAppliancesByProfile(allAppliances, profileId);
  }

  Future<List<Map<String, dynamic>>> _listAllAppliancesPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_webAppliancesKey) ??
        prefs.getString(_legacyAppliancesKey);

    if (raw == null || raw.isEmpty) {
      const empty = <Map<String, dynamic>>[];
      await _saveAllAppliancesPrefs(empty, prefs: prefs);
      return empty;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        const empty = <Map<String, dynamic>>[];
        await _saveAllAppliancesPrefs(empty, prefs: prefs);
        return empty;
      }

      final normalized = _sortByName(
        decoded
            .whereType<Map>()
            .map((item) => _normalize(item.cast<String, dynamic>()))
            .where(_shouldKeepLegacyItem)
            .toList(),
      );
      await _saveAllAppliancesPrefs(normalized, prefs: prefs);
      return normalized;
    } catch (_) {
      const empty = <Map<String, dynamic>>[];
      await _saveAllAppliancesPrefs(empty, prefs: prefs);
      return empty;
    }
  }

  Future<List<Map<String, dynamic>>> _saveAllAppliancesPrefs(
    List<Map<String, dynamic>> appliances, {
    SharedPreferences? prefs,
  }) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final normalized = _sortByName(appliances.map(_normalize).toList());
    await preferences.setString(_webAppliancesKey, jsonEncode(normalized));
    return normalized;
  }

  List<Map<String, dynamic>> _filterAppliancesByProfile(
    List<Map<String, dynamic>> appliances,
    String profileId,
  ) {
    final safeProfileId = _normalizeProfileId(profileId);
    return appliances
        .where(
          (item) => _normalizeProfileId(item['profile_id']) == safeProfileId,
        )
        .toList(growable: false);
  }

  Future<Map<String, int>> _listOutagesPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webOutagesKey);
    if (raw == null || raw.isEmpty) {
      return <String, int>{};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return <String, int>{};
      }

      return {
        for (final entry in decoded.entries)
          entry.key: (entry.value as num?)?.toInt() ?? 0,
      };
    } catch (_) {
      return <String, int>{};
    }
  }

  Future<void> _saveOutagesPrefs(Map<String, int> outages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webOutagesKey, jsonEncode(outages));
  }

  Future<List<Map<String, dynamic>>> _listOutageLogsPrefs({
    required int limit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webOutageLogsKey);
    if (raw == null || raw.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <Map<String, dynamic>>[];
      }

      final logs = decoded
          .whereType<Map>()
          .map((item) => _normalizeOutageLog(item.cast<String, dynamic>()))
          .toList(growable: false);
      return logs.take(limit).toList(growable: false);
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveOutageLogsPrefs(List<Map<String, dynamic>> logs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_webOutageLogsKey, jsonEncode(logs));
  }

  Future<void> _appendOutageLog(Map<String, dynamic> log) async {
    final normalized = _normalizeOutageLog(log);

    if (_usePrefsStorage) {
      final existing = await _listOutageLogsPrefs(limit: 500);
      final updated = [normalized, ...existing];
      final limited = updated.take(500).toList(growable: false);
      await _saveOutageLogsPrefs(limited);
      return;
    }

    final db = await _readyDatabase();
    await db.insert(
      _outageLogTable,
      _toOutageLogDbRow(normalized),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.execute('''
      DELETE FROM $_outageLogTable
      WHERE id NOT IN (
        SELECT id FROM $_outageLogTable
        ORDER BY created_at DESC
        LIMIT 500
      )
    ''');
  }

  Map<String, dynamic> _createOutageLog({
    required String type,
    required DateTime createdAt,
    DateTime? trackingStartAt,
    DateTime? trackingEndAt,
    int? minutesAdded,
    int? eventMinutes,
    double? estimatedKwhSaved,
    int? estimatedIqdSaved,
    int? activePowerWatts,
    String? date,
    int? previousMinutes,
    int? currentMinutes,
    required String source,
  }) {
    return _normalizeOutageLog({
      'id': _uuid.v4(),
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'tracking_start_at': trackingStartAt?.toIso8601String(),
      'tracking_end_at': trackingEndAt?.toIso8601String(),
      'minutes_added': minutesAdded,
      'event_minutes': eventMinutes,
      'estimated_kwh_saved': estimatedKwhSaved,
      'estimated_iqd_saved': estimatedIqdSaved,
      'active_power_watts': activePowerWatts,
      'date': date,
      'previous_minutes': previousMinutes,
      'current_minutes': currentMinutes,
      'source': source,
    });
  }

  Future<DateTime?> _readOutageTrackingStart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_outageTrackingStartKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      await prefs.remove(_outageTrackingStartKey);
      return null;
    }

    return parsed.toLocal();
  }

  Future<void> _writeOutageTrackingStart(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outageTrackingStartKey, dateTime.toIso8601String());
  }

  Future<void> _clearOutageTrackingStart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_outageTrackingStartKey);
    await prefs.remove(_outageTrackingBaselineKey);
  }

  Map<String, int> _splitRangeAcrossDates({
    required DateTime start,
    required DateTime end,
  }) {
    if (!end.isAfter(start)) {
      return const <String, int>{};
    }

    final result = <String, int>{};
    var cursor = start;

    while (cursor.isBefore(end)) {
      final nextMidnight = DateTime(cursor.year, cursor.month, cursor.day + 1);
      final segmentEnd = end.isBefore(nextMidnight) ? end : nextMidnight;
      final minutes = segmentEnd.difference(cursor).inMinutes;
      if (minutes > 0) {
        final dateKey = _formatDate(cursor);
        result[dateKey] = (result[dateKey] ?? 0) + minutes;
      }
      cursor = segmentEnd;
    }

    return result;
  }

  Future<_OutageBaseline> _captureOutageBaseline(
    DateTime date,
    String tariffProfileId,
  ) async {
    final appliances = await listAppliances();
    final dailyKwh = appliances.fold<double>(0, (sum, appliance) {
      return sum +
          scheduledDailyKwh(
            powerWatts: (appliance['power_watts'] as num?)?.toDouble() ?? 0,
            dailyUseHours:
                (appliance['daily_use_hours'] as num?)?.toDouble() ?? 0,
            isOn: appliance['is_on'] == true,
          );
    });
    // Without an hourly schedule, spread configured daily use evenly over 24h.
    // Treating every enabled appliance as drawing nameplate power throughout
    // an outage significantly overstates the estimated avoided consumption.
    return _OutageBaseline(
      averagePowerWatts: dailyKwh * 1000 / 24,
      monthlyKwh: dailyKwh * daysInCalendarMonth(date),
      tariffProfileId: tariffProfileId,
    );
  }

  Future<_OutageBaseline> _readOutageBaseline(
    DateTime startedAt,
    String fallbackTariffProfileId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_outageTrackingBaselineKey);
    if (raw != null) {
      try {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        final savedStart = DateTime.tryParse(saved['started_at'] as String);
        final watts = (saved['average_power_watts'] as num).toDouble();
        final monthlyKwh = (saved['monthly_kwh'] as num).toDouble();
        if (savedStart == startedAt &&
            watts.isFinite &&
            watts >= 0 &&
            monthlyKwh.isFinite &&
            monthlyKwh >= 0) {
          return _OutageBaseline(
            averagePowerWatts: watts,
            monthlyKwh: monthlyKwh,
            tariffProfileId: tariffProfileById(
              saved['tariff_profile_id'] as String?,
            ).id,
          );
        }
      } catch (_) {
        // Older trackers did not persist a schedule/tariff snapshot.
      }
    }

    // Preserve an older tracker's captured load if present. Its historical
    // daily schedule and tariff cannot be reconstructed after an app update.
    final logs = await listOutageLogs(limit: 500);
    for (final log in logs) {
      final logStart = DateTime.tryParse(
        log['tracking_start_at']?.toString() ?? '',
      );
      final watts = (log['active_power_watts'] as num?)?.toDouble();
      if (log['type'] == 'start' &&
          logStart == startedAt &&
          watts != null &&
          watts.isFinite &&
          watts >= 0) {
        return _OutageBaseline(
          averagePowerWatts: watts,
          monthlyKwh: watts / 1000 * 24 * daysInCalendarMonth(startedAt),
          tariffProfileId: fallbackTariffProfileId,
        );
      }
    }
    return _captureOutageBaseline(startedAt, fallbackTariffProfileId);
  }

  Map<String, dynamic> _buildSavingsSnapshot({
    required int eventMinutes,
    required _OutageBaseline baseline,
  }) {
    final activePowerWatts = baseline.averagePowerWatts.round();
    if (eventMinutes == 0 || baseline.averagePowerWatts <= 0) {
      return {
        'event_minutes': eventMinutes,
        'estimated_kwh_saved': 0.0,
        'estimated_iqd_saved': 0,
        'active_power_watts': activePowerWatts,
      };
    }

    final absMinutes = eventMinutes.abs();
    final kwh = (baseline.averagePowerWatts / 1000.0) * (absMinutes / 60.0);
    final profile = tariffProfileById(baseline.tariffProfileId);
    final estimatedCost =
        (calculateElectricityCostIqd(
                  kwh: baseline.monthlyKwh,
                  profile: profile,
                ) -
                calculateElectricityCostIqd(
                  kwh: baseline.monthlyKwh - kwh,
                  profile: profile,
                ))
            .round();
    final sign = eventMinutes < 0 ? -1 : 1;

    return {
      'event_minutes': eventMinutes,
      'estimated_kwh_saved': kwh * sign,
      'estimated_iqd_saved': estimatedCost * sign,
      'active_power_watts': activePowerWatts,
    };
  }

  Future<String> _resolveTariffProfileId(
    String? overrideTariffProfileId,
  ) async {
    if (overrideTariffProfileId != null && overrideTariffProfileId.isNotEmpty) {
      return tariffProfileById(overrideTariffProfileId).id;
    }
    final profile = await readSavedElectricityTariffProfile();
    return profile.id;
  }

  Future<Database> _readyDatabase() async {
    final db = await _openOrGetDatabase();
    await _ensureSeedOrMigrated(db);
    return db;
  }

  Future<Database> _openOrGetDatabase() async {
    if (_database != null) {
      return _database!;
    }

    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    _database = await openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_outageTable (
              date TEXT PRIMARY KEY,
              outage_minutes INTEGER NOT NULL
            )
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS $_outageLogTable (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              created_at TEXT NOT NULL,
              tracking_start_at TEXT,
              tracking_end_at TEXT,
              minutes_added INTEGER,
              event_minutes INTEGER,
              estimated_kwh_saved REAL,
              estimated_iqd_saved INTEGER,
              active_power_watts INTEGER,
              date TEXT,
              previous_minutes INTEGER,
              current_minutes INTEGER,
              source TEXT
            )
          ''');
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_outage_logs_created_at
            ON $_outageLogTable(created_at)
          ''');
        }
        if (oldVersion < 4) {
          final columns = await db.rawQuery(
            'PRAGMA table_info($_outageLogTable)',
          );

          Future<void> addIfMissing(String name, String type) async {
            final exists = columns.any((row) => row['name'] == name);
            if (!exists) {
              await db.execute(
                'ALTER TABLE $_outageLogTable ADD COLUMN $name $type',
              );
            }
          }

          await addIfMissing('event_minutes', 'INTEGER');
          await addIfMissing('estimated_kwh_saved', 'REAL');
          await addIfMissing('estimated_iqd_saved', 'INTEGER');
          await addIfMissing('active_power_watts', 'INTEGER');
        }
        if (oldVersion < 5) {
          final applianceColumns = await db.rawQuery(
            'PRAGMA table_info($_applianceTable)',
          );
          final hasProfileId = applianceColumns.any(
            (row) => row['name'] == 'profile_id',
          );
          if (!hasProfileId) {
            await db.execute(
              'ALTER TABLE $_applianceTable ADD COLUMN profile_id TEXT',
            );
          }
          await db.rawUpdate(
            '''
            UPDATE $_applianceTable
            SET profile_id = ?
            WHERE profile_id IS NULL OR TRIM(profile_id) = ''
            ''',
            [defaultHouseProfileId],
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_appliances_profile_id ON $_applianceTable(profile_id)',
          );
        }
      },
    );

    return _database!;
  }

  Future<void> _ensureSeedOrMigrated(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyMigrated = prefs.getBool(_legacyMigrationKey) ?? false;
    final hasInitFlag = prefs.containsKey(_storeInitializedKey);
    final isInitialized =
        (prefs.getBool(_storeInitializedKey) ?? false) || alreadyMigrated;

    var rowCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_applianceTable'),
        ) ??
        0;
    if (rowCount > 0 && !hasInitFlag) {
      final cleaned = await _cleanupLegacySeededAppliancesIfNeeded(db, prefs);
      if (cleaned) {
        rowCount =
            Sqflite.firstIntValue(
              await db.rawQuery('SELECT COUNT(*) FROM $_applianceTable'),
            ) ??
            0;
      }
    }

    if (rowCount > 0) {
      if (!isInitialized) {
        await prefs.setBool(_storeInitializedKey, true);
      }
      return;
    }

    // Empty appliance list can be a valid user state (all appliances deleted),
    // so don't re-seed defaults after the store has been initialized once.
    if (isInitialized) {
      if (prefs.getBool(_storeInitializedKey) != true) {
        await prefs.setBool(_storeInitializedKey, true);
      }
      return;
    }

    if (!alreadyMigrated) {
      final migrated = await _migrateLegacyJsonToSqlite(db, prefs);
      await prefs.setBool(_legacyMigrationKey, true);
      if (migrated) {
        await prefs.setBool(_storeInitializedKey, true);
        return;
      }
    }

    // No default seeding: start with an empty list on first install.
    await prefs.setBool(_storeInitializedKey, true);
  }

  Future<bool> _migrateLegacyJsonToSqlite(
    Database db,
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_legacyAppliancesKey);
    if (raw == null || raw.isEmpty) {
      return false;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return false;
      }

      final appliances = decoded
          .whereType<Map>()
          .map((item) => _normalize(item.cast<String, dynamic>()))
          .where(_shouldKeepLegacyItem)
          .toList();
      if (_isLegacySeedSet(appliances)) {
        return false;
      }
      if (appliances.isEmpty) {
        return false;
      }

      await _insertMany(db, appliances);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _cleanupLegacySeededAppliancesIfNeeded(
    Database db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_legacySeedCleanupKey) == true) {
      return false;
    }

    try {
      final rows = await db.query(_applianceTable, columns: ['id', 'name']);
      if (!_looksLikeLegacySeed(rows)) {
        return false;
      }

      await db.delete(_applianceTable);
      return true;
    } finally {
      await prefs.setBool(_legacySeedCleanupKey, true);
    }
  }

  bool _looksLikeLegacySeed(List<Map<String, Object?>> rows) {
    if (rows.isEmpty || rows.length > _legacySeedNames.length) {
      return false;
    }

    final normalizedNames = rows
        .map((row) => (row['name']?.toString() ?? '').trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
    if (normalizedNames.length != rows.length) {
      return false;
    }
    if (!normalizedNames.every(_legacySeedNames.contains)) {
      return false;
    }

    final normalizedIds = rows
        .map((row) => row['id']?.toString().trim().toLowerCase() ?? '')
        .where((id) => id.isNotEmpty);
    final idPattern = RegExp(r'^(default-|seed-|appliance-|\d+$)');
    final allMatchIdPattern = normalizedIds.every(idPattern.hasMatch);

    return allMatchIdPattern ||
        normalizedNames.length == _legacySeedNames.length;
  }

  bool _isLegacySeedSet(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty || rows.length > _legacySeedNames.length) {
      return false;
    }

    final names = rows
        .map((row) => (row['name'] as String? ?? '').trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();
    return names.length == rows.length &&
        names.every(_legacySeedNames.contains) &&
        names.length == _legacySeedNames.length;
  }

  bool _shouldKeepLegacyItem(Map<String, dynamic> item) {
    final name = (item['name'] as String? ?? '').trim().toLowerCase();
    final id = (item['id'] as String? ?? '').trim().toLowerCase();
    final looksLikeSeedId = id.startsWith('default-') || id.startsWith('seed-');

    if (_legacySeedNames.contains(name) && looksLikeSeedId) {
      return false;
    }
    return true;
  }

  Future<void> _insertMany(
    Database db,
    List<Map<String, dynamic>> appliances,
  ) async {
    final batch = db.batch();
    for (final appliance in appliances) {
      batch.insert(
        _applianceTable,
        _toDbRow(appliance),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE $_applianceTable (
        id TEXT PRIMARY KEY,
        profile_id TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        power_watts INTEGER NOT NULL,
        daily_use_hours REAL NOT NULL,
        is_on INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_outageTable (
        date TEXT PRIMARY KEY,
        outage_minutes INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE $_outageLogTable (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        tracking_start_at TEXT,
        tracking_end_at TEXT,
        minutes_added INTEGER,
        event_minutes INTEGER,
        estimated_kwh_saved REAL,
        estimated_iqd_saved INTEGER,
        active_power_watts INTEGER,
        date TEXT,
        previous_minutes INTEGER,
        current_minutes INTEGER,
        source TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_appliances_name ON $_applianceTable(name)',
    );
    await db.execute(
      'CREATE INDEX idx_appliances_profile_id ON $_applianceTable(profile_id)',
    );
    await db.execute(
      'CREATE INDEX idx_outage_logs_created_at ON $_outageLogTable(created_at)',
    );
  }

  Map<String, dynamic> _toDbRow(Map<String, dynamic> item) {
    final normalized = _normalize(item);
    return {
      'id': normalized['id'],
      'profile_id': normalized['profile_id'],
      'name': normalized['name'],
      'category': normalized['category'],
      'power_watts': normalized['power_watts'],
      'daily_use_hours': normalized['daily_use_hours'],
      'is_on': (normalized['is_on'] as bool) ? 1 : 0,
    };
  }

  Map<String, dynamic> _fromDbRow(Map<String, dynamic> item) {
    return _normalize({...item, 'is_on': item['is_on'] == 1});
  }

  Map<String, dynamic> _toOutageLogDbRow(Map<String, dynamic> item) {
    final normalized = _normalizeOutageLog(item);
    return {
      'id': normalized['id'],
      'type': normalized['type'],
      'created_at': normalized['created_at'],
      'tracking_start_at': normalized['tracking_start_at'],
      'tracking_end_at': normalized['tracking_end_at'],
      'minutes_added': normalized['minutes_added'],
      'event_minutes': normalized['event_minutes'],
      'estimated_kwh_saved': normalized['estimated_kwh_saved'],
      'estimated_iqd_saved': normalized['estimated_iqd_saved'],
      'active_power_watts': normalized['active_power_watts'],
      'date': normalized['date'],
      'previous_minutes': normalized['previous_minutes'],
      'current_minutes': normalized['current_minutes'],
      'source': normalized['source'],
    };
  }

  Map<String, dynamic> _fromOutageLogDbRow(Map<String, dynamic> item) {
    return _normalizeOutageLog(item);
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> item) {
    final power = item['power_watts'];
    final hours = item['daily_use_hours'];
    final isOn = item['is_on'];
    final normalizedProfileId = _normalizeProfileId(item['profile_id']);
    final normalizedName = _normalizeDisplayText(
      item['name']?.toString(),
      fallback: 'Unknown',
    );
    final normalizedCategory = _normalizeCategory(item['category']?.toString());

    return {
      'id': item['id']?.toString() ?? _uuid.v4(),
      'profile_id': normalizedProfileId,
      'name': normalizedName,
      'category': normalizedCategory,
      'power_watts': power is num ? power.round() : 0,
      'daily_use_hours': hours is num ? hours.toDouble() : 0.0,
      'is_on': isOn == true || isOn == 1 || isOn == 'true',
    };
  }

  String _normalizeProfileId(Object? raw) {
    final value = raw?.toString().trim() ?? '';
    return value.isNotEmpty ? value : defaultHouseProfileId;
  }

  String _normalizeDisplayText(String? raw, {required String fallback}) {
    final value = _repairMojibake(raw?.trim() ?? '').trim();
    return value.isNotEmpty ? value : fallback;
  }

  String _normalizeCategory(String? raw) {
    final value = _normalizeDisplayText(raw, fallback: 'Other');
    switch (value) {
      case 'Kitchen':
      case 'چێشتخانە':
        return 'Kitchen';
      case 'Climate Control':
      case 'کۆنترۆڵی هەوا':
        return 'Climate Control';
      case 'Entertainment':
      case 'سەرگرمی':
      case 'موزیک':
        return 'Entertainment';
      case 'Laundry':
      case 'جلشۆر':
        return 'Laundry';
      case 'Water Heating':
      case 'ئاو گەرمکەر':
      case 'گەرمکردنی ئاو':
        return 'Water Heating';
      case 'Hall':
      case 'هۆڵ':
        return 'Hall';
      case 'Bathroom':
      case 'حەمام':
        return 'Bathroom';
      case 'Outdoor':
      case 'دەرەوە':
        return 'Outdoor';
      case 'Bedroom':
      case 'ووری خەوتن':
        return 'Bedroom';
      case 'Other':
      case 'هی تر':
        return 'Other';
      default:
        return value;
    }
  }

  String _repairMojibake(String value) {
    if (value.isEmpty || !_mojibakePattern.hasMatch(value)) {
      return value;
    }

    final bytes = latin1.encode(value);
    final originalScore = _mojibakePattern.allMatches(value).length;
    for (final allowMalformed in const [false, true]) {
      try {
        final candidate = utf8.decode(bytes, allowMalformed: allowMalformed);
        if (candidate.isEmpty || candidate == value) {
          continue;
        }

        final candidateScore = _mojibakePattern.allMatches(candidate).length;
        final candidateHasArabic = _arabicScriptPattern.hasMatch(candidate);
        final originalHasArabic = _arabicScriptPattern.hasMatch(value);

        if (candidateHasArabic && !originalHasArabic) {
          return candidate;
        }
        if (candidateScore < originalScore) {
          return candidate;
        }
      } catch (_) {
        // Keep original text when conversion fails.
      }
    }

    return value;
  }

  Map<String, dynamic> _normalizeOutageLog(Map<String, dynamic> item) {
    return {
      'id': item['id']?.toString() ?? _uuid.v4(),
      'type': item['type']?.toString() ?? 'manual_set',
      'created_at':
          item['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'tracking_start_at': item['tracking_start_at']?.toString(),
      'tracking_end_at': item['tracking_end_at']?.toString(),
      'minutes_added': (item['minutes_added'] as num?)?.toInt(),
      'event_minutes': (item['event_minutes'] as num?)?.toInt(),
      'estimated_kwh_saved': (item['estimated_kwh_saved'] as num?)?.toDouble(),
      'estimated_iqd_saved': (item['estimated_iqd_saved'] as num?)?.toInt(),
      'active_power_watts': (item['active_power_watts'] as num?)?.toInt(),
      'date': item['date']?.toString(),
      'previous_minutes': (item['previous_minutes'] as num?)?.toInt(),
      'current_minutes': (item['current_minutes'] as num?)?.toInt(),
      'source': item['source']?.toString() ?? 'tracker',
    };
  }

  List<Map<String, dynamic>> _sortByName(List<Map<String, dynamic>> items) {
    items.sort((a, b) {
      final aName = (a['name'] as String? ?? '').toLowerCase();
      final bName = (b['name'] as String? ?? '').toLowerCase();
      return aName.compareTo(bName);
    });
    return items;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _OutageBaseline {
  const _OutageBaseline({
    required this.averagePowerWatts,
    required this.monthlyKwh,
    required this.tariffProfileId,
  });

  final double averagePowerWatts;
  final double monthlyKwh;
  final String tariffProfileId;
}
