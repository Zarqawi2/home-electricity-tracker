
import '../../../../core/network/dio_client.dart';
import '../models/dashboard_dto.dart';

class ApplianceRemoteDataSource {
  ApplianceRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<ApplianceDto>> listAppliances() async {
    final response = await _client.dio.get('/api/appliances');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List<dynamic>)
          .map((e) => ApplianceDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((e) => ApplianceDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ApplianceDto>> createAppliance({
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    await _client.dio.post(
      '/api/appliances',
      data: {
        'name': name,
        'category': category,
        'power_watts': powerW,
        'daily_use_hours': dailyUseHours,
        'is_on': isOn,
      },
    );
    return listAppliances();
  }

  Future<List<ApplianceDto>> updateAppliance({
    required String id,
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    await _client.dio.put(
      '/api/appliances/$id',
      data: {
        'name': name,
        'category': category,
        'power_watts': powerW,
        'daily_use_hours': dailyUseHours,
        'is_on': isOn,
      },
    );
    return listAppliances();
  }

  Future<List<ApplianceDto>> deleteAppliance(String id) async {
    await _client.dio.delete('/api/appliances/$id');
    return listAppliances();
  }

  Future<List<ApplianceDto>> toggleAppliance(String id) async {
    await _client.dio.patch('/api/appliances/$id/toggle');
    return listAppliances();
  }
}
