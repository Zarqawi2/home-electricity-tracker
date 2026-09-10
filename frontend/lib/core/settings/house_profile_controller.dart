import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const houseProfilesPrefsKey = 'house_profiles_v1';
const selectedHouseProfilePrefsKey = 'selected_house_profile_v1';
const defaultHouseProfileId = 'house_default';
const defaultHouseProfileName = 'ماڵی سەرەکی';

class HouseProfile {
  const HouseProfile({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  static HouseProfile fromJson(Map<String, dynamic> json) {
    return HouseProfile(
      id: json['id']?.toString().trim() ?? '',
      name: json['name']?.toString().trim() ?? '',
    );
  }
}

class HouseProfileState {
  const HouseProfileState({
    required this.profiles,
    required this.selectedProfileId,
    required this.isLoading,
  });

  final List<HouseProfile> profiles;
  final String selectedProfileId;
  final bool isLoading;

  HouseProfile get selectedProfile {
    for (final profile in profiles) {
      if (profile.id == selectedProfileId) {
        return profile;
      }
    }
    return profiles.isNotEmpty
        ? profiles.first
        : const HouseProfile(
            id: defaultHouseProfileId,
            name: defaultHouseProfileName,
          );
  }

  HouseProfileState copyWith({
    List<HouseProfile>? profiles,
    String? selectedProfileId,
    bool? isLoading,
  }) {
    return HouseProfileState(
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId ?? this.selectedProfileId,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  static HouseProfileState initial() {
    return const HouseProfileState(
      profiles: <HouseProfile>[
        HouseProfile(id: defaultHouseProfileId, name: defaultHouseProfileName),
      ],
      selectedProfileId: defaultHouseProfileId,
      isLoading: true,
    );
  }
}

final houseProfileProvider =
    StateNotifierProvider<HouseProfileController, HouseProfileState>(
      (ref) => HouseProfileController(),
    );

class HouseProfileController extends StateNotifier<HouseProfileState> {
  HouseProfileController() : super(HouseProfileState.initial()) {
    unawaited(_load());
  }

  static const Uuid _uuid = Uuid();

  Future<void> _load() async {
    final snapshot = await _readProfileSnapshot();
    state = state.copyWith(
      profiles: snapshot.profiles,
      selectedProfileId: snapshot.selectedProfileId,
      isLoading: false,
    );
  }

  Future<void> selectProfile(String id) async {
    final targetId = id.trim();
    if (targetId.isEmpty) return;
    final exists = state.profiles.any((profile) => profile.id == targetId);
    if (!exists) return;

    state = state.copyWith(selectedProfileId: targetId);
    await _saveSnapshot(
      profiles: state.profiles,
      selectedProfileId: state.selectedProfileId,
    );
  }

  Future<void> addProfile(String rawName) async {
    final name = _sanitizeName(rawName);
    if (name.isEmpty) return;

    final next = <HouseProfile>[
      ...state.profiles,
      HouseProfile(id: 'house_${_uuid.v4()}', name: name),
    ];
    state = state.copyWith(profiles: next, selectedProfileId: next.last.id);
    await _saveSnapshot(
      profiles: state.profiles,
      selectedProfileId: state.selectedProfileId,
    );
  }

  Future<void> renameProfile({
    required String id,
    required String rawName,
  }) async {
    final targetId = id.trim();
    final name = _sanitizeName(rawName);
    if (targetId.isEmpty || name.isEmpty) return;

    final next = state.profiles
        .map(
          (profile) => profile.id == targetId
              ? HouseProfile(id: profile.id, name: name)
              : profile,
        )
        .toList(growable: false);
    state = state.copyWith(profiles: next);
    await _saveSnapshot(
      profiles: state.profiles,
      selectedProfileId: state.selectedProfileId,
    );
  }

  Future<bool> deleteProfile(String id) async {
    final targetId = id.trim();
    if (targetId.isEmpty || state.profiles.length <= 1) {
      return false;
    }

    final next = state.profiles
        .where((profile) => profile.id != targetId)
        .toList(growable: false);
    if (next.isEmpty) {
      return false;
    }

    final nextSelected = next.any((item) => item.id == state.selectedProfileId)
        ? state.selectedProfileId
        : next.first.id;
    state = state.copyWith(profiles: next, selectedProfileId: nextSelected);
    await _saveSnapshot(
      profiles: state.profiles,
      selectedProfileId: state.selectedProfileId,
    );
    return true;
  }
}

class _ProfileSnapshot {
  const _ProfileSnapshot({
    required this.profiles,
    required this.selectedProfileId,
  });

  final List<HouseProfile> profiles;
  final String selectedProfileId;
}

Future<List<HouseProfile>> readSavedHouseProfiles() async {
  final snapshot = await _readProfileSnapshot();
  return snapshot.profiles;
}

Future<String> readSelectedHouseProfileId() async {
  final snapshot = await _readProfileSnapshot();
  return snapshot.selectedProfileId;
}

Future<HouseProfile> readSelectedHouseProfile() async {
  final snapshot = await _readProfileSnapshot();
  for (final profile in snapshot.profiles) {
    if (profile.id == snapshot.selectedProfileId) {
      return profile;
    }
  }
  return snapshot.profiles.first;
}

Future<void> ensureHouseProfilesInitialized() async {
  final snapshot = await _readProfileSnapshot();
  await _saveSnapshot(
    profiles: snapshot.profiles,
    selectedProfileId: snapshot.selectedProfileId,
  );
}

String _sanitizeName(String raw) {
  final collapsed = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.length <= 28) {
    return collapsed;
  }
  return collapsed.substring(0, 28).trimRight();
}

Future<_ProfileSnapshot> _readProfileSnapshot() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(houseProfilesPrefsKey);
    final selectedRaw = prefs.getString(selectedHouseProfilePrefsKey);
    final selectedId = selectedRaw?.trim() ?? '';
    final decoded = _decodeProfiles(raw);

    final profiles = _normalizeProfiles(decoded);
    final hasSelected = profiles.any((profile) => profile.id == selectedId);
    final effectiveSelected = hasSelected ? selectedId : profiles.first.id;
    return _ProfileSnapshot(
      profiles: profiles,
      selectedProfileId: effectiveSelected,
    );
  } catch (_) {
    return const _ProfileSnapshot(
      profiles: <HouseProfile>[
        HouseProfile(id: defaultHouseProfileId, name: defaultHouseProfileName),
      ],
      selectedProfileId: defaultHouseProfileId,
    );
  }
}

List<HouseProfile> _decodeProfiles(String? raw) {
  if (raw == null || raw.isEmpty) {
    return const <HouseProfile>[];
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const <HouseProfile>[];
    }

    return decoded
        .whereType<Map>()
        .map((entry) => HouseProfile.fromJson(entry.cast<String, dynamic>()))
        .toList(growable: false);
  } catch (_) {
    return const <HouseProfile>[];
  }
}

