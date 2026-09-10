import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/datasources/local_appliance_store.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../viewmodels/dashboard_state.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(LocalApplianceStore()),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

class DashboardViewModel extends StateNotifier<DashboardUIState> {
  DashboardViewModel({required DashboardRepository repository})
    : _repository = repository,
      super(DashboardUIState.initial()) {
    fetch();
  }

  final DashboardRepository _repository;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.fetchDashboard(
        date: state.date,
        mode: state.viewMode,
      );
      state = state.copyWith(data: data, isLoading: false, error: null);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data.',
      );
    }
  }

  Future<void> refresh() async {
    await fetch();
  }

  Future<void> setViewMode(DashboardViewMode mode) async {
    state = state.copyWith(viewMode: mode);
    await fetch();
  }

  Future<void> setTodayOutageMinutes(int minutes) async {
    try {
      await _repository.setTodayOutageMinutes(minutes);
      await fetch();
    } catch (_) {
      state = state.copyWith(
        error: 'پاشەکەوتکردنی کاتی قطع بوون سەرکەوتوو نەبوو.',
      );
    }
  }

  Future<void> startOutageTracking() async {
    try {
      await _repository.startOutageTracking();
      await fetch();
    } catch (_) {
      state = state.copyWith(
        error: 'دەستپێکردنی تۆمارکردنی قەطعبوون سەرکەوتوو نەبوو.',
      );
    }
  }

  Future<int> stopOutageTracking() async {
    try {
      final minutes = await _repository.stopOutageTracking();
      await fetch();
      return minutes;
    } catch (_) {
      state = state.copyWith(
        error: 'وەستاندنی تۆمارکردنی قەطعبوون سەرکەوتوو نەبوو.',
      );
      return 0;
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardUIState>((ref) {
      return DashboardViewModel(
        repository: ref.watch(dashboardRepositoryProvider),
      );
    });
