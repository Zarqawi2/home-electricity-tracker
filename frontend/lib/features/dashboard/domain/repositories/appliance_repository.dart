import '../entities/appliance.dart';

abstract class ApplianceRepository {
  Future<List<Appliance>> fetchAppliances();
  Future<List<Appliance>> toggleAppliance(String id);
  Future<List<Appliance>> addAppliance({
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    bool isOn = true,
  });
  Future<List<Appliance>> deleteAppliance(String id);
  Future<List<Appliance>> updateAppliance(
    String id, {
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  });
}