List<HouseProfile> _normalizeProfiles(List<HouseProfile> raw) {
  final seen = <String>{};
  final normalized = <HouseProfile>[];
  for (final profile in raw) {
    final id = profile.id.trim();
    final name = _sanitizeName(profile.name);
    if (id.isEmpty || name.isEmpty || seen.contains(id)) {
      continue;
    }
    seen.add(id);
    normalized.add(HouseProfile(id: id, name: name));
  }
  if (normalized.isEmpty) {
    return const <HouseProfile>[
      HouseProfile(id: defaultHouseProfileId, name: defaultHouseProfileName),
    ];
  }
  return normalized;
}

Future<void> _saveSnapshot({
  required List<HouseProfile> profiles,
  required String selectedProfileId,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final normalizedProfiles = _normalizeProfiles(profiles);
    final hasSelected = normalizedProfiles.any(
      (profile) => profile.id == selectedProfileId,
    );
    final effectiveSelected = hasSelected
        ? selectedProfileId
        : normalizedProfiles.first.id;
    await prefs.setString(
      houseProfilesPrefsKey,
      jsonEncode(
        normalizedProfiles.map((profile) => profile.toJson()).toList(),
      ),
    );
    await prefs.setString(selectedHouseProfilePrefsKey, effectiveSelected);
  } catch (_) {
    // Keep in-memory state even when persistence fails.
  }
}
