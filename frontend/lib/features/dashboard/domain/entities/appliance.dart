class Appliance {
  const Appliance({
    required this.id,
    required this.name,
    required this.category,
    required this.powerW,
    required this.dailyUseHours,
    required this.isOn,
  });

  final String id;
  final String name;
  final String category;
  final double powerW;
  final double dailyUseHours;
  final bool isOn;

  double get dailyKwh => (powerW / 1000) * dailyUseHours;

  Appliance copyWith({
    String? id,
    String? name,
    String? category,
    double? powerW,
    double? dailyUseHours,
    bool? isOn,
  }) {
    return Appliance(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      powerW: powerW ?? this.powerW,
      dailyUseHours: dailyUseHours ?? this.dailyUseHours,
      isOn: isOn ?? this.isOn,
    );
  }
}
