import '../entities/appliance.dart';
import '../repositories/appliance_repository.dart';

class UpdateAppliance {
  UpdateAppliance(this._repository);

  final ApplianceRepository _repository;

  Future<List<Appliance>> call({
    required String id,
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) {
    return _repository.updateAppliance(
      id,
      name: name,
      category: category,
      powerW: powerW,
      dailyUseHours: dailyUseHours,
      isOn: isOn,
    );
  }
}
