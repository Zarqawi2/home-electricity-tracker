import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/providers.dart';
import '../../data/datasources/appliance_remote_datasource.dart';
import '../../data/repositories/appliance_repository_impl.dart';
import '../../domain/entities/appliance.dart';
import '../../domain/repositories/appliance_repository.dart';
import '../../domain/usecases/add_appliance.dart';
import '../../domain/usecases/delete_appliance.dart';
import '../../domain/usecases/toggle_appliance.dart';
import '../../domain/usecases/update_appliance.dart';

final applianceRemoteDataSourceProvider = Provider<ApplianceRemoteDataSource>(
  (ref) => ApplianceRemoteDataSource(ref.watch(dioClientProvider)),
);

final applianceRepositoryProvider = Provider<ApplianceRepository>((ref) {
  return ApplianceRepositoryImpl(ref.watch(applianceRemoteDataSourceProvider));
});

final addApplianceUseCaseProvider = Provider<AddAppliance>((ref) {
  return AddAppliance(ref.watch(applianceRepositoryProvider));
});

final updateApplianceUseCaseProvider = Provider<UpdateAppliance>((ref) {
  return UpdateAppliance(ref.watch(applianceRepositoryProvider));
});

final toggleApplianceUseCaseProvider = Provider<ToggleAppliance>((ref) {
  return ToggleAppliance(ref.watch(applianceRepositoryProvider));
});

final deleteApplianceUseCaseProvider = Provider<DeleteAppliance>((ref) {
  return DeleteAppliance(ref.watch(applianceRepositoryProvider));
});

class ApplianceState {
  const ApplianceState({
    required this.items,
    required this.isLoading,
    this.error,
  });

  final List<Appliance> items;
  final bool isLoading;
  final String? error;

  ApplianceState copyWith({
    List<Appliance>? items,
    bool? isLoading,
    String? error,
  }) {
    return ApplianceState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static ApplianceState initial() =>
      const ApplianceState(items: [], isLoading: true);
}

class ApplianceViewModel extends StateNotifier<ApplianceState> {
  ApplianceViewModel({
    required ApplianceRepository repository,
    required AddAppliance addAppliance,
    required UpdateAppliance updateAppliance,
    required ToggleAppliance toggleAppliance,
    required DeleteAppliance deleteAppliance,
    required Connectivity connectivity,
    required DioClient dioClient,
  })  : _repository = repository,
        _addAppliance = addAppliance,
        _updateAppliance = updateAppliance,
        _toggleAppliance = toggleAppliance,
        _deleteAppliance = deleteAppliance,
        _connectivity = connectivity,
        _dioClient = dioClient,
        super(ApplianceState.initial()) {
    load();
  }

  final ApplianceRepository _repository;
  final AddAppliance _addAppliance;
  final UpdateAppliance _updateAppliance;
  final ToggleAppliance _toggleAppliance;
  final DeleteAppliance _deleteAppliance;
  final Connectivity _connectivity;
  final DioClient _dioClient;

  Future<void> load() async {
    try {
      final status = await _connectivity.checkConnectivity();
      if (status == ConnectivityResult.none) {
        state = state.copyWith(
          isLoading: false,
          error: 'پەیوەندی ئینتەرنێت نییە',
        );
        return;
      }
      final items = await _repository.fetchAppliances();
      state = state.copyWith(items: items, isLoading: false, error: null);
    } catch (e) {
      final message = e is DioException
          ? _dioClient.mapDioError(e)
          : 'هێنانی ئامێرەکان سەرکەوتوو نەبوو';
      state = state.copyWith(isLoading: false, error: message);
    }
  }

  Future<bool> toggle(String id) async {
    final previous = state.items;
    try {
      final status = await _connectivity.checkConnectivity();
      if (status == ConnectivityResult.none) {
        state = state.copyWith(error: 'پەیوەندی ئینتەرنێت نییە');
        return false;
      }
      final updated = await _toggleAppliance(id);
      state = state.copyWith(items: updated, isLoading: false, error: null);
      return true;
    } catch (e) {
      final message = e is DioException
          ? _dioClient.mapDioError(e)
          : 'نوێکردنەوەی ئامێر سەرکەوتوو نەبوو';
      state = state.copyWith(items: previous, isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> add({
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    bool isOn = true,
  }) async {
    try {
      final status = await _connectivity.checkConnectivity();
      if (status == ConnectivityResult.none) {
        state = state.copyWith(error: 'پەیوەندی ئینتەرنێت نییە');
        return false;
      }
      final items = await _addAppliance(
        name: name,
        category: category,
        powerW: powerW,
        dailyUseHours: dailyUseHours,
        isOn: isOn,
      );
      state = state.copyWith(items: items, isLoading: false, error: null);
      return true;
    } catch (e) {
      final message = e is DioException
          ? _dioClient.mapDioError(e)
          : 'هەڵگرتنی ئامێر سەرکەوتوو نەبوو';
      state = state.copyWith(error: message);
      return false;
    }
  }

  Future<bool> delete(String id) async {
    final previous = state.items;
    try {
      final status = await _connectivity.checkConnectivity();
      if (status == ConnectivityResult.none) {
        state = state.copyWith(error: 'پەیوەندی ئینتەرنێت نییە');
        return false;
      }
      final items = await _deleteAppliance(id);
      state = state.copyWith(items: items, isLoading: false, error: null);
      return true;
    } catch (e) {
      final message = e is DioException
          ? _dioClient.mapDioError(e)
          : 'سڕینەوەی ئامێر سەرکەوتوو نەبوو';
      state = state.copyWith(items: previous, isLoading: false, error: message);
      return false;
    }
  }

  Future<bool> update({
    required String id,
    required String name,
    required String category,
    required double powerW,
    required double dailyUseHours,
    required bool isOn,
  }) async {
    try {
      final status = await _connectivity.checkConnectivity();
      if (status == ConnectivityResult.none) {
        state = state.copyWith(error: 'پەیوەندی ئینتەرنێت نییە');
        return false;
      }
      final items = await _updateAppliance(
        id: id,
        name: name,
        category: category,
        powerW: powerW,
        dailyUseHours: dailyUseHours,
        isOn: isOn,
      );
      state = state.copyWith(items: items, isLoading: false, error: null);
      return true;
    } catch (e) {
      final message = e is DioException
          ? _dioClient.mapDioError(e)
          : 'هەڵگرتنی ئامێر سەرکەوتوو نەبوو';
      state = state.copyWith(error: message);
      return false;
    }
  }

  Future<void> refresh() => load();
}

final appliancesProvider =
    StateNotifierProvider<ApplianceViewModel, ApplianceState>((ref) {
  return ApplianceViewModel(
    repository: ref.watch(applianceRepositoryProvider),
    addAppliance: ref.watch(addApplianceUseCaseProvider),
    updateAppliance: ref.watch(updateApplianceUseCaseProvider),
    toggleAppliance: ref.watch(toggleApplianceUseCaseProvider),
    deleteAppliance: ref.watch(deleteApplianceUseCaseProvider),
    connectivity: ref.watch(connectivityProvider),
    dioClient: ref.watch(dioClientProvider),
  );
});
