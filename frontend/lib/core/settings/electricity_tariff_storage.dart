import 'package:shared_preferences/shared_preferences.dart';

import 'electricity_tariff.dart';

const electricityTariffProfilePrefsKey = 'electricity_tariff_profile_v1';

Future<ElectricityTariffProfile> readSavedElectricityTariffProfile() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.getString(electricityTariffProfilePrefsKey);
    return tariffProfileById(rawId);
  } catch (_) {
    return ElectricityTariffCatalog.defaultProfile;
  }
}

Future<void> saveElectricityTariffProfile(String profileId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final safeProfileId = tariffProfileById(profileId).id;
    await prefs.setString(electricityTariffProfilePrefsKey, safeProfileId);
  } catch (_) {
    // Ignore persistence failures; state still updates in-memory.
  }
}
