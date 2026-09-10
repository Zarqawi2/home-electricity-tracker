import 'dart:math';

class ElectricityTariffTier {
  const ElectricityTariffTier({required this.toKwh, required this.rateIqd});

  final double? toKwh;
  final double rateIqd;
}

class ElectricityTariffProfile {
  const ElectricityTariffProfile({
    required this.id,
    required this.title,
    required this.description,
    required this.unitRateIqd,
    this.tiers = const <ElectricityTariffTier>[],
  });

  final String id;
  final String title;
  final String description;
  final int unitRateIqd;
  final List<ElectricityTariffTier> tiers;

  bool get isTiered => tiers.isNotEmpty;
}

class ElectricityTariffCatalog {
  ElectricityTariffCatalog._();

  static const household = ElectricityTariffProfile(
    id: 'household_tiered',
    title: 'ماڵی',
    description: 'نرخی پلەیی بۆ هاوبەشانی ماڵی',
    unitRateIqd: 72,
    tiers: <ElectricityTariffTier>[
      ElectricityTariffTier(toKwh: 400, rateIqd: 72),
      ElectricityTariffTier(toKwh: 800, rateIqd: 108),
      ElectricityTariffTier(toKwh: 1200, rateIqd: 175),
      ElectricityTariffTier(toKwh: 1600, rateIqd: 265),
      ElectricityTariffTier(toKwh: null, rateIqd: 350),
    ],
  );

  static const commercial = ElectricityTariffProfile(
    id: 'commercial',
    title: 'بازرگانی',
    description: 'نرخی یەکسان بۆ بازرگانی',
    unitRateIqd: 185,
  );

  static const largeIndustrial = ElectricityTariffProfile(
    id: 'large_industrial',
    title: 'پیشەسازی گەورە',
    description: 'نرخی یەکسان بۆ پیشەسازی گەورە',
    unitRateIqd: 125,
  );

  static const industrial = ElectricityTariffProfile(
    id: 'industrial',
    title: 'پیشەسازی',
    description: 'نرخی یەکسان بۆ پیشەسازی',
    unitRateIqd: 160,
  );

  static const governmental = ElectricityTariffProfile(
    id: 'governmental',
    title: 'میری',
    description: 'نرخی یەکسان بۆ بەشە میرییەکان',
    unitRateIqd: 160,
  );

  static const agricultural = ElectricityTariffProfile(
    id: 'agricultural',
    title: 'کشتوکاڵی',
    description: 'نرخی یەکسان بۆ کشتوکاڵی',
    unitRateIqd: 60,
  );

  static const List<ElectricityTariffProfile> values =
      <ElectricityTariffProfile>[
        household,
        commercial,
        largeIndustrial,
        industrial,
        governmental,
        agricultural,
      ];

  static const ElectricityTariffProfile defaultProfile = household;
}

ElectricityTariffProfile tariffProfileById(String? id) {
  if (id == null || id.isEmpty) {
    return ElectricityTariffCatalog.defaultProfile;
  }
  for (final profile in ElectricityTariffCatalog.values) {
    if (profile.id == id) {
      return profile;
    }
  }
  return ElectricityTariffCatalog.defaultProfile;
}

double calculateElectricityCostIqd({
  required double kwh,
  required ElectricityTariffProfile profile,
}) {
  final usage = kwh.isFinite ? max(0.0, kwh) : 0.0;
  if (usage <= 0) {
    return 0;
  }

  if (!profile.isTiered) {
    return usage * profile.unitRateIqd;
  }

  var remaining = usage;
  var lowerBound = 0.0;
  var cost = 0.0;

  for (final tier in profile.tiers) {
    final upper = tier.toKwh ?? double.infinity;
    final band = upper - lowerBound;
    final applied = min(remaining, band);
    if (applied <= 0) {
      lowerBound = upper;
      continue;
    }
    cost += applied * tier.rateIqd;
    remaining -= applied;
    lowerBound = upper;
    if (remaining <= 0) {
      break;
    }
  }

  return cost;
}

String tariffRateLabel(ElectricityTariffProfile profile) {
  if (!profile.isTiered) {
    return '${profile.unitRateIqd} دینار / kWh';
  }
  final rates = profile.tiers
      .map((tier) => tier.rateIqd)
      .where((value) => value > 0)
      .toList();
  if (rates.isEmpty) {
    return 'پلەیی';
  }
  rates.sort();
  return 'پلەیی (${rates.first.toInt()}-${rates.last.toInt()} دینار / kWh)';
}
