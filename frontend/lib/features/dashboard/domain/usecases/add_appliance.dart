import '../entities/appliance.dart';
import '../repositories/appliance_repository.dart';

class AddAppliance {
  AddAppliance(this._repository);

  final ApplianceRepository _repository;

  Future<List<Appliance>> call({
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    bool isOn = true,
  }) {
    return _repository.addAppliance(
      name: name,
      category: category,
      powerW: powerW,
      dailyUseHours: dailyUseHours,
      isOn: isOn,
    );
  }
}
