import '../models/dashboard_dto.dart';
import 'local_appliance_store.dart';

class ApplianceRemoteDataSource {
  ApplianceRemoteDataSource(this._store);

  final LocalApplianceStore _store;

  Future<List<ApplianceDto>> listAppliances() async {
    final data = await _store.listAppliances();
    return data.map(ApplianceDto.fromJson).toList();
  }

  Future<List<ApplianceDto>> createAppliance({
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    final data = await _store.createAppliance(
      name: name,
      category: category,
      powerW: powerW,
      dailyUseHours: dailyUseHours,
      isOn: isOn,
    );
    return data.map(ApplianceDto.fromJson).toList();
  }

  Future<List<ApplianceDto>> updateAppliance({
    required String id,
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    final data = await _store.updateAppliance(
      id: id,
      name: name,
      category: category,
      powerW: powerW,
      dailyUseHours: dailyUseHours,
      isOn: isOn,
    );
    return data.map(ApplianceDto.fromJson).toList();
  }

  Future<List<ApplianceDto>> deleteAppliance(String id) async {
    final data = await _store.deleteAppliance(id);
    return data.map(ApplianceDto.fromJson).toList();
  }

  Future<List<ApplianceDto>> toggleAppliance(String id) async {
    final data = await _store.toggleAppliance(id);
    return data.map(ApplianceDto.fromJson).toList();
  }
}
