import '../../domain/entities/dashboard_data.dart';
import '../../domain/entities/view_mode.dart';

class DashboardUIState {
  const DashboardUIState({
    required this.viewMode,
    required this.isLoading,
    this.data,
    this.error,
    required this.date,
  });

  final DashboardViewMode viewMode;
  final bool isLoading;
  final DashboardData? data;
  final String? error;
  final DateTime date;

  DashboardUIState copyWith({
    DashboardViewMode? viewMode,
    bool? isLoading,
    DashboardData? data,
    String? error,
    DateTime? date,
  }) {
    return DashboardUIState(
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
      date: date ?? this.date,
    );
  }

  static DashboardUIState initial() => DashboardUIState(
        viewMode: DashboardViewMode.daily,
        isLoading: true,
        data: null,
        error: null,
        date: DateTime.now(),
      );
}
