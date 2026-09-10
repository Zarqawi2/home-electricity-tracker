import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'electricity_tariff.dart';
import 'electricity_tariff_storage.dart';

final electricityTariffProfileProvider =
    StateNotifierProvider<
      ElectricityTariffProfileController,
      ElectricityTariffProfile
    >((ref) => ElectricityTariffProfileController());

class ElectricityTariffProfileController
    extends StateNotifier<ElectricityTariffProfile> {
  ElectricityTariffProfileController()
    : super(ElectricityTariffCatalog.defaultProfile) {
    unawaited(_loadProfile());
  }

  Future<void> _loadProfile() async {
    state = await readSavedElectricityTariffProfile();
  }

  Future<void> setProfile(ElectricityTariffProfile profile) async {
    state = tariffProfileById(profile.id);
    await saveElectricityTariffProfile(state.id);
  }
}
