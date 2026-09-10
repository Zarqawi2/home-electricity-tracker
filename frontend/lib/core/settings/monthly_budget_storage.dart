import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const monthlyBudgetPrefsKey = 'monthly_budget_iqd_v1';
const monthlyBudgetByProfilePrefsKey = 'monthly_budget_iqd_by_profile_v2';

Future<double?> readSavedMonthlyBudgetIqd() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.get(monthlyBudgetPrefsKey);
    if (raw is num) {
      final value = raw.toDouble();
      return value > 0 ? value : null;
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> saveMonthlyBudgetIqd(double? budgetIqd) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (budgetIqd == null || budgetIqd <= 0) {
      await prefs.remove(monthlyBudgetPrefsKey);
      return;
    }
    await prefs.setDouble(monthlyBudgetPrefsKey, budgetIqd);
  } catch (_) {
    // Ignore persistence failures; value can still be used in-memory.
  }
}

Future<double?> readSavedMonthlyBudgetIqdForProfile(String profileId) async {
  final normalizedProfileId = profileId.trim();
  if (normalizedProfileId.isEmpty) return null;

  try {
    final prefs = await SharedPreferences.getInstance();
    final savedMap = _readBudgetMap(prefs);
    final fromMap = savedMap[normalizedProfileId];
    if (fromMap != null && fromMap > 0) {
      return fromMap;
    }

    // Backward compatibility with the old single-budget key.
    final legacy = prefs.get(monthlyBudgetPrefsKey);
    if (legacy is num) {
      final value = legacy.toDouble();
      if (value > 0) {
        savedMap[normalizedProfileId] = value;
        await _writeBudgetMap(prefs, savedMap);
        await prefs.remove(monthlyBudgetPrefsKey);
        return value;
      }
    }
    return null;
  } catch (_) {
    return null;
  }
}

Future<void> saveMonthlyBudgetIqdForProfile({
  required String profileId,
  required double? budgetIqd,
}) async {
  final normalizedProfileId = profileId.trim();
  if (normalizedProfileId.isEmpty) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    final savedMap = _readBudgetMap(prefs);
    if (budgetIqd == null || budgetIqd <= 0) {
      savedMap.remove(normalizedProfileId);
    } else {
      savedMap[normalizedProfileId] = budgetIqd;
    }
    await _writeBudgetMap(prefs, savedMap);
    await prefs.remove(monthlyBudgetPrefsKey);
  } catch (_) {
    // Ignore persistence failures; value can still be used in-memory.
  }
}

Map<String, double> _readBudgetMap(SharedPreferences prefs) {
  final raw = prefs.getString(monthlyBudgetByProfilePrefsKey);
  if (raw == null || raw.isEmpty) {
    return <String, double>{};
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return <String, double>{};
    }
    final next = <String, double>{};
    for (final entry in decoded.entries) {
      final key = entry.key.toString().trim();
      final valueRaw = entry.value;
      if (key.isEmpty || valueRaw is! num) continue;
      final value = valueRaw.toDouble();
      if (value > 0) {
        next[key] = value;
      }
    }
    return next;
  } catch (_) {
    return <String, double>{};
  }
}

Future<void> _writeBudgetMap(
  SharedPreferences prefs,
  Map<String, double> budgetMap,
) async {
  if (budgetMap.isEmpty) {
    await prefs.remove(monthlyBudgetByProfilePrefsKey);
    return;
  }
  await prefs.setString(monthlyBudgetByProfilePrefsKey, jsonEncode(budgetMap));
}
