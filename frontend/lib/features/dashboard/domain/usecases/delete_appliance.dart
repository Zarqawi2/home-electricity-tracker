import '../repositories/appliance_repository.dart';
import '../entities/appliance.dart';

class DeleteAppliance {
  DeleteAppliance(this.repository);

  final ApplianceRepository repository;

  Future<List<Appliance>> call(String id) {
    return repository.deleteAppliance(id);
  }
}
