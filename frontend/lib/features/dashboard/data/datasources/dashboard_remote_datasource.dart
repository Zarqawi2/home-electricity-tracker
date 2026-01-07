import 'package:intl/intl.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/view_mode.dart';
import '../models/dashboard_dto.dart';

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._client);

  final DioClient _client;

  Future<DashboardDto> fetchDashboard({
    required DateTime date,
    required DashboardViewMode mode,
  }) async {
    final formatter = DateFormat('yyyy-MM-dd');
    final response = await _client.dio.get(
      '/api/dashboard',
      queryParameters: {'date': formatter.format(date), 'mode': mode.name},
    );

    return DashboardDto.fromJson(response.data as Map<String, dynamic>);
  }
}
