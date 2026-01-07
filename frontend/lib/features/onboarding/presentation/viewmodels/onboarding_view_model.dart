import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks whether onboarding has been completed; used by router for redirects.
final onboardingSeenNotifier = ValueNotifier<bool>(false);

class OnboardingState {
  const OnboardingState({
    required this.pageIndex,
    required this.isCompleting,
  });

  final int pageIndex;
  final bool isCompleting;

  OnboardingState copyWith({
    int? pageIndex,
    bool? isCompleting,
  }) {
    return OnboardingState(
      pageIndex: pageIndex ?? this.pageIndex,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }

  static const initial = OnboardingState(pageIndex: 0, isCompleting: false);
}

class OnboardingViewModel extends StateNotifier<OnboardingState> {
  OnboardingViewModel() : super(OnboardingState.initial);

  void setPage(int index) {
    state = state.copyWith(pageIndex: index);
  }

  void back() {
    if (state.pageIndex > 0) {
      state = state.copyWith(pageIndex: state.pageIndex - 1);
    }
  }

  Future<bool> next(int totalPages) async {
    if (state.pageIndex < totalPages - 1) {
      state = state.copyWith(pageIndex: state.pageIndex + 1);
      return false;
    }
    return await complete();
  }

  Future<bool> complete() async {
    state = state.copyWith(isCompleting: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      onboardingSeenNotifier.value = true;
      state = state.copyWith(isCompleting: false);
      return true;
    } catch (_) {
      state = state.copyWith(isCompleting: false);
      return false;
    }
  }
}

final onboardingViewModelProvider =
    StateNotifierProvider<OnboardingViewModel, OnboardingState>(
  (ref) => OnboardingViewModel(),
);
