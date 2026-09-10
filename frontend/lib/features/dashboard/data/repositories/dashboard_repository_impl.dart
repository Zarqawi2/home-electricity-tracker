import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._remoteDataSource);

  final DashboardRemoteDataSource _remoteDataSource;

  @override
  Future<DashboardData> fetchDashboard({
    required DateTime date,
    required DashboardViewMode mode,
  }) async {
    final dto = await _remoteDataSource.fetchDashboard(date: date, mode: mode);
    return dto.toDomain();
  }

  @override
  Future<void> setTodayOutageMinutes(int minutes) {
    return _remoteDataSource.setTodayOutageMinutes(minutes);
  }

  @override
  Future<void> startOutageTracking() {
    return _remoteDataSource.startOutageTracking();
  }

  @override
  Future<int> stopOutageTracking() {
    return _remoteDataSource.stopOutageTracking();
  }
}
