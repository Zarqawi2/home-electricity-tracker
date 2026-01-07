import '../entities/appliance.dart';
import '../repositories/appliance_repository.dart';

class ToggleAppliance {
  const ToggleAppliance(this._repository);

  final ApplianceRepository _repository;

  Future<List<Appliance>> call(String id) {
    return _repository.toggleAppliance(id);
  }
}
