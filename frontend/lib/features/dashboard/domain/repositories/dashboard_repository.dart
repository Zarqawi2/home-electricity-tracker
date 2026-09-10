import '../entities/dashboard_data.dart';
import '../entities/view_mode.dart';

abstract class DashboardRepository {
  Future<DashboardData> fetchDashboard({
    required DateTime date,
    required DashboardViewMode mode,
  });

  Future<void> setTodayOutageMinutes(int minutes);
  Future<void> startOutageTracking();
  Future<int> stopOutageTracking();
}
