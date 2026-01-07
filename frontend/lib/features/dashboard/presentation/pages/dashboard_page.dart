import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/appliance_breakdown.dart';
import '../../domain/entities/chart_point.dart';
import '../viewmodels/appliance_view_model.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/view_mode_toggle.dart';
import 'widgets/snackbar.dart';
import 'sections/appliances_section.dart';
import 'sections/charts_section.dart';
import 'sections/grid_calculator.dart';
import 'sections/metrics_section.dart';
import 'sections/tips_section.dart';
import 'utils/appliance_actions.dart';
import 'utils/tips_localization.dart';
import 'widgets/status_banner.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String? _lastErrorMessage;
  ApplianceActions? _actions;
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<DashboardUIState>(dashboardProvider, (prev, next) {
      final message = next.error;
      if (message != null && message != _lastErrorMessage && mounted) {
        _lastErrorMessage = message;
        showSnack(context, message, variant: SnackBarVariant.error);
      }
    });

    ref.listen<ApplianceState>(appliancesProvider, (prev, next) {
      final message = next.error;
      if (message != null && message != _lastErrorMessage && mounted) {
        _lastErrorMessage = message;
        showSnack(context, message, variant: SnackBarVariant.error);
      }
    });

    _actions ??= ApplianceActions(context: context, ref: ref);

    final dashboardState = ref.watch(dashboardProvider);
    final appliancesState = ref.watch(appliancesProvider);
    final data = dashboardState.data;
    final summary = data?.summary;
    final List<ApplianceBreakdown> breakdown =
        data?.breakdown ?? <ApplianceBreakdown>[];
    final List<ChartPoint> chartPoints = data?.chartPoints ?? <ChartPoint>[];
    final Map<String, double> applianceCosts =
        data?.applianceMonthlyCosts ?? <String, double>{};
    final tips = localizedTips(data?.tips ?? const []);

    final dailyChangeText = summary != null
        ? '${summary.dailyChangePct >= 0 ? '+' : ''}${summary.dailyChangePct.toStringAsFixed(1)}% بەراورد بە ڕۆژی پێشوو'
        : '+0.0% بەراورد بە ڕۆژی پێشوو';
    final costChangeText = summary != null
        ? '${summary.costChangePct >= 0 ? '+' : ''}${summary.costChangePct.toStringAsFixed(1)}% بەراورد بە ماوەی پێشوو'
        : '+0.0% بەراورد بە ماوەی پێشوو';

    final mediaQuery = MediaQuery.of(context);
    const spacing = 12.0;
    const maxContentWidth = 1280.0;
    final safeWidth = mediaQuery.size.width.clamp(0.0, maxContentWidth);
    final contentWidth = (safeWidth - 32).clamp(0.0, double.infinity);
    final grid = GridCalculator(
      contentWidth: contentWidth,
      spacing: spacing,
      applianceSlack: 64,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 120,
              collapsedHeight: 120,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              automaticallyImplyLeading: false,
              surfaceTintColor: Theme.of(context).colorScheme.surface,
              flexibleSpace: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: DashboardHeader(
                    onRefresh: _onRefresh,
                    isRefreshing: _isRefreshing,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: maxContentWidth),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dashboardState.error == 'پەیوەندی ئینتەرنێت نییە' ||
                            appliancesState.error ==
                                'پەیوەندی ئینتەرنێت نییە') ...[
                          const SizedBox(height: 8),
                          const StatusBanner(
                            message:
                                'پەیوەندی ئینتەرنێت نییە. تۆڕەکەت بپشکنە و دووبارە هەوڵ بدە.',
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 16),
                        MetricsSection(
                          grid: grid,
                          summary: summary,
                          dailyChangeText: dailyChangeText,
                          costChangeText: costChangeText,
                          spacing: spacing,
                        ),
                        const SizedBox(height: 16),
                        ViewModeToggle(
                          mode: dashboardState.viewMode,
                          onChanged: (mode) => ref
                              .read(dashboardProvider.notifier)
                              .setViewMode(mode),
                        ),
                        const SizedBox(height: 16),
                        ChartsSection(
                          dashboardState: dashboardState,
                          chartPoints: chartPoints,
                          breakdown: breakdown,
                          grid: grid,
                          spacing: spacing,
                        ),
                        const SizedBox(height: 16),
                        AppliancesSection(
                          grid: grid,
                          appliances: appliancesState.items,
                          applianceCosts: applianceCosts,
                          spacing: spacing,
                          isLoading: appliancesState.isLoading,
                          errorMessage: appliancesState.error,
                          onAdd: _actions!.add,
                          onToggle: _actions!.toggle,
                          onEdit: _actions!.edit,
                          onDelete: _actions!.delete,
                        ),
                        const SizedBox(height: 16),
                        TipsSection(tips: tips),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    // Allow showing repeat errors on explicit refresh attempts.
    _lastErrorMessage = null;
    _actions ??= ApplianceActions(context: context, ref: ref);
    await _actions!.refreshAll();
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
}
