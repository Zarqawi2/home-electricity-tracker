import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/providers.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/entities/view_mode.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../viewmodels/dashboard_state.dart';

final dashboardRemoteDataSourceProvider = Provider<DashboardRemoteDataSource>(
  (ref) => DashboardRemoteDataSource(ref.watch(dioClientProvider)),
);

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardRemoteDataSourceProvider));
});

class DashboardViewModel extends StateNotifier<DashboardUIState> {
  DashboardViewModel({
    required DashboardRepository repository,
    required Connectivity connectivity,
    required DioClient dioClient,
  })  : _repository = repository,
        _connectivity = connectivity,
        _dioClient = dioClient,
        super(DashboardUIState.initial()) {
    fetch();
  }

  final DashboardRepository _repository;
  final Connectivity _connectivity;
  final DioClient _dioClient;

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final status = await _connectivity.checkConnectivity();
      if (status == ConnectivityResult.none) {
        state = state.copyWith(
          isLoading: false,
          error: 'پەیوەندی ئینتەرنێت نییە',
        );
        return;
      }
      final data = await _repository.fetchDashboard(
        date: state.date,
        mode: state.viewMode,
      );
      state = state.copyWith(data: data, isLoading: false, error: null);
    } catch (e) {
      final message = e is DioException
          ? _dioClient.mapDioError(e)
          : 'بارکردنی داشبۆرد سەرکەوتوو نەبوو';
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<void> refresh() async {
    await fetch();
  }

  Future<void> setViewMode(DashboardViewMode mode) async {
    state = state.copyWith(viewMode: mode);
    await fetch();
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardViewModel, DashboardUIState>((ref) {
  return DashboardViewModel(
    repository: ref.watch(dashboardRepositoryProvider),
    connectivity: ref.watch(connectivityProvider),
    dioClient: ref.watch(dioClientProvider),
  );
});
