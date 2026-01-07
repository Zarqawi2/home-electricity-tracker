import '../../domain/entities/appliance.dart';
import '../../domain/repositories/appliance_repository.dart';
import '../datasources/appliance_remote_datasource.dart';

class ApplianceRepositoryImpl implements ApplianceRepository {
  ApplianceRepositoryImpl(this._remoteDataSource);

  final ApplianceRemoteDataSource _remoteDataSource;

  @override
  Future<List<Appliance>> fetchAppliances() async {
    final dtos = await _remoteDataSource.listAppliances();
    return dtos.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Appliance>> toggleAppliance(String id) async {
    final dtos = await _remoteDataSource.toggleAppliance(id);
    return dtos.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Appliance>> addAppliance({
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    bool isOn = true,
  }) async {
    final dtos = await _remoteDataSource.createAppliance(
      name: name,
      category: category,
      powerW: powerW,
      dailyUseHours: dailyUseHours,
      isOn: isOn,
    );
    return dtos.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Appliance>> deleteAppliance(String id) async {
    final dtos = await _remoteDataSource.deleteAppliance(id);
    return dtos.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<Appliance>> updateAppliance(
    String id, {
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    final dtos = await _remoteDataSource.updateAppliance(
      id: id,
      name: name,
      category: category,
      powerW: powerW,
      dailyUseHours: dailyUseHours,
      isOn: isOn,
    );
    return dtos.map((e) => e.toDomain()).toList();
  }
}
