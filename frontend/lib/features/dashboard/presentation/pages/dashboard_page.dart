import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../../../core/formatters/thousands_number_input_formatter.dart';
import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/settings/electricity_tariff.dart';
import '../../../../core/settings/electricity_tariff_controller.dart';
import '../../../../core/settings/house_profile_controller.dart';
import '../../../../core/settings/meter_cycle_storage.dart';
import '../../../../core/settings/monthly_budget_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog_shell.dart';
import '../../domain/entities/appliance_breakdown.dart';
import '../../domain/entities/chart_point.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../viewmodels/appliance_view_model.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/dashboard_state.dart';
import '../utils/dashboard_responsive.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_navigation.dart';
import '../widgets/dashboard_overview.dart';
import '../widgets/dashboard_workspace.dart';
import '../widgets/view_mode_toggle.dart';
import 'widgets/snackbar.dart';
import 'sections/appliances_section.dart';
import 'sections/charts_section.dart';
import 'sections/grid_calculator.dart';
import 'sections/tips_section.dart';
import 'utils/appliance_actions.dart';
import 'utils/tips_localization.dart';
import 'widgets/status_banner.dart';

enum _OutageAction { startTracking, stopTracking, manualEdit }

enum _CalculatorInputMode { directKwh, wattsHours, meterReading }

enum _BudgetHealth { normal, warning, critical, exceeded }

final NumberFormat _iqdWholeFormatter = NumberFormat.decimalPattern('en_US');
final NumberFormat _iqdRateFormatter = NumberFormat('#,##0.0', 'en_US');
final TextInputFormatter _budgetNumberInputFormatter =
    ThousandsNumberInputFormatter();
final TextInputFormatter _decimalNumberInputFormatter =
    FilteringTextInputFormatter.allow(RegExp(r'^\d*([.,]\d{0,3})?$'));
final TextInputFormatter _integerNumberInputFormatter =
    FilteringTextInputFormatter.digitsOnly;

const Color _dashboardSurface = Color(0xFFFFFFFF);
const Color _dashboardSubtleSurface = Color(0xFFF8FAFC);
const Color _dashboardBorder = Color(0xFFE2E8F0);
const Color _dashboardIcon = Color(0xFF1E293B);
const Color _dashboardMutedText = Color(0xFF64748B);
const Color _dashboardSelected = Color(0xFF2563EB);
const Color _dashboardSelectedSurface = Color(0xFFEFF6FF);

_BudgetHealth _budgetHealthForRatio(double ratio) {
  if (ratio >= 1) {
    return _BudgetHealth.exceeded;
  }
  if (ratio >= 0.9) {
    return _BudgetHealth.critical;
  }
  if (ratio >= 0.7) {
    return _BudgetHealth.warning;
  }
  return _BudgetHealth.normal;
}

String _budgetHealthLabel(_BudgetHealth health) {
  switch (health) {
    case _BudgetHealth.normal:
      return '\u0626\u0627\u0633\u0627\u06cc\u06cc';
    case _BudgetHealth.warning:
      return '\u0626\u0627\u06af\u0627\u062f\u0627\u0631\u06cc';
    case _BudgetHealth.critical:
      return '\u0645\u06d5\u062a\u0631\u0633\u06cc\u062f\u0627\u0631';
    case _BudgetHealth.exceeded:
      return '\u062a\u06ce\u067e\u06d5\u0695\u0628\u0648\u0648';
  }
}

class _DashboardStrings {
  const _DashboardStrings._();

  static const profileTitle =
      '\u067e\u0631\u06c6\u0641\u0627\u06cc\u0644\u06cc \u0645\u0627\u06b5';
  static const profileDialogSubtitle =
      '\u0647\u06d5\u0631 \u0645\u0627\u06b5\u06ce\u06a9 \u0626\u0627\u0645\u06ce\u0631 \u0648 \u062f\u0627\u062a\u0627\u06cc \u062a\u0627\u06cc\u0628\u06d5\u062a\u06cc \u062e\u06c6\u06cc \u0647\u06d5\u06cc\u06d5.';
  static const profileNameDialogSubtitle =
      '\u0647\u06d5\u0631 \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644 \u062a\u06d5\u0646\u0647\u0627 \u0626\u0627\u0645\u06ce\u0631\u06d5\u06a9\u0627\u0646\u06cc \u062e\u06c6\u06cc \u0647\u06d5\u06cc\u06d5.';
  static const profileNameLabel =
      '\u0646\u0627\u0648\u06cc \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644';
  static const profileListTitle =
      '\u0644\u06cc\u0633\u062a\u06cc \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644\u06d5\u06a9\u0627\u0646';
  static const add = '\u0632\u06cc\u0627\u062f\u06a9\u0631\u062f\u0646';
  static const rename =
      '\u06af\u06c6\u0695\u06cc\u0646\u06cc \u0646\u0627\u0648';
  static const delete = '\u0633\u0695\u06cc\u0646\u06d5\u0648\u06d5';
  static const selected = '\u0686\u0627\u0644\u0627\u06a9';
  static const choose = '\u0647\u06d5\u06b5\u0628\u0698\u06ce\u0631\u06d5';
  static const menuOptions =
      '\u0647\u06d5\u06b5\u0628\u0698\u0627\u0631\u062f\u06d5';
  static const requiredField =
      '\u062f\u0627\u0648\u0627\u06a9\u0631\u0627\u0648\u06d5';

  static const addProfileTitle =
      '\u0632\u06cc\u0627\u062f\u06a9\u0631\u062f\u0646\u06cc \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644\u06cc \u0645\u0627\u06b5';
  static const addProfileHint =
      '\u0646\u0627\u0648\u06cc \u0645\u0627\u06b5 \u0628\u0646\u0648\u0648\u0633\u06d5';
  static const renameProfileTitle =
      '\u06af\u06c6\u0695\u06cc\u0646\u06cc \u0646\u0627\u0648\u06cc \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644';
  static const renameProfileHint =
      '\u0646\u0627\u0648\u06cc \u0646\u0648\u06ce';
  static const save = '\u067e\u0627\u0634\u06d5\u06a9\u06d5\u0648\u062a';

  static const deleteProfileTitle =
      '\u0633\u0695\u06cc\u0646\u06d5\u0648\u06d5\u06cc \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644';
  static const cancel =
      '\u067e\u0627\u0634\u06af\u06d5\u0632\u0628\u0648\u0648\u0646\u06d5\u0648\u06d5';
  static const deleteConfirm = '\u0628\u0633\u0695\u06d5\u0648\u06d5';
  static const deleteBody =
      '\u0626\u06d5\u0645 \u06a9\u0627\u0631\u06d5 \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644\u06d5\u06a9\u06d5 \u062f\u06d5\u0633\u0695\u06ce\u062a\u06d5\u0648\u06d5. \u0626\u06d5\u06af\u06d5\u0631 \u062a\u06d5\u0646\u0647\u0627 \u06cc\u06d5\u06a9 \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644 \u0647\u06d5\u0628\u06ce\u062a\u060c \u0646\u0627\u062a\u0648\u0627\u0646\u0631\u06ce\u062a \u0628\u0633\u0695\u06ce\u062a\u06d5\u0648\u06d5.';

  static const switchedProfile =
      '\u067e\u0631\u06c6\u0641\u0627\u06cc\u0644\u06cc \u0645\u0627\u06b5 \u06af\u06c6\u0695\u062f\u0631\u0627.';
  static const profileAdded =
      '\u067e\u0631\u06c6\u0641\u0627\u06cc\u0644\u06cc \u0646\u0648\u06ce \u0632\u06cc\u0627\u062f\u06a9\u0631\u0627.';
  static const profileRenamed =
      '\u0646\u0627\u0648\u06cc \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644 \u0646\u0648\u06ce\u06a9\u0631\u0627\u06cc\u06d5\u0648\u06d5.';
  static const profileRenameFailed =
      '\u06af\u06c6\u0695\u06cc\u0646\u06cc \u0646\u0627\u0648 \u0633\u06d5\u0631\u06a9\u06d5\u0648\u062a\u0648\u0648 \u0646\u06d5\u0628\u0648\u0648. \u062f\u0648\u0648\u0628\u0627\u0631\u06d5 \u0647\u06d5\u0648\u06b5 \u0628\u062f\u06d5.';
  static const minOneProfileRequired =
      '\u06a9\u06d5\u0645\u062a\u0631\u06cc\u0646 \u06cc\u06d5\u06a9 \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644 \u067e\u06ce\u0648\u06cc\u0633\u062a\u06d5.';
  static const profileDeleted =
      '\u067e\u0631\u06c6\u0641\u0627\u06cc\u0644 \u0633\u0695\u0627\u06cc\u06d5\u0648\u06d5.';

  static String deleteProfileSubtitle(String name) =>
      '\u062f\u06b5\u0646\u06cc\u0627\u06cc \u0644\u06d5 \u0633\u0695\u06cc\u0646\u06d5\u0648\u06d5\u06cc "$name"\u061f';
}

class _DashboardResponsive {
  const _DashboardResponsive._();

  static bool isCompactDialog(MediaQueryData media) =>
      media.size.width < 430 || media.size.height < 720;

  static double profileManagerMaxWidth(MediaQueryData media) {
    final compact = media.size.width < 430;
    return compact
        ? (media.size.width - 20).clamp(280.0, 420.0).toDouble()
        : 480.0;
  }

  static double profileNameMaxWidth(MediaQueryData media, bool compact) {
    return compact
        ? (media.size.width - 16).clamp(300.0, 520.0).toDouble()
        : 520.0;
  }

  static double profileManagerContentHeight(
    MediaQueryData media,
    bool compact,
  ) {
    return (media.size.height -
            media.padding.top -
            media.padding.bottom -
            media.viewInsets.bottom -
            (compact ? 280 : 300))
        .clamp(220.0, 460.0)
        .toDouble();
  }

  static double profileNameContentHeight(MediaQueryData media, bool compact) {
    return (media.size.height -
            media.padding.top -
            media.padding.bottom -
            media.viewInsets.bottom -
            (compact ? 250 : 280))
        .clamp(88.0, 220.0)
        .toDouble();
  }
}

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with WidgetsBindingObserver {
  static const _appVersionLabel = '1.0.9 (10)';

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedSection = 0;
  bool _drawerOpen = false;
  late Future<List<MeterCycleRecord>> _meterHistory;
  String? _lastErrorMessage;
  ApplianceActions? _actions;
  bool _isRefreshing = false;
  bool _isLifecycleRefreshRunning = false;
  DateTime? _lastLifecycleRefreshAt;
  double? _monthlyBudgetIqd;
  bool _budgetLoaded = false;
  int _budgetLoadToken = 0;
  ProviderSubscription<DashboardUIState>? _dashboardErrorSub;
  ProviderSubscription<ApplianceState>? _applianceErrorSub;
  ProviderSubscription<HouseProfileState>? _houseProfileSub;

  @override
  void initState() {
    super.initState();
    _meterHistory = readSavedMeterCycleHistory();
    WidgetsBinding.instance.addObserver(this);
    _dashboardErrorSub = ref.listenManual<DashboardUIState>(
      dashboardProvider,
      _onDashboardStateChanged,
    );
    _applianceErrorSub = ref.listenManual<ApplianceState>(
      appliancesProvider,
      _onApplianceStateChanged,
    );
    _houseProfileSub = ref.listenManual<HouseProfileState>(
      houseProfileProvider,
      _onHouseProfileStateChanged,
    );
    final initialProfileId = ref.read(houseProfileProvider).selectedProfileId;
    unawaited(_loadSavedMonthlyBudget(initialProfileId));
  }

  @override
  void dispose() {
    _dashboardErrorSub?.close();
    _applianceErrorSub?.close();
    _houseProfileSub?.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshAfterBackgroundAction());
    }
  }

  void _onDashboardStateChanged(DashboardUIState? prev, DashboardUIState next) {
    final message = next.error;
    if (message != null && message != _lastErrorMessage && mounted) {
      _lastErrorMessage = message;
      showSnack(context, message, variant: SnackBarVariant.error);
    }
  }

  void _onApplianceStateChanged(ApplianceState? prev, ApplianceState next) {
    final message = next.error;
    if (message != null && message != _lastErrorMessage && mounted) {
      _lastErrorMessage = message;
      showSnack(context, message, variant: SnackBarVariant.error);
    }
  }

  void _onHouseProfileStateChanged(
    HouseProfileState? prev,
    HouseProfileState next,
  ) {
    final profileChanged = prev?.selectedProfileId != next.selectedProfileId;
    final finishedInitialLoad = (prev?.isLoading ?? true) && !next.isLoading;
    if (!profileChanged && !finishedInitialLoad) return;

    if (mounted) {
      setState(() {
        _budgetLoaded = false;
      });
    }
    unawaited(_loadSavedMonthlyBudget(next.selectedProfileId));
  }

  Future<void> _loadSavedMonthlyBudget(String profileId) async {
    final normalizedProfileId = profileId.trim();
    if (normalizedProfileId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _monthlyBudgetIqd = null;
        _budgetLoaded = true;
      });
      return;
    }

    final token = ++_budgetLoadToken;
    final savedBudget = await readSavedMonthlyBudgetIqdForProfile(
      normalizedProfileId,
    );
    if (!mounted) return;
    if (token != _budgetLoadToken) return;
    final selectedProfileId = ref.read(houseProfileProvider).selectedProfileId;
    if (selectedProfileId.trim() != normalizedProfileId) return;

    setState(() {
      _monthlyBudgetIqd = savedBudget;
      _budgetLoaded = true;
    });
  }

  Future<void> _saveMonthlyBudget({
    required String profileId,
    required double? budgetIqd,
  }) async {
    final normalizedProfileId = profileId.trim();
    if (normalizedProfileId.isEmpty) return;

    await saveMonthlyBudgetIqdForProfile(
      profileId: normalizedProfileId,
      budgetIqd: budgetIqd,
    );
    if (!mounted) return;
    final selectedProfileId = ref.read(houseProfileProvider).selectedProfileId;
    if (selectedProfileId.trim() != normalizedProfileId) return;

    setState(() {
      _monthlyBudgetIqd = budgetIqd;
      _budgetLoaded = true;
    });
  }

  void _disposeControllersAfterSheetClose(
    Iterable<TextEditingController> controllers,
  ) {
    // Some dialog/sheet dismiss animations can still read field controllers
    // for a short time after pop().
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      for (final controller in controllers) {
        try {
          controller.dispose();
        } catch (_) {
          // Ignore if already disposed elsewhere.
        }
      }
    });
  }

  Future<void> _refreshForProfileChange() async {
    await Future.wait([
      ref.read(appliancesProvider.notifier).refresh(),
      ref.read(dashboardProvider.notifier).refresh(),
    ]);
  }

  Future<void> _onSwitchHouseProfile(String profileId) async {
    await ref.read(houseProfileProvider.notifier).selectProfile(profileId);
    await _refreshForProfileChange();
    if (!mounted) return;
    showSnack(
      context,
      _DashboardStrings.switchedProfile,
      variant: SnackBarVariant.success,
    );
  }

  Future<void> _onAddHouseProfileTap() async {
    final name = await _showHouseProfileNameDialog(
      title: _DashboardStrings.addProfileTitle,
      actionLabel: _DashboardStrings.add,
      hintText: _DashboardStrings.addProfileHint,
    );
    if (name == null || name.trim().isEmpty) return;

    await ref.read(houseProfileProvider.notifier).addProfile(name);
    await _refreshForProfileChange();
    if (!mounted) return;
    showSnack(
      context,
      _DashboardStrings.profileAdded,
      variant: SnackBarVariant.success,
    );
  }

  Future<void> _onRenameHouseProfile(HouseProfile profile) async {
    try {
      final name = await _showHouseProfileNameDialog(
        title: _DashboardStrings.renameProfileTitle,
        actionLabel: _DashboardStrings.save,
        hintText: _DashboardStrings.renameProfileHint,
        initialValue: profile.name,
      );
      if (name == null || name.trim().isEmpty) return;

      await ref
          .read(houseProfileProvider.notifier)
          .renameProfile(id: profile.id, rawName: name);
      if (!mounted) return;
      showSnack(
        context,
        _DashboardStrings.profileRenamed,
        variant: SnackBarVariant.success,
      );
    } catch (_) {
      if (!mounted) return;
      showSnack(
        context,
        _DashboardStrings.profileRenameFailed,
        variant: SnackBarVariant.error,
      );
    }
  }

  Future<void> _onDeleteHouseProfile(HouseProfile profile) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AppDialogShell(
          title: _DashboardStrings.deleteProfileTitle,
          subtitle: _DashboardStrings.deleteProfileSubtitle(profile.name),
          icon: Icons.delete_outline_rounded,
          onClose: () => Navigator.of(ctx).pop(false),
          accentColor: _dashboardIcon,
          content: Text(
            _DashboardStrings.deleteBody,
            style: Theme.of(ctx).textTheme.bodyMedium,
            textDirection: TextDirection.rtl,
          ),
          actions: [
            AppButton(
              label: _DashboardStrings.cancel,
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            AppButton(
              label: _DashboardStrings.deleteConfirm,
              variant: AppButtonVariant.destructive,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );
    if (approved != true || !mounted) return;

    final success = await ref
        .read(houseProfileProvider.notifier)
        .deleteProfile(profile.id);
    if (!success) {
      if (!mounted) return;
      showSnack(
        context,
        _DashboardStrings.minOneProfileRequired,
        variant: SnackBarVariant.info,
      );
      return;
    }
    await _refreshForProfileChange();
    if (!mounted) return;
    showSnack(
      context,
      _DashboardStrings.profileDeleted,
      variant: SnackBarVariant.success,
    );
  }

  Future<String?> _showHouseProfileNameDialog({
    required String title,
    required String actionLabel,
    required String hintText,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    String? errorText;
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final media = MediaQuery.of(ctx);
          final compact = _DashboardResponsive.isCompactDialog(media);
          final keyboardInset = media.viewInsets.bottom;
          final maxContentHeight =
              _DashboardResponsive.profileNameContentHeight(media, compact);

          return StatefulBuilder(
            builder: (ctx, setLocalState) {
              return AppDialogShell(
                title: title,
                subtitle: _DashboardStrings.profileNameDialogSubtitle,
                icon: Icons.home_work_outlined,
                onClose: () => Navigator.of(ctx).pop(null),
                accentColor: _dashboardIcon,
                maxWidth: _DashboardResponsive.profileNameMaxWidth(
                  media,
                  compact,
                ),
                insetPadding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 20,
                  vertical: keyboardInset > 0 ? 6 : (compact ? 10 : 24),
                ),
                contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                actionPadding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                content: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxContentHeight),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: controller,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            maxLength: 28,
                            scrollPadding: EdgeInsets.only(
                              bottom: keyboardInset + 96,
                            ),
                            decoration: InputDecoration(
                              labelText: _DashboardStrings.profileNameLabel,
                              hintText: hintText,
                              errorText: errorText,
                              counterText: '',
                            ),
                            onChanged: (_) {
                              if (errorText != null) {
                                setLocalState(() => errorText = null);
                              }
                            },
                            onFieldSubmitted: (_) {
                              final value = controller.text.trim();
                              if (value.isEmpty) {
                                setLocalState(
                                  () => errorText =
                                      _DashboardStrings.requiredField,
                                );
                                return;
                              }
                              FocusScope.of(ctx).unfocus();
                              Navigator.of(ctx).pop(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  _ProfileActionButton(
                    label: actionLabel,
                    icon: Icons.check_rounded,
                    compact: compact,
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isEmpty) {
                        setLocalState(
                          () => errorText = _DashboardStrings.requiredField,
                        );
                        return;
                      }
                      FocusScope.of(ctx).unfocus();
                      Navigator.of(ctx).pop(value);
                    },
                  ),
                ],
              );
            },
          );
        },
      );

      return result;
    } finally {
      _disposeControllersAfterSheetClose([controller]);
    }
  }

  String _buildBudgetDrawerSubtitle(DashboardSummary? summary) {
    if (!_budgetLoaded) {
      return 'بارکردن...';
    }
    final budget = _monthlyBudgetIqd;
    if (budget == null || budget <= 0) {
      return 'سنووری مانگانە دیاری نەکراوە';
    }
    final used = (summary?.estimatedCost ?? 0)
        .clamp(0, double.infinity)
        .toDouble();
    final ratio = budget > 0 ? used / budget : 0;
    final percent = (ratio * 100).clamp(0, 999).toDouble();
    return '${_formatIqd(used)} / ${_formatIqd(budget)} \u2022 ${percent.toStringAsFixed(0)}%';
  }

  void _selectSection(int index) {
    if (_selectedSection == index) return;
    setState(() {
      _selectedSection = index;
      if (index == 2) _meterHistory = readSavedMeterCycleHistory();
    });
  }

  Future<void> _openCalculator({bool meterMode = false}) async {
    await _showEnergyCalculatorSheet(meterMode: meterMode);
    if (mounted) {
      final history = readSavedMeterCycleHistory();
      setState(() {
        _meterHistory = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _actions ??= ApplianceActions(context: context, ref: ref);
    final dashboardState = ref.watch(dashboardProvider);
    final appliancesState = ref.watch(appliancesProvider);
    final houseProfile = ref.watch(houseProfileProvider).selectedProfile;
    final tariff = ref.watch(electricityTariffProfileProvider);
    final data = dashboardState.data;
    final summary = data?.summary;
    final chartPoints = data?.chartPoints ?? <ChartPoint>[];
    final breakdown = data?.breakdown ?? <ApplianceBreakdown>[];
    final tips = localizedTips(data?.tips ?? const []);
    final media = MediaQuery.of(context);
    final responsiveMedia = media.copyWith(
      textScaler: DashboardResponsive.textScaler(media),
    );
    final maxWidth = _selectedSection == 1 ? 1200.0 : 960.0;
    final contentWidth = (media.size.width.clamp(0.0, maxWidth) - 40)
        .clamp(0.0, double.infinity)
        .toDouble();
    const spacing = 16.0;
    final grid = GridCalculator(
      contentWidth: contentWidth,
      spacing: spacing,
      applianceSlack: 24,
    );

    Widget section;
    switch (_selectedSection) {
      case 1:
        section = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardSectionHeading(
              title: 'ئامێرەکان',
              subtitle:
                  '${houseProfile.name} • ڕێکخستنی وات و کاتی بەکارهێنان.',
            ),
            AppliancesSection(
              grid: grid,
              appliances: appliancesState.items,
              applianceCosts: data?.applianceMonthlyCosts ?? <String, double>{},
              spacing: spacing,
              isLoading: appliancesState.isLoading,
              errorMessage: appliancesState.error,
              onAdd: _actions!.add,
              onToggle: _actions!.toggle,
              onEdit: _actions!.edit,
              onDelete: _actions!.delete,
            ),
          ],
        );
      case 2:
        section = DashboardRecordsSection(
          history: _meterHistory,
          onOutageLogTap: () => context.push('/outage-log'),
          onMeterTap: () => unawaited(_openCalculator(meterMode: true)),
        );
      case 3:
        section = DashboardToolList(
          onEnergyTap: () => unawaited(_openCalculator()),
          onElectricalTap: () => unawaited(_showElectricalToolsSheet()),
          onBudgetTap: () => unawaited(_showBudgetSheet()),
          onOutageTap: () => unawaited(_onEditOutageTap()),
        );
      default:
        section = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DashboardOverview(
              summary: summary,
              houseName: houseProfile.name,
              tariffLabel: '${tariff.title} • ${tariffRateLabel(tariff)}',
              monthlyBudgetIqd: _monthlyBudgetIqd,
              isLoading: dashboardState.isLoading && summary == null,
              onBudgetTap: () => unawaited(_showBudgetSheet()),
              onTariffTap: () => unawaited(_showTariffInfoSheet(tariff)),
              onAppliancesTap: () => _selectSection(1),
              onOutageTap: () => unawaited(_onEditOutageTap()),
            ),
            const SizedBox(height: 20),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                key: const PageStorageKey('overview-analysis'),
                tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                iconColor: _dashboardIcon,
                collapsedIconColor: _dashboardIcon,
                title: const Text(
                  'شیکردنەوەی خەمڵاندن',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'دابەشکردنی ئامێرەکان و کاریگەری قەطعبوون',
                ),
                children: [
                  const SizedBox(height: 12),
                  ViewModeToggle(
                    mode: dashboardState.viewMode,
                    onChanged: (mode) =>
                        ref.read(dashboardProvider.notifier).setViewMode(mode),
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
                  TipsSection(tips: tips),
                ],
              ),
            ),
          ],
        );
    }

    return PopScope(
      canPop: _selectedSection == 0 || _drawerOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_drawerOpen) {
            _scaffoldKey.currentState?.closeEndDrawer();
          } else {
            _selectSection(0);
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        onEndDrawerChanged: (open) {
          if (mounted) setState(() => _drawerOpen = open);
        },
        backgroundColor: _dashboardSubtleSurface,
        endDrawer: _SettingsDrawer(
          selectedTariffProfile: tariff,
          selectedHouseProfileName: houseProfile.name,
          budgetSubtitle: _buildBudgetDrawerSubtitle(summary),
          versionLabel: _appVersionLabel,
          onHouseProfileTap: _openHouseProfileFromDrawer,
          onBudgetTap: _openBudgetFromDrawer,
          onTariffTap: _openTariffFromDrawer,
          onAboutTap: _showAboutSheet,
        ),
        bottomNavigationBar: DashboardNavigation(
          selectedIndex: _selectedSection,
          onSelected: _selectSection,
        ),
        body: MediaQuery(
          data: responsiveMedia,
          child: Column(
            children: [
              Material(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: DashboardHeader(
                      houseName: houseProfile.name,
                      onProfileTap: () =>
                          unawaited(_showHouseProfileManagerDialog()),
                      onMenuTap: () =>
                          _scaffoldKey.currentState?.openEndDrawer(),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: _dashboardBorder),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _onRefresh();
                    if (mounted && _selectedSection == 2) {
                      final history = readSavedMeterCycleHistory();
                      setState(() {
                        _meterHistory = history;
                      });
                    }
                  },
                  child: SingleChildScrollView(
                    key: PageStorageKey('dashboard-section-$_selectedSection'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth - 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (dashboardState.error != null &&
                                _selectedSection == 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: StatusBanner(
                                  message: dashboardState.error!,
                                ),
                              ),
                            section,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  Future<void> _refreshAfterBackgroundAction() async {
    if (!mounted || _isLifecycleRefreshRunning) {
      return;
    }

    final now = DateTime.now();
    if (_lastLifecycleRefreshAt != null &&
        now.difference(_lastLifecycleRefreshAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastLifecycleRefreshAt = now;
    _isLifecycleRefreshRunning = true;

    try {
      await Future.wait([
        ref.read(dashboardProvider.notifier).refresh(),
        ref.read(appliancesProvider.notifier).refresh(),
      ]);
    } finally {
      _isLifecycleRefreshRunning = false;
    }
  }

  Future<void> _onEditOutageTap() async {
    final summary = ref.read(dashboardProvider).data?.summary;
    final isTracking = summary?.outageTrackingActive ?? false;
    final action = await _showOutageActionSheet(isTrackingActive: isTracking);
    if (action == null || !mounted) {
      return;
    }

    final notifier = ref.read(dashboardProvider.notifier);

    switch (action) {
      case _OutageAction.startTracking:
        await notifier.startOutageTracking();
        await NotificationService.instance.ensureOutageControlNotification();
        if (!mounted) {
          return;
        }
        showSnack(
          context,
          'تۆمارکردنی قەطعبوون دەستی پێکرد.',
          variant: SnackBarVariant.success,
        );
        return;
      case _OutageAction.stopTracking:
        final addedMinutes = await notifier.stopOutageTracking();
        await NotificationService.instance.ensureOutageControlNotification();
        if (!mounted) {
          return;
        }
        final message = addedMinutes > 0
            ? 'تۆمارکردن وەستێنرا. $addedMinutes خولەک زیاد کرا.'
            : 'هیچ خولەکێکی تۆمارکراو زیاد نەکرا.';
        showSnack(context, message, variant: SnackBarVariant.success);
        return;
      case _OutageAction.manualEdit:
        final currentMinutes = summary?.outageMinutesToday ?? 0;
        final minutes = await _showOutageDialog(currentMinutes);
        if (minutes == null || !mounted) {
          return;
        }

        await notifier.setTodayOutageMinutes(minutes);
        await NotificationService.instance.ensureOutageControlNotification();
        if (!mounted) {
          return;
        }
        showSnack(
          context,
          'خولەکەکانی قەطعبوونی کارەبا نوێ کرانەوە: $minutes.',
          variant: SnackBarVariant.success,
        );
        return;
    }
  }

  Future<void> _showAboutSheet() async {
    _scaffoldKey.currentState?.closeEndDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierLabel: 'about_dialog',
      barrierDismissible: true,
      barrierColor: const Color(0xA3000000),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) {
        return _RunakiAboutDialog(versionLabel: _appVersionLabel);
      },
      transitionBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openHouseProfileFromDrawer() async {
    _scaffoldKey.currentState?.closeEndDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await _showHouseProfileManagerDialog();
  }

  Future<void> _openBudgetFromDrawer() async {
    _scaffoldKey.currentState?.closeEndDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    await _showBudgetSheet();
  }

  Future<void> _showHouseProfileManagerDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        final media = MediaQuery.of(ctx);
        final compact = _DashboardResponsive.isCompactDialog(media);
        final keyboardInset = media.viewInsets.bottom;
        final maxWidth = _DashboardResponsive.profileManagerMaxWidth(media);
        final maxContentHeight =
            _DashboardResponsive.profileManagerContentHeight(media, compact);

        return Consumer(
          builder: (ctx, dialogRef, _) {
            final houseProfileState = dialogRef.watch(houseProfileProvider);
            return AppDialogShell(
              title: _DashboardStrings.profileTitle,
              subtitle: _DashboardStrings.profileDialogSubtitle,
              icon: Icons.home_work_outlined,
              onClose: () => Navigator.of(ctx).pop(),
              accentColor: _dashboardIcon,
              maxWidth: maxWidth,
              insetPadding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 18,
                vertical: compact ? 10 : 16,
              ),
              contentPadding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              actionPadding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
              content: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxContentHeight),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: keyboardInset > 0 ? 8 : 0),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: _HouseProfileCard(
                      state: houseProfileState,
                      onAddTap: _onAddHouseProfileTap,
                      onSelectProfile: _onSwitchHouseProfile,
                      onRenameProfile: _onRenameHouseProfile,
                      onDeleteProfile: _onDeleteHouseProfile,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBudgetSheet() async {
    final pageContext = context;
    final summary = ref.read(dashboardProvider).data?.summary;
    final monthlyEstimateCost = (summary?.estimatedCost ?? 0)
        .clamp(0, double.infinity)
        .toDouble();
    final monthlyEstimateKwh = (summary?.monthlyKwh ?? 0)
        .clamp(0, double.infinity)
        .toDouble();
    final budgetController = TextEditingController(
      text: _monthlyBudgetIqd == null
          ? ''
          : _iqdWholeFormatter.format(_monthlyBudgetIqd!.round()),
    );

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (sheetContext) {
          final media = MediaQuery.of(sheetContext);
          final keyboardInset = media.viewInsets.bottom;
          final availableHeight =
              media.size.height - media.padding.top - media.padding.bottom - 12;
          final sheetHeight = media.size.width >= 700
              ? (availableHeight < 720 ? availableHeight : 720.0)
              : availableHeight.clamp(300.0, media.size.height).toDouble();

          return SafeArea(
            top: false,
            bottom: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: SizedBox(
                height: sheetHeight,
                child: StatefulBuilder(
                  builder: (dialogContext, sheetSetState) {
                    final rawBudget = _parseBudgetInput(budgetController.text);
                    final hasBudgetInput = budgetController.text
                        .trim()
                        .isNotEmpty;
                    final isBudgetValid = !hasBudgetInput || rawBudget > 0;
                    final previewBudget = hasBudgetInput && isBudgetValid
                        ? rawBudget
                        : _monthlyBudgetIqd;
                    final hasActiveBudget =
                        previewBudget != null && previewBudget > 0;
                    final usageRatio = hasActiveBudget
                        ? monthlyEstimateCost / previewBudget
                        : 0.0;
                    final usagePercent = (usageRatio * 100)
                        .clamp(0, 999)
                        .toDouble();
                    final health = _budgetHealthForRatio(usageRatio);
                    final statusColor = health == _BudgetHealth.exceeded
                        ? Theme.of(dialogContext).colorScheme.error
                        : _dashboardIcon;
                    final remaining = hasActiveBudget
                        ? previewBudget - monthlyEstimateCost
                        : 0.0;
                    final profile = ref.read(electricityTariffProfileProvider);

                    Widget metricCard({
                      required IconData icon,
                      required String label,
                      required String value,
                    }) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _dashboardSubtleSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _dashboardBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _dashboardSurface,
                                borderRadius: BorderRadius.circular(11),
                                border: Border.all(color: _dashboardBorder),
                              ),
                              child: Icon(
                                icon,
                                size: 19,
                                color: _dashboardIcon,
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    style: Theme.of(dialogContext)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondaryFor(
                                            dialogContext,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(dialogContext)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: AppColors.textPrimaryFor(
                                            dialogContext,
                                          ),
                                          fontWeight: FontWeight.w800,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    Future<void> saveBudget() async {
                      final value = hasBudgetInput ? rawBudget : null;
                      await _saveMonthlyBudget(
                        profileId: ref
                            .read(houseProfileProvider)
                            .selectedProfileId,
                        budgetIqd: value,
                      );
                      if (!mounted || !sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();
                      if (!pageContext.mounted) return;
                      showSnack(
                        pageContext,
                        value == null ? 'بەدجەت لابرا' : 'بەدجەت پاشەکەوتکرا',
                        variant: SnackBarVariant.success,
                      );
                    }

                    return AppSheetShell(
                      title: 'بەدجەتی مانگانەی کارەبا',
                      subtitle: 'سنوورێک دابنێ بۆ ئاگاداریی پێشوەخت.',
                      icon: Icons.account_balance_wallet_outlined,
                      onClose: () => Navigator.of(sheetContext).pop(),
                      accentColor: _dashboardIcon,
                      showHandle: false,
                      expandChild: true,
                      maxWidth: 720,
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                      actions: [
                        AppButton(
                          label: !hasBudgetInput && _monthlyBudgetIqd != null
                              ? 'لابردنی بەدجەت'
                              : 'پاشەکەوتکردنی بەدجەت',
                          icon: !hasBudgetInput && _monthlyBudgetIqd != null
                              ? Icons.delete_outline_rounded
                              : Icons.check_rounded,
                          variant: !hasBudgetInput && _monthlyBudgetIqd != null
                              ? AppButtonVariant.destructive
                              : AppButtonVariant.primary,
                          onPressed:
                              isBudgetValid &&
                                  (hasBudgetInput || _monthlyBudgetIqd != null)
                              ? () => unawaited(saveBudget())
                              : null,
                        ),
                      ],
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: budgetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: <TextInputFormatter>[
                                _budgetNumberInputFormatter,
                              ],
                              textDirection: TextDirection.ltr,
                              onChanged: (_) => sheetSetState(() {}),
                              decoration: InputDecoration(
                                labelText: 'سنووری بەدجەتی مانگانە',
                                hintText: '120,000',
                                suffixText: 'دینار',
                                errorText: hasBudgetInput && !isBudgetValid
                                    ? 'بڕێکی دروست بنووسە'
                                    : null,
                                prefixIcon: const Icon(
                                  Icons.payments_outlined,
                                  color: _dashboardIcon,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (hasActiveBudget) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _dashboardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _dashboardBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'خەرجی پێشبینیکراوی مانگانە',
                                                style: Theme.of(dialogContext)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.textSecondaryFor(
                                                            dialogContext,
                                                          ),
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatIqd(monthlyEstimateCost),
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: Theme.of(dialogContext)
                                                    .textTheme
                                                    .headlineSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color:
                                                          AppColors.textPrimaryFor(
                                                            dialogContext,
                                                          ),
                                                      fontFeatures: const [
                                                        FontFeature.tabularFigures(),
                                                      ],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _dashboardSubtleSurface,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: _dashboardBorder,
                                            ),
                                          ),
                                          child: Text(
                                            _budgetHealthLabel(health),
                                            style: Theme.of(dialogContext)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: statusColor,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        minHeight: 8,
                                        value: usageRatio.clamp(0, 1),
                                        backgroundColor: _dashboardBorder,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              _dashboardSelected,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${usagePercent.toStringAsFixed(0)}% بەکارهاتووە',
                                            style: Theme.of(dialogContext)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color:
                                                      AppColors.textSecondaryFor(
                                                        dialogContext,
                                                      ),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          _formatIqd(previewBudget),
                                          textDirection: TextDirection.ltr,
                                          style: Theme.of(dialogContext)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppColors.textSecondaryFor(
                                                      dialogContext,
                                                    ),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ] else ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: _dashboardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: _dashboardBorder),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 20,
                                      color: _dashboardIcon,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'هێشتا بەدجەتت دیاری نەکردووە. سنوورێک بنووسە تا ئاگاداری و پێشبینییەکان چالاک بن.',
                                        style: Theme.of(dialogContext)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(height: 1.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth >= 520;
                                final cardWidth = wide
                                    ? (constraints.maxWidth - 12) / 2
                                    : constraints.maxWidth;
                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [
                                    SizedBox(
                                      width: cardWidth,
                                      child: metricCard(
                                        icon:
                                            Icons.electrical_services_outlined,
                                        label: 'بەکارهێنانی پێشبینیکراو',
                                        value:
                                            '${monthlyEstimateKwh.toStringAsFixed(1)} kWh',
                                      ),
                                    ),
                                    SizedBox(
                                      width: cardWidth,
                                      child: metricCard(
                                        icon: Icons.receipt_long_outlined,
                                        label: 'جۆری نرخ',
                                        value: profile.title,
                                      ),
                                    ),
                                    if (hasActiveBudget) ...[
                                      SizedBox(
                                        width: cardWidth,
                                        child: metricCard(
                                          icon: Icons.flag_outlined,
                                          label: 'سنووری بەدجەت',
                                          value: _formatIqd(previewBudget),
                                        ),
                                      ),
                                      SizedBox(
                                        width: cardWidth,
                                        child: metricCard(
                                          icon: remaining >= 0
                                              ? Icons.trending_up_rounded
                                              : Icons.trending_down_rounded,
                                          label: remaining >= 0
                                              ? 'ماوەی بەدجەت'
                                              : 'زیادەڕۆیی',
                                          value: _formatIqd(remaining.abs()),
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _disposeControllersAfterSheetClose([budgetController]);
    }
  }

  Future<void> _openTariffFromDrawer() async {
    _scaffoldKey.currentState?.closeEndDrawer();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;

    final selected = await _showTariffProfileSheet();
    if (selected == null || !mounted) {
      return;
    }

    final current = ref.read(electricityTariffProfileProvider);
    if (current.id == selected.id) {
      return;
    }

    await ref
        .read(electricityTariffProfileProvider.notifier)
        .setProfile(selected);
    await ref.read(dashboardProvider.notifier).refresh();
  }

  Future<void> _showEnergyCalculatorSheet({bool meterMode = false}) async {
    final initialProfile = ref.read(electricityTariffProfileProvider);
    var calculatorProfile = initialProfile;
    var appliedProfileId = initialProfile.id;
    final kwhController = TextEditingController(text: '250');
    final wattsController = TextEditingController(text: '1500');
    final hoursController = TextEditingController(text: '6');
    final meterStartController = TextEditingController();
    final meterEndController = TextEditingController();
    final daysController = TextEditingController(text: '30');
    var inputMode = meterMode
        ? _CalculatorInputMode.meterReading
        : _CalculatorInputMode.directKwh;
    var meterCycleHistory = await readSavedMeterCycleHistory();
    if (!mounted) return;

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (sheetContext) {
          final media = MediaQuery.of(sheetContext);
          final keyboardInset = media.viewInsets.bottom;
          final availableHeight = (media.size.height - media.padding.top - 8)
              .clamp(300.0, media.size.height)
              .toDouble();
          final isDesktop = media.size.width >= 700;
          final sheetHeight = isDesktop
              ? (media.size.height * 0.88)
                    .clamp(560.0, availableHeight)
                    .toDouble()
              : availableHeight;

          return SafeArea(
            top: false,
            bottom: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Align(
                alignment: isDesktop
                    ? Alignment.center
                    : Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: sheetHeight),
                  child: AppSheetShell(
                    title: 'ژمێریاری وزە و تێچوو',
                    subtitle: 'بەکارهێنان و تێچوو بە شێوەیەکی سادە هەژمار بکە',
                    icon: Icons.calculate_outlined,
                    onClose: () => Navigator.of(sheetContext).pop(),
                    accentColor: _dashboardIcon,
                    showHandle: false,
                    expandChild: false,
                    maxWidth: 900,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: StatefulBuilder(
                      builder: (context, sheetSetState) {
                        final theme = Theme.of(context);
                        const primary = _dashboardSelected;
                        const border = _dashboardBorder;
                        const surface = _dashboardSurface;
                        const mutedSurface = _dashboardSubtleSurface;
                        final textPrimary =
                            theme.textTheme.bodyLarge?.color ??
                            AppColors.textPrimaryFor(context);
                        final textSecondary =
                            theme.textTheme.bodyMedium?.color ??
                            AppColors.textSecondaryFor(context);

                        final days = _parseCalculatorNum(daysController.text);
                        final directKwh = _parseCalculatorNum(
                          kwhController.text,
                        );
                        final watts = _parseCalculatorNum(wattsController.text);
                        final hours = _parseCalculatorNum(hoursController.text);
                        final meterStart = _parseCalculatorNum(
                          meterStartController.text,
                        );
                        final meterEnd = _parseCalculatorNum(
                          meterEndController.text,
                        );

                        final hasDaysInput = daysController.text
                            .trim()
                            .isNotEmpty;
                        final hasDirectInput = kwhController.text
                            .trim()
                            .isNotEmpty;
                        final hasWattsInput = wattsController.text
                            .trim()
                            .isNotEmpty;
                        final hasHoursInput = hoursController.text
                            .trim()
                            .isNotEmpty;
                        final hasMeterStartInput = meterStartController.text
                            .trim()
                            .isNotEmpty;
                        final hasMeterEndInput = meterEndController.text
                            .trim()
                            .isNotEmpty;

                        final isDaysValid = days > 0;
                        final isDirectValid = directKwh > 0;
                        final isWattsValid = watts > 0;
                        final isHoursValid = hours > 0;
                        final isMeterStartValid = meterStart >= 0;
                        final isMeterEndValid = meterEnd >= 0;
                        final meterUsageKwh = meterEnd - meterStart;
                        final isMeterRangeValid = meterUsageKwh > 0;

                        final isDirectMode =
                            inputMode == _CalculatorInputMode.directKwh;
                        final isWattsMode =
                            inputMode == _CalculatorInputMode.wattsHours;
                        final isMeterMode =
                            inputMode == _CalculatorInputMode.meterReading;

                        final canCompute =
                            isDaysValid &&
                            (isDirectMode
                                ? isDirectValid
                                : isWattsMode
                                ? isWattsValid && isHoursValid
                                : hasMeterStartInput &&
                                      hasMeterEndInput &&
                                      isMeterStartValid &&
                                      isMeterEndValid &&
                                      isMeterRangeValid);
                        final validDays = isDaysValid ? days : 0.0;
                        final rawKwh = canCompute
                            ? isDirectMode
                                  ? directKwh
                                  : isWattsMode
                                  ? (watts / 1000) * hours * validDays
                                  : meterUsageKwh
                            : 0.0;
                        final totalKwh = rawKwh.isFinite && rawKwh > 0
                            ? rawKwh
                            : 0.0;
                        final totalCost = calculateElectricityCostIqd(
                          kwh: totalKwh,
                          profile: calculatorProfile,
                        );
                        final dailyKwh = canCompute
                            ? totalKwh / validDays
                            : 0.0;
                        final dailyCost = canCompute
                            ? totalCost / validDays
                            : 0.0;
                        final weeklyKwh = dailyKwh * 7;
                        final weeklyCost = calculateElectricityCostIqd(
                          kwh: weeklyKwh,
                          profile: calculatorProfile,
                        );
                        final monthlyKwh = dailyKwh * 30;
                        final monthlyCost = calculateElectricityCostIqd(
                          kwh: monthlyKwh,
                          profile: calculatorProfile,
                        );
                        final yearlyKwh = monthlyKwh * 12;
                        final yearlyCost = calculateElectricityCostIqd(
                          kwh: yearlyKwh,
                          profile: calculatorProfile,
                        );
                        final effectiveRate = totalKwh > 0
                            ? totalCost / totalKwh
                            : 0.0;
                        final hasResult = canCompute && totalKwh > 0;
                        final tierHint = _buildCalculatorTierHint(
                          profile: calculatorProfile,
                          kwh: totalKwh,
                        );
                        final canApplyProfile =
                            calculatorProfile.id != appliedProfileId;

                        final showDaysError = hasDaysInput && !isDaysValid;
                        final showDirectError =
                            isDirectMode && hasDirectInput && !isDirectValid;
                        final showWattsError =
                            isWattsMode && hasWattsInput && !isWattsValid;
                        final showHoursError =
                            isWattsMode && hasHoursInput && !isHoursValid;
                        final showMeterStartError =
                            isMeterMode &&
                            hasMeterStartInput &&
                            !isMeterStartValid;
                        final showMeterEndError =
                            isMeterMode &&
                            hasMeterEndInput &&
                            (!isMeterEndValid ||
                                (hasMeterStartInput && !isMeterRangeValid));

                        const positiveValueError =
                            'ژمارەیەکی گەورەتر لە سفر بنووسە';
                        final meterUsageCost = calculateElectricityCostIqd(
                          kwh: meterUsageKwh > 0 ? meterUsageKwh : 0,
                          profile: calculatorProfile,
                        );
                        final canSaveMeterCycle = isMeterMode && canCompute;

                        InputDecoration inputDecoration({
                          required String label,
                          String? hint,
                          String? suffix,
                          String? error,
                        }) {
                          return InputDecoration(
                            labelText: label,
                            hintText: hint,
                            suffixText: suffix,
                            errorText: error,
                            filled: true,
                            fillColor: surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: primary,
                                width: 1.4,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.error,
                                width: 1.4,
                              ),
                            ),
                          );
                        }

                        Widget panel({
                          required Widget child,
                          EdgeInsetsGeometry padding = EdgeInsets.zero,
                          Color? color,
                        }) {
                          return Container(
                            width: double.infinity,
                            padding: padding,
                            decoration: BoxDecoration(
                              color: color ?? surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: child,
                          );
                        }

                        Widget sectionTitle({
                          required String title,
                          required IconData icon,
                          String? subtitle,
                        }) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, size: 19, color: _dashboardIcon),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: textSecondary,
                                              height: 1.4,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        Widget adaptiveFields(List<Widget> fields) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              if (constraints.maxWidth >= 560) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (
                                      var index = 0;
                                      index < fields.length;
                                      index++
                                    ) ...[
                                      if (index > 0) const SizedBox(width: 12),
                                      Expanded(child: fields[index]),
                                    ],
                                  ],
                                );
                              }
                              return Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < fields.length;
                                    index++
                                  ) ...[
                                    if (index > 0) const SizedBox(height: 12),
                                    fields[index],
                                  ],
                                ],
                              );
                            },
                          );
                        }

                        Widget metricTile({
                          required String label,
                          required String value,
                          required IconData icon,
                        }) {
                          return Container(
                            height: 76,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 20, color: _dashboardIcon),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        value,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textDirection: TextDirection.ltr,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final modes =
                            <
                              ({
                                _CalculatorInputMode mode,
                                String label,
                                IconData icon,
                              })
                            >[
                              (
                                mode: _CalculatorInputMode.directKwh,
                                label: 'kWh',
                                icon: Icons.electric_meter_outlined,
                              ),
                              (
                                mode: _CalculatorInputMode.wattsHours,
                                label: 'وات + کات',
                                icon: Icons.schedule_outlined,
                              ),
                              (
                                mode: _CalculatorInputMode.meterReading,
                                label: 'کنتۆر',
                                icon: Icons.speed_outlined,
                              ),
                            ];

                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              panel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    DropdownButtonFormField<String>(
                                      initialValue: calculatorProfile.id,
                                      isExpanded: true,
                                      decoration: inputDecoration(
                                        label: 'جۆری نرخ',
                                      ),
                                      items: ElectricityTariffCatalog.values
                                          .map(
                                            (
                                              profile,
                                            ) => DropdownMenuItem<String>(
                                              value: profile.id,
                                              child: Text(
                                                '${profile.title} • ${tariffRateLabel(profile)}',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (profileId) {
                                        if (profileId == null) return;
                                        sheetSetState(() {
                                          calculatorProfile = tariffProfileById(
                                            profileId,
                                          );
                                        });
                                      },
                                    ),
                                    if (canApplyProfile) ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: AppButton(
                                          label: 'هەڵگرتنی ئەم نرخە',
                                          icon: Icons.check_rounded,
                                          variant: AppButtonVariant.outline,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          onPressed: () {
                                            final profileToApply =
                                                calculatorProfile;
                                            unawaited(() async {
                                              await ref
                                                  .read(
                                                    electricityTariffProfileProvider
                                                        .notifier,
                                                  )
                                                  .setProfile(profileToApply);
                                              await ref
                                                  .read(
                                                    dashboardProvider.notifier,
                                                  )
                                                  .refresh();
                                              if (!mounted ||
                                                  !context.mounted ||
                                                  !sheetContext.mounted) {
                                                return;
                                              }
                                              sheetSetState(() {
                                                appliedProfileId =
                                                    profileToApply.id;
                                              });
                                              showSnack(
                                                context,
                                                'جۆری نرخ نوێکرایەوە',
                                                variant:
                                                    SnackBarVariant.success,
                                              );
                                            }());
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final buttonWidth =
                                      (constraints.maxWidth - 16) / 3;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      for (final item in modes)
                                        SizedBox(
                                          width: buttonWidth,
                                          child: AppButton(
                                            fullWidth: true,
                                            label: item.label,
                                            icon: item.icon,
                                            iconSize: 17,
                                            fontSize: 12.5,
                                            variant: AppButtonVariant.segment,
                                            selected: inputMode == item.mode,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 11,
                                            ),
                                            onPressed: () => sheetSetState(
                                              () => inputMode = item.mode,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              panel(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (isDirectMode)
                                      TextField(
                                        controller: kwhController,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        inputFormatters: <TextInputFormatter>[
                                          _decimalNumberInputFormatter,
                                        ],
                                        onChanged: (_) => sheetSetState(() {}),
                                        decoration: inputDecoration(
                                          label: 'کۆی بەکارهێنان',
                                          hint: 'نموونە: 250',
                                          suffix: 'kWh',
                                          error: showDirectError
                                              ? positiveValueError
                                              : null,
                                        ),
                                      ),
                                    if (isWattsMode)
                                      adaptiveFields([
                                        TextField(
                                          controller: wattsController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: <TextInputFormatter>[
                                            _decimalNumberInputFormatter,
                                          ],
                                          onChanged: (_) =>
                                              sheetSetState(() {}),
                                          decoration: inputDecoration(
                                            label: 'هێز',
                                            hint: '1500',
                                            suffix: 'W',
                                            error: showWattsError
                                                ? positiveValueError
                                                : null,
                                          ),
                                        ),
                                        TextField(
                                          controller: hoursController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: <TextInputFormatter>[
                                            _decimalNumberInputFormatter,
                                          ],
                                          onChanged: (_) =>
                                              sheetSetState(() {}),
                                          decoration: inputDecoration(
                                            label: 'کات لە ڕۆژێکدا',
                                            hint: '6',
                                            suffix: 'کاتژمێر',
                                            error: showHoursError
                                                ? positiveValueError
                                                : null,
                                          ),
                                        ),
                                      ]),
                                    if (isMeterMode) ...[
                                      adaptiveFields([
                                        TextField(
                                          controller: meterStartController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: <TextInputFormatter>[
                                            _decimalNumberInputFormatter,
                                          ],
                                          onChanged: (_) =>
                                              sheetSetState(() {}),
                                          decoration: inputDecoration(
                                            label: 'خوێندنەوەی سەرەتا',
                                            hint: '12000',
                                            suffix: 'kWh',
                                            error: showMeterStartError
                                                ? 'ژمارەیەکی دروست بنووسە'
                                                : null,
                                          ),
                                        ),
                                        TextField(
                                          controller: meterEndController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          inputFormatters: <TextInputFormatter>[
                                            _decimalNumberInputFormatter,
                                          ],
                                          onChanged: (_) =>
                                              sheetSetState(() {}),
                                          decoration: inputDecoration(
                                            label: 'خوێندنەوەی کۆتایی',
                                            hint: '12250',
                                            suffix: 'kWh',
                                            error: showMeterEndError
                                                ? 'دەبێت لە سەرەتا زیاتر بێت'
                                                : null,
                                          ),
                                        ),
                                      ]),
                                      const SizedBox(height: 12),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: mutedSurface,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(color: border),
                                        ),
                                        child: Text(
                                          meterUsageKwh > 0
                                              ? 'بەکارهێنانی کنتۆر: ${meterUsageKwh.toStringAsFixed(2)} kWh'
                                              : 'بەکارهێنانی کنتۆر: --',
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Divider(height: 1, color: border),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: daysController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: <TextInputFormatter>[
                                        _integerNumberInputFormatter,
                                      ],
                                      onChanged: (_) => sheetSetState(() {}),
                                      decoration: inputDecoration(
                                        label: 'ژمارەی ڕۆژەکان',
                                        hint: '30',
                                        suffix: 'ڕۆژ',
                                        error: showDaysError
                                            ? positiveValueError
                                            : null,
                                      ),
                                    ),
                                    if (isMeterMode) ...[
                                      const SizedBox(height: 12),
                                      AppButton(
                                        fullWidth: true,
                                        label: 'تۆمارکردنی خولی کنتۆر',
                                        icon: Icons.save_outlined,
                                        variant: AppButtonVariant.primary,
                                        onPressed: canSaveMeterCycle
                                            ? () {
                                                unawaited(() async {
                                                  final now = DateTime.now();
                                                  final nextRecord =
                                                      MeterCycleRecord(
                                                        id: '${now.microsecondsSinceEpoch}',
                                                        fromReadingKwh:
                                                            meterStart,
                                                        toReadingKwh: meterEnd,
                                                        usageKwh: meterUsageKwh,
                                                        costIqd: meterUsageCost,
                                                        profileId:
                                                            calculatorProfile
                                                                .id,
                                                        profileTitle:
                                                            calculatorProfile
                                                                .title,
                                                        days: validDays.round(),
                                                        createdAt: now,
                                                      );
                                                  final updatedHistory =
                                                      await saveMeterCycleRecord(
                                                        nextRecord,
                                                      );
                                                  if (!mounted ||
                                                      !context.mounted ||
                                                      !sheetContext.mounted) {
                                                    return;
                                                  }
                                                  sheetSetState(() {
                                                    meterCycleHistory =
                                                        updatedHistory;
                                                  });
                                                  showSnack(
                                                    context,
                                                    'خولی کنتۆر تۆمارکرا',
                                                    variant:
                                                        SnackBarVariant.success,
                                                  );
                                                }());
                                              }
                                            : null,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              panel(
                                color: mutedSurface,
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'کۆی تێچوو',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            hasResult
                                                ? _formatIqd(totalCost)
                                                : '--',
                                            textDirection: TextDirection.ltr,
                                            style: theme
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  color: textPrimary,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: border),
                                      ),
                                      child: Text(
                                        hasResult
                                            ? '${totalKwh.toStringAsFixed(2)} kWh'
                                            : '-- kWh',
                                        textDirection: TextDirection.ltr,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: textPrimary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (tierHint != null && hasResult) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 11,
                                  ),
                                  decoration: BoxDecoration(
                                    color: surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: border),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline_rounded,
                                        size: 18,
                                        color: _dashboardIcon,
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Text(
                                          tierHint,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: textSecondary,
                                                height: 1.45,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              ExpansionTile(
                                title: const Text(
                                  'وردەکاریی خەمڵاندن',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                tilePadding: EdgeInsets.zero,
                                iconColor: _dashboardIcon,
                                collapsedIconColor: _dashboardIcon,
                                shape: const Border(),
                                collapsedShape: const Border(),
                                maintainState: true,
                                children: [
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final columns =
                                          constraints.maxWidth >= 720
                                          ? 3
                                          : constraints.maxWidth >= 480
                                          ? 2
                                          : 1;
                                      final tileWidth =
                                          (constraints.maxWidth -
                                              ((columns - 1) * 10)) /
                                          columns;
                                      final values =
                                          <
                                            ({
                                              String label,
                                              String value,
                                              IconData icon,
                                            })
                                          >[
                                            (
                                              label: 'بەکارهێنانی ڕۆژانە',
                                              value: hasResult
                                                  ? '${dailyKwh.toStringAsFixed(2)} kWh'
                                                  : '--',
                                              icon: Icons.today_outlined,
                                            ),
                                            (
                                              label: 'تێچووی ڕۆژانە',
                                              value: hasResult
                                                  ? _formatIqd(dailyCost)
                                                  : '--',
                                              icon: Icons.payments_outlined,
                                            ),
                                            (
                                              label: 'پێشبینی هەفتانە',
                                              value: hasResult
                                                  ? '${weeklyKwh.toStringAsFixed(1)} kWh / ${_formatIqd(weeklyCost)}'
                                                  : '--',
                                              icon: Icons
                                                  .calendar_view_week_outlined,
                                            ),
                                            (
                                              label: 'پێشبینی مانگانە',
                                              value: hasResult
                                                  ? '${monthlyKwh.toStringAsFixed(1)} kWh / ${_formatIqd(monthlyCost)}'
                                                  : '--',
                                              icon:
                                                  Icons.calendar_month_outlined,
                                            ),
                                            (
                                              label: 'پێشبینی ساڵانە',
                                              value: hasResult
                                                  ? '${yearlyKwh.toStringAsFixed(0)} kWh / ${_formatIqd(yearlyCost)}'
                                                  : '--',
                                              icon: Icons.date_range_outlined,
                                            ),
                                            (
                                              label: 'نرخی کاریگەر',
                                              value: hasResult
                                                  ? _formatIqdPerKwh(
                                                      effectiveRate,
                                                    )
                                                  : '--',
                                              icon: Icons.price_check_outlined,
                                            ),
                                          ];
                                      return Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: [
                                          for (final item in values)
                                            SizedBox(
                                              width: tileWidth,
                                              child: metricTile(
                                                label: item.label,
                                                value: item.value,
                                                icon: item.icon,
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                              if (isMeterMode &&
                                  meterCycleHistory.isNotEmpty) ...[
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: sectionTitle(
                                        title: 'مێژووی خولەکانی کنتۆر',
                                        subtitle:
                                            'نوێترین تۆمارەکان لە سەرەوەن',
                                        icon: Icons.history_outlined,
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        unawaited(() async {
                                          final emptied =
                                              await clearMeterCycleHistory();
                                          if (!mounted ||
                                              !context.mounted ||
                                              !sheetContext.mounted) {
                                            return;
                                          }
                                          sheetSetState(() {
                                            meterCycleHistory = emptied;
                                          });
                                          showSnack(
                                            context,
                                            'مێژووی کنتۆر پاککرایەوە',
                                            variant: SnackBarVariant.success,
                                          );
                                        }());
                                      },
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: _dashboardIcon,
                                      ),
                                      label: const Text('پاککردنەوە'),
                                      style: TextButton.styleFrom(
                                        foregroundColor:
                                            theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                for (final record in meterCycleHistory.take(
                                  6,
                                )) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: border),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.speed_outlined,
                                          size: 19,
                                          color: _dashboardIcon,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${record.usageKwh.toStringAsFixed(2)} kWh • ${record.profileTitle}',
                                                textDirection:
                                                    TextDirection.ltr,
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: textPrimary,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${_formatCycleDate(record.createdAt)} • ${record.days} ڕۆژ',
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: textSecondary,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _formatIqd(record.costIqd),
                                          textDirection: TextDirection.ltr,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                                color: textPrimary,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ],
                              const SizedBox(height: 4),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _disposeControllersAfterSheetClose([
        kwhController,
        wattsController,
        hoursController,
        meterStartController,
        meterEndController,
        daysController,
      ]);
    }
  }

  Future<void> _showElectricalToolsSheet() async {
    final voltageController = TextEditingController(text: '220');
    final currentController = TextEditingController(text: '5');
    final powerController = TextEditingController(text: '1000');

    String formatCalcNum(double value, {int fractionDigits = 3}) {
      if (!value.isFinite) return '--';
      final fixed = value.toStringAsFixed(fractionDigits);
      return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    String buildFormula({
      required bool valid,
      required String left,
      required String expression,
      required String result,
      required String unit,
    }) {
      if (!valid) {
        return 'پێویستە ژمارەی دروست داخڵ بکەیت';
      }
      return '$left = $expression = $result $unit';
    }

    try {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (sheetContext) {
          final media = MediaQuery.of(sheetContext);
          final keyboardInset = media.viewInsets.bottom;
          final availableHeight = (media.size.height - media.padding.top - 8)
              .clamp(300.0, media.size.height)
              .toDouble();
          final isDesktop = media.size.width >= 700;
          final sheetHeight = isDesktop
              ? (media.size.height * 0.86)
                    .clamp(520.0, availableHeight)
                    .toDouble()
              : availableHeight;

          return SafeArea(
            top: false,
            bottom: false,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Align(
                alignment: isDesktop
                    ? Alignment.center
                    : Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: sheetHeight),
                  child: AppSheetShell(
                    title: 'ژمێریاری کارەبا',
                    subtitle: 'وات، ئەمپێر و ڤۆڵتەج بە خێرایی هەژمار بکە',
                    icon: Icons.electrical_services_outlined,
                    onClose: () => Navigator.of(sheetContext).pop(),
                    accentColor: _dashboardIcon,
                    showHandle: false,
                    expandChild: false,
                    maxWidth: 760,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: StatefulBuilder(
                      builder: (context, sheetSetState) {
                        final theme = Theme.of(context);
                        const primary = _dashboardSelected;
                        const border = _dashboardBorder;
                        const surface = _dashboardSurface;
                        const mutedSurface = _dashboardSubtleSurface;
                        final textPrimary =
                            theme.textTheme.bodyLarge?.color ??
                            AppColors.textPrimaryFor(context);
                        final textSecondary =
                            theme.textTheme.bodyMedium?.color ??
                            AppColors.textSecondaryFor(context);

                        final voltage = _parseCalculatorNum(
                          voltageController.text,
                        );
                        final current = _parseCalculatorNum(
                          currentController.text,
                        );
                        final power = _parseCalculatorNum(powerController.text);
                        final hasVoltage = voltageController.text
                            .trim()
                            .isNotEmpty;
                        final hasCurrent = currentController.text
                            .trim()
                            .isNotEmpty;
                        final hasPower = powerController.text.trim().isNotEmpty;
                        final validVoltage = voltage > 0;
                        final validCurrent = current > 0;
                        final validPower = power > 0;

                        final canCalculatePower = validVoltage && validCurrent;
                        final canCalculateCurrent = validPower && validVoltage;
                        final canCalculateVoltage = validPower && validCurrent;
                        final apparentPower = canCalculatePower
                            ? voltage * current
                            : 0.0;
                        final calculatedCurrent = canCalculateCurrent
                            ? power / voltage
                            : 0.0;
                        final calculatedVoltage = canCalculateVoltage
                            ? power / current
                            : 0.0;

                        InputDecoration inputDecoration({
                          required String label,
                          required String suffix,
                          String? error,
                        }) {
                          return InputDecoration(
                            labelText: label,
                            suffixText: suffix,
                            errorText: error,
                            filled: true,
                            fillColor: surface,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: primary,
                                width: 1.4,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.colorScheme.error,
                                width: 1.4,
                              ),
                            ),
                          );
                        }

                        Widget sectionTitle({
                          required String title,
                          required IconData icon,
                          String? subtitle,
                        }) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(icon, size: 19, color: _dashboardIcon),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: textPrimary,
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    if (subtitle != null) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: textSecondary,
                                              height: 1.4,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          );
                        }

                        Widget resultRow({
                          required String label,
                          required String value,
                          required IconData icon,
                        }) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            decoration: BoxDecoration(
                              color: surface,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: border),
                            ),
                            child: Row(
                              children: [
                                Icon(icon, size: 20, color: _dashboardIcon),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Text(
                                    label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  value,
                                  textDirection: TextDirection.ltr,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        Widget formulaRow({
                          required String title,
                          required String formula,
                          required String description,
                        }) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 14,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                SelectableText(
                                  formula,
                                  textDirection: TextDirection.ltr,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              sectionTitle(
                                title: 'زانیارییەکان',
                                subtitle:
                                    'ژمارەکان بگۆڕە؛ ئەنجامەکان خۆکارانە نوێ دەبنەوە',
                                icon: Icons.edit_outlined,
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 650
                                      ? 3
                                      : constraints.maxWidth >= 430
                                      ? 2
                                      : 1;
                                  final fieldWidth =
                                      (constraints.maxWidth -
                                          ((columns - 1) * 12)) /
                                      columns;
                                  final fields = <Widget>[
                                    TextField(
                                      controller: voltageController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: <TextInputFormatter>[
                                        _decimalNumberInputFormatter,
                                      ],
                                      onChanged: (_) => sheetSetState(() {}),
                                      decoration: inputDecoration(
                                        label: 'ڤۆڵتەج',
                                        suffix: 'V',
                                        error: hasVoltage && !validVoltage
                                            ? 'ژمارەیەکی گەورەتر لە سفر بنووسە'
                                            : null,
                                      ),
                                    ),
                                    TextField(
                                      controller: currentController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: <TextInputFormatter>[
                                        _decimalNumberInputFormatter,
                                      ],
                                      onChanged: (_) => sheetSetState(() {}),
                                      decoration: inputDecoration(
                                        label: 'ئەمپێر',
                                        suffix: 'A',
                                        error: hasCurrent && !validCurrent
                                            ? 'ژمارەیەکی گەورەتر لە سفر بنووسە'
                                            : null,
                                      ),
                                    ),
                                    TextField(
                                      controller: powerController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      inputFormatters: <TextInputFormatter>[
                                        _decimalNumberInputFormatter,
                                      ],
                                      onChanged: (_) => sheetSetState(() {}),
                                      decoration: inputDecoration(
                                        label: 'وات',
                                        suffix: 'W',
                                        error: hasPower && !validPower
                                            ? 'ژمارەیەکی گەورەتر لە سفر بنووسە'
                                            : null,
                                      ),
                                    ),
                                  ];
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      for (final field in fields)
                                        SizedBox(
                                          width: fieldWidth,
                                          child: field,
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              sectionTitle(
                                title: 'ئەنجامەکان',
                                icon: Icons.functions_outlined,
                              ),
                              const SizedBox(height: 10),
                              resultRow(
                                label: 'توانی گشتی',
                                value: canCalculatePower
                                    ? '≈ ${formatCalcNum(apparentPower, fractionDigits: 2)} VA'
                                    : '--',
                                icon: Icons.electric_meter_outlined,
                              ),
                              const SizedBox(height: 9),
                              resultRow(
                                label: 'ئەمپێر لە وات و ڤۆڵتەج',
                                value: canCalculateCurrent
                                    ? '≈ ${formatCalcNum(calculatedCurrent)} A'
                                    : '--',
                                icon: Icons.electric_meter_outlined,
                              ),
                              const SizedBox(height: 9),
                              resultRow(
                                label: 'ڤۆڵتەج لە وات و ئەمپێر',
                                value: canCalculateVoltage
                                    ? '≈ ${formatCalcNum(calculatedVoltage)} V'
                                    : '--',
                                icon: Icons.power_outlined,
                              ),
                              const SizedBox(height: 20),
                              ExpansionTile(
                                title: const Text(
                                  'فۆرمولە و ڕوونکردنەوە',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                tilePadding: EdgeInsets.zero,
                                iconColor: _dashboardIcon,
                                collapsedIconColor: _dashboardIcon,
                                shape: const Border(),
                                collapsedShape: const Border(),
                                maintainState: true,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: mutedSurface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: border),
                                    ),
                                    child: Column(
                                      children: [
                                        formulaRow(
                                          title: 'توانی گشتی (VA)',
                                          formula: buildFormula(
                                            valid: canCalculatePower,
                                            left: 'S',
                                            expression:
                                                '${formatCalcNum(voltage)} × ${formatCalcNum(current)}',
                                            result: formatCalcNum(
                                              apparentPower,
                                              fractionDigits: 2,
                                            ),
                                            unit: 'VA',
                                          ),
                                          description:
                                              'ڤۆڵتەج لە ئەمپێر بکە بۆ دۆزینەوەی توانی گشتی.',
                                        ),
                                        Divider(height: 1, color: border),
                                        formulaRow(
                                          title: 'ئەمپێر (A)',
                                          formula: buildFormula(
                                            valid: canCalculateCurrent,
                                            left: 'I',
                                            expression:
                                                '${formatCalcNum(power)} ÷ ${formatCalcNum(voltage)}',
                                            result: formatCalcNum(
                                              calculatedCurrent,
                                            ),
                                            unit: 'A',
                                          ),
                                          description:
                                              'وات دابەش بە ڤۆڵتەج بکە بۆ دۆزینەوەی ئەمپێر.',
                                        ),
                                        Divider(height: 1, color: border),
                                        formulaRow(
                                          title: 'ڤۆڵتەج (V)',
                                          formula: buildFormula(
                                            valid: canCalculateVoltage,
                                            left: 'V',
                                            expression:
                                                '${formatCalcNum(power)} ÷ ${formatCalcNum(current)}',
                                            result: formatCalcNum(
                                              calculatedVoltage,
                                            ),
                                            unit: 'V',
                                          ),
                                          description:
                                              'وات دابەش بە ئەمپێر بکە بۆ دۆزینەوەی ڤۆڵتەج.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } finally {
      _disposeControllersAfterSheetClose([
        voltageController,
        currentController,
        powerController,
      ]);
    }
  }

  String? _buildCalculatorTierHint({
    required ElectricityTariffProfile profile,
    required double kwh,
  }) {
    if (!profile.isTiered || kwh <= 0) {
      return null;
    }
    final tiers = profile.tiers;
    for (var i = 0; i < tiers.length; i++) {
      final tier = tiers[i];
      final upper = tier.toKwh;
      if (upper == null) {
        final tierRate = _iqdWholeFormatter.format(tier.rateIqd.round());
        return 'بەکارهێنانت لە پلەی کۆتایییە ($tierRate دینار/ kWh).';
      }
      if (kwh <= upper) {
        if (i + 1 >= tiers.length) {
          return null;
        }
        final remaining = upper - kwh;
        final nextRate = _iqdWholeFormatter.format(
          tiers[i + 1].rateIqd.round(),
        );
        if (remaining <= 0.1) {
          return 'نزیکیت لە گۆڕانی پلەی نرخی داهاتوو ($nextRate دینار/ kWh).';
        }
        return '${remaining.toStringAsFixed(1)} kWh ماوە بۆ پلەی داهاتوو ($nextRate دینار/ kWh).';
      }
    }
    return 'بەکارهێنانت لە پلەی بەرزە.';
  }

  double _parseCalculatorNum(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatCycleDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year/$month/$day';
  }

  double _parseBudgetInput(String input) {
    final normalized = input.trim().replaceAll(',', '');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatIqd(num value) {
    return formatIqd(value);
  }

  String _formatIqdPerKwh(num value) {
    return '${_iqdRateFormatter.format(value)} دینار / kWh';
  }

  Future<ElectricityTariffProfile?> _showTariffProfileSheet() {
    final currentProfile = ref.read(electricityTariffProfileProvider);
    final media = MediaQuery.of(context);
    final availableHeight =
        media.size.height - media.padding.top - media.padding.bottom - 12;
    final preferredHeight = (media.size.height * 0.78)
        .clamp(360.0, 560.0)
        .toDouble();
    final sheetHeight = preferredHeight < availableHeight
        ? preferredHeight
        : availableHeight;

    return showModalBottomSheet<ElectricityTariffProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: SizedBox(
            height: sheetHeight,
            child: AppSheetShell(
              title: 'جۆری هاوبەشبوون و نرخی یەکە',
              subtitle: 'نرخی گونجاو بۆ جۆری بەکارهێنانت هەڵبژێرە.',
              icon: Icons.receipt_long_outlined,
              onClose: () => Navigator.of(sheetContext).pop(),
              accentColor: _dashboardIcon,
              showHandle: false,
              expandChild: true,
              maxWidth: 640,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: ListView.separated(
                itemCount: ElectricityTariffCatalog.values.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final profile = ElectricityTariffCatalog.values[index];
                  return _TariffProfileTile(
                    icon: _tariffIconFor(profile),
                    profile: profile,
                    selected: currentProfile.id == profile.id,
                    onTap: () => Navigator.of(sheetContext).pop(profile),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showTariffInfoSheet(ElectricityTariffProfile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const minSheetHeight = 240.0;
              const maxSheetHeight = 620.0;
              const sheetChrome = 40.0;
              final maxAvailableHeight = (constraints.maxHeight - sheetChrome)
                  .clamp(minSheetHeight, constraints.maxHeight)
                  .toDouble();
              final estimatedTierSectionHeight = profile.isTiered
                  ? (profile.tiers.length * 58.0) + 90.0
                  : 54.0;
              final desiredHeight = (230.0 + estimatedTierSectionHeight)
                  .clamp(minSheetHeight, maxSheetHeight)
                  .toDouble();
              final sheetHeight = desiredHeight
                  .clamp(minSheetHeight, maxAvailableHeight)
                  .toDouble();

              var fromKwh = 1;
              final tierRows = <Widget>[];
              for (final tier in profile.tiers) {
                final toKwh = tier.toKwh?.round();
                final rangeLabel = toKwh == null
                    ? '$fromKwh+ kWh'
                    : '$fromKwh-$toKwh kWh';
                tierRows.add(
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _dashboardSubtleSurface,
                      border: Border.all(color: _dashboardBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            rangeLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Text(
                          '${tier.rateIqd.round()} دینار/kWh',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondaryFor(context),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
                if (toKwh != null) {
                  fromKwh = toKwh + 1;
                }
              }

              return SizedBox(
                height: sheetHeight,
                child: AppSheetShell(
                  title: 'زانیاری نرخی کارەبا',
                  subtitle: profile.title,
                  icon: Icons.receipt_long_outlined,
                  onClose: () => Navigator.of(sheetContext).pop(),
                  accentColor: _dashboardIcon,
                  maxWidth: 640,
                  showHandle: false,
                  expandChild: true,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _dashboardSubtleSurface,
                          border: Border.all(color: _dashboardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.title,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              profile.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tariffRateLabel(profile),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: profile.isTiered
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'پلەکانی نرخ:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    ...tierRows,
                                  ],
                                )
                              : Text(
                                  'ئەم جۆرە نرخێکی یەکسانی هەیە بۆ هەموو بەکارهێنان.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _tariffIconFor(ElectricityTariffProfile profile) {
    switch (profile.id) {
      case 'commercial':
        return Icons.storefront_outlined;
      case 'large_industrial':
        return Icons.factory_outlined;
      case 'industrial':
        return Icons.precision_manufacturing_outlined;
      case 'governmental':
        return Icons.account_balance_outlined;
      case 'agricultural':
        return Icons.agriculture_outlined;
      case 'household_tiered':
      default:
        return Icons.home_outlined;
    }
  }

  Future<_OutageAction?> _showOutageActionSheet({
    required bool isTrackingActive,
  }) {
    return showModalBottomSheet<_OutageAction>(
      context: context,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: AppSheetShell(
            title: 'قەطعبوونی کارەبا',
            subtitle: 'شێوازی تۆمارکردنی کات هەڵبژێرە.',
            icon: Icons.power_settings_new_outlined,
            onClose: () => Navigator.of(sheetContext).pop(),
            accentColor: _dashboardIcon,
            maxWidth: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _OutageSheetTile(
                  icon: isTrackingActive
                      ? Icons.stop_circle_outlined
                      : Icons.play_circle_outline_rounded,
                  title: isTrackingActive
                      ? 'وەستاندنی تۆمارکردن'
                      : 'دەستپێکردنی تۆمارکردن',
                  subtitle: isTrackingActive
                      ? 'خولەکە تۆمارکراوەکان ئێستا پاشەکەوت بکە'
                      : 'کاتژمێر دەست پێ بکە کاتێک کارەبا قەطع دەبێت',
                  onTap: () {
                    Navigator.of(sheetContext).pop(
                      isTrackingActive
                          ? _OutageAction.stopTracking
                          : _OutageAction.startTracking,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _OutageSheetTile(
                  icon: Icons.edit_outlined,
                  title: 'دەستکاری دەستی (ئەمڕۆ)',
                  subtitle: 'خولەکەکانی قەطعبوون ڕاستەوخۆ دیاری بکە',
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_OutageAction.manualEdit),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int?> _showOutageDialog(int initialMinutes) async {
    final safeInitial = initialMinutes.clamp(0, 1440).toInt();
    return showGeneralDialog<int>(
      context: context,
      barrierLabel: 'manual_outage_dialog',
      barrierDismissible: true,
      barrierColor: const Color(0x9E000000),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) {
        return _ManualOutageDialog(initialMinutes: safeInitial);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _RunakiAboutDialog extends StatelessWidget {
  const _RunakiAboutDialog({required this.versionLabel});

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    final maxHeight = (MediaQuery.sizeOf(context).height * 0.9)
        .clamp(420.0, 620.0)
        .toDouble();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460, maxHeight: maxHeight),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: _dashboardSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _dashboardBorder),
                  ),
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AppModalCloseButton(
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Center(
                              child: Container(
                                width: 78,
                                height: 78,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: _dashboardSubtleSurface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: _dashboardBorder),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/img/icon.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'دەربارەی ڕووناکی',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.1,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'وەشانی $versionLabel',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textSecondaryFor(context),
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'ڕووناکی یارمەتیت دەدات بە بەڕێوەبردنی بەکارهێنانی کارەبا، تێچوو و کاتی قەطعبوون بە شێوەیەکی ئاسان و ورد.',
                              textAlign: TextAlign.center,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(height: 1.45),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: const [
                                _AboutFeatureChip(
                                  icon: Icons.electrical_services_outlined,
                                  label: 'تێچووی ڕۆژانە',
                                ),
                                _AboutFeatureChip(
                                  icon: Icons.power_outlined,
                                  label: 'کۆنترۆڵی قەطعبوون',
                                ),
                                _AboutFeatureChip(
                                  icon: Icons.history_outlined,
                                  label: 'مێژووی تۆمارکراو',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Powered by BARHAM',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textSecondaryFor(context),
                                    letterSpacing: 0.2,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: AppButton(
                                    label: 'داخستن',
                                    icon: Icons.check_rounded,
                                    variant: AppButtonVariant.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    fontSize: 12.5,
                                    iconSize: 16,
                                    borderRadius: 11,
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutFeatureChip extends StatelessWidget {
  const _AboutFeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: _dashboardSubtleSurface,
        border: Border.all(color: _dashboardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _dashboardIcon),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualOutageDialog extends StatefulWidget {
  const _ManualOutageDialog({required this.initialMinutes});

  final int initialMinutes;

  @override
  State<_ManualOutageDialog> createState() => _ManualOutageDialogState();
}

class _ManualOutageDialogState extends State<_ManualOutageDialog> {
  static const _maxMinutes = 1440;
  static const _presets = <int>[0, 15, 30, 60, 120, 180, 240, 360];

  late final TextEditingController _controller;
  late int _minutes;
  String? _error;

  @override
  void initState() {
    super.initState();
    _minutes = widget.initialMinutes;
    _controller = TextEditingController(text: _minutes.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setMinutes(int value) {
    final next = value.clamp(0, _maxMinutes).toInt();
    setState(() {
      _minutes = next;
      _error = null;
      final text = next.toString();
      if (_controller.text != text) {
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
      }
    });
  }

  void _onTextChanged(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      setState(() {
        _error = null;
      });
      return;
    }

    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 0 || parsed > _maxMinutes) {
      setState(() {
        _error = 'تکایە ژمارەیەک لە نێوان 0 و 1440 بنووسە.';
      });
      return;
    }

    _setMinutes(parsed);
  }

  void _submit() {
    final parsed = int.tryParse(_controller.text.trim());
    if (parsed == null || parsed < 0 || parsed > _maxMinutes) {
      setState(() {
        _error = 'تکایە ژمارەیەک لە نێوان 0 و 1440 بنووسە.';
      });
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  String _formatDuration(int minutes) {
    final safe = minutes.clamp(0, _maxMinutes).toInt();
    final hours = safe ~/ 60;
    final rest = safe % 60;
    if (hours == 0) {
      return '$safe خولەک';
    }
    if (rest == 0) {
      return '$hours کاتژمێر';
    }
    return '$hours کاتژمێر و $rest خولەک';
  }

  String _severityLabel(double outagePercent) {
    if (outagePercent < 15) {
      return 'کەم';
    }
    if (outagePercent < 35) {
      return 'مامناوەند';
    }
    return 'زۆر';
  }

  @override
  Widget build(BuildContext context) {
    const accent = _dashboardSelected;

    final uptimePercent = ((_maxMinutes - _minutes) / _maxMinutes * 100)
        .clamp(0, 100)
        .toDouble();
    final outagePercent = (_minutes / _maxMinutes * 100)
        .clamp(0, 100)
        .toDouble();
    final availableMinutes = (_maxMinutes - _minutes)
        .clamp(0, _maxMinutes)
        .toInt();
    final severityText = _severityLabel(outagePercent);

    final maxHeight = (MediaQuery.sizeOf(context).height * 0.84)
        .clamp(420, 620)
        .toDouble();

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 440, maxHeight: maxHeight),
            child: Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: _dashboardSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _dashboardBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _dashboardSubtleSurface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _dashboardBorder),
                              ),
                              child: Icon(
                                Icons.power_off_outlined,
                                size: 18,
                                color: _dashboardIcon,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'دەستکاری قەطعبوونی کارەبا',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'تۆماری خولەکەکانی ئەمڕۆ',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondaryFor(
                                            context,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            AppModalCloseButton(
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _dashboardBorder),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final tileWidth =
                                      (constraints.maxWidth - 8) / 2;
                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      SizedBox(
                                        width: tileWidth,
                                        child: _ManualOutageMetricTile(
                                          icon: Icons.timer_outlined,
                                          label: 'کۆی قەطعبوون',
                                          value: _formatDuration(_minutes),
                                        ),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _ManualOutageMetricTile(
                                          icon: Icons
                                              .check_circle_outline_rounded,
                                          label: 'بەردەوامی',
                                          value:
                                              '${uptimePercent.toStringAsFixed(1)}%',
                                        ),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _ManualOutageMetricTile(
                                          icon: Icons.power_outlined,
                                          label: 'کاتی هەبوونی کارەبا',
                                          value: _formatDuration(
                                            availableMinutes,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: tileWidth,
                                        child: _ManualOutageMetricTile(
                                          icon: Icons.insights_outlined,
                                          label: 'ئاستی قەطعبوون',
                                          value:
                                              '$severityText (${outagePercent.toStringAsFixed(1)}%)',
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'هەڵبژاردەی خێرا:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _presets
                                    .map(
                                      (value) => _OutagePresetChip(
                                        value: value,
                                        selected: _minutes == value,
                                        onTap: () => _setMinutes(value),
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: _dashboardSurface,
                                  border: Border.all(color: _dashboardBorder),
                                ),
                                child: TextField(
                                  controller: _controller,
                                  keyboardType: TextInputType.number,
                                  textInputAction: TextInputAction.done,
                                  onChanged: _onTextChanged,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '0 - 1440',
                                    labelText: 'خولەکی قەطعبوون',
                                    suffixText: 'خولەک',
                                    prefixIcon: Icon(
                                      Icons.edit_calendar_outlined,
                                      size: 18,
                                      color: _dashboardIcon,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 11,
                                    ),
                                    border: InputBorder.none,
                                    errorText: _error,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: accent,
                                  inactiveTrackColor: _dashboardBorder,
                                  thumbColor: accent,
                                  overlayColor: Colors.transparent,
                                  trackHeight: 3.6,
                                ),
                                child: Slider(
                                  value: _minutes.toDouble(),
                                  min: 0,
                                  max: _maxMinutes.toDouble(),
                                  divisions: 96,
                                  onChanged: (value) {
                                    _setMinutes(value.round());
                                  },
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '0',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '1440',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: _dashboardBorder),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'هەڵوەشاندنەوە',
                                icon: Icons.close_rounded,
                                variant: AppButtonVariant.ghost,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                fontSize: 12.5,
                                iconSize: 16,
                                borderRadius: 10,
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: AppButton(
                                label: 'پاشەکەوتکردن',
                                icon: Icons.check_rounded,
                                variant: AppButtonVariant.primary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 9,
                                ),
                                fontSize: 12.5,
                                iconSize: 16,
                                borderRadius: 10,
                                onPressed: _submit,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ManualOutageMetricTile extends StatelessWidget {
  const _ManualOutageMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _dashboardSubtleSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _dashboardBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: _dashboardIcon),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryFor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutagePresetChip extends StatelessWidget {
  const _OutagePresetChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _dashboardSelectedSurface : _dashboardSubtleSurface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? _dashboardSelected : _dashboardBorder,
          ),
        ),
        child: Text(
          '$value خولەک',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: selected ? _dashboardSelected : _dashboardMutedText,
          ),
        ),
      ),
    );
  }
}

class _OutageSheetTile extends StatelessWidget {
  const _OutageSheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _dashboardSubtleSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _dashboardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _dashboardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _dashboardBorder),
              ),
              child: Icon(icon, color: _dashboardIcon, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_left_rounded,
              textDirection: TextDirection.ltr,
              size: 20,
              color: _dashboardIcon,
            ),
          ],
        ),
      ),
    );
  }
}

class _TariffProfileTile extends StatelessWidget {
  const _TariffProfileTile({
    required this.icon,
    required this.profile,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final ElectricityTariffProfile profile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const primary = _dashboardSelected;
    const border = _dashboardBorder;
    const secondaryText = _dashboardMutedText;
    return Material(
      color: selected ? _dashboardSelectedSurface : _dashboardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _dashboardSubtleSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _dashboardBorder),
                ),
                child: Icon(icon, size: 20, color: _dashboardIcon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${profile.description} • ${tariffRateLabel(profile)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondaryText,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.check_circle_outline_rounded
                    : Icons.radio_button_off_rounded,
                size: 21,
                color: _dashboardIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HouseProfileCard extends StatelessWidget {
  const _HouseProfileCard({
    required this.state,
    required this.onSelectProfile,
    required this.onAddTap,
    required this.onRenameProfile,
    required this.onDeleteProfile,
  });

  final HouseProfileState state;
  final Future<void> Function(String profileId) onSelectProfile;
  final Future<void> Function() onAddTap;
  final Future<void> Function(HouseProfile profile) onRenameProfile;
  final Future<void> Function(HouseProfile profile) onDeleteProfile;

  @override
  Widget build(BuildContext context) {
    final compact = _DashboardResponsive.isCompactDialog(
      MediaQuery.of(context),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _DashboardStrings.profileListTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryFor(context),
                ),
              ),
            ),
            _ProfileActionButton(
              label: _DashboardStrings.add,
              icon: Icons.add_rounded,
              compact: compact,
              onPressed: () => unawaited(onAddTap()),
            ),
          ],
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < state.profiles.length; index++) ...[
          _HouseProfilePill(
            profile: state.profiles[index],
            selected: state.profiles[index].id == state.selectedProfileId,
            compact: compact,
            canDelete: state.profiles.length > 1,
            onTap: () => unawaited(onSelectProfile(state.profiles[index].id)),
            onRename: () => unawaited(onRenameProfile(state.profiles[index])),
            onDelete: () => unawaited(onDeleteProfile(state.profiles[index])),
          ),
          if (index != state.profiles.length - 1)
            SizedBox(height: compact ? 8 : 10),
        ],
      ],
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.label,
    required this.icon,
    required this.compact,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: label,
      icon: icon,
      iconSize: compact ? 15 : 16,
      fontSize: compact ? 11.5 : 12.5,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 9,
      ),
      borderRadius: 11,
      variant: AppButtonVariant.outline,
      backgroundColor: _dashboardSurface,
      borderColor: _dashboardBorder,
      textColor: _dashboardIcon,
      onPressed: onPressed,
    );
  }
}

class _HouseProfilePill extends StatelessWidget {
  const _HouseProfilePill({
    required this.profile,
    required this.selected,
    required this.compact,
    required this.canDelete,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final HouseProfile profile;
  final bool selected;
  final bool compact;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.primaryFor(context);
    const border = _dashboardBorder;
    const secondaryText = _dashboardMutedText;

    return Material(
      color: selected ? _dashboardSelectedSurface : _dashboardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: BoxConstraints(minHeight: compact ? 58 : 64),
          padding: EdgeInsetsDirectional.fromSTEB(compact ? 10 : 12, 8, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: _dashboardSubtleSurface,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: _dashboardBorder),
                ),
                child: Icon(
                  Icons.home_outlined,
                  size: compact ? 18 : 20,
                  color: _dashboardIcon,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected
                          ? _DashboardStrings.selected
                          : _DashboardStrings.choose,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected ? primary : secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 20,
                    color: _dashboardIcon,
                  ),
                ),
              PopupMenuButton<String>(
                tooltip: _DashboardStrings.menuOptions,
                padding: EdgeInsets.zero,
                splashRadius: 18,
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: _dashboardIcon,
                ),
                itemBuilder: (ctx) => [
                  const PopupMenuItem<String>(
                    value: 'rename',
                    child: Text(_DashboardStrings.rename),
                  ),
                  if (canDelete)
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(_DashboardStrings.delete),
                    ),
                ],
                onSelected: (value) {
                  if (value == 'rename') {
                    onRename();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsDrawer extends StatelessWidget {
  const _SettingsDrawer({
    required this.selectedTariffProfile,
    required this.selectedHouseProfileName,
    required this.budgetSubtitle,
    required this.versionLabel,
    required this.onHouseProfileTap,
    required this.onBudgetTap,
    required this.onTariffTap,
    required this.onAboutTap,
  });

  final ElectricityTariffProfile selectedTariffProfile;
  final String selectedHouseProfileName;
  final String budgetSubtitle;
  final String versionLabel;
  final Future<void> Function() onHouseProfileTap;
  final Future<void> Function() onBudgetTap;
  final Future<void> Function() onTariffTap;
  final Future<void> Function() onAboutTap;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ڕێکخستنەکان',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  AppModalCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _dashboardBorder),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  DashboardActionRow(
                    icon: Icons.home_work_outlined,
                    title: _DashboardStrings.profileTitle,
                    subtitle: selectedHouseProfileName,
                    onTap: () => unawaited(onHouseProfileTap()),
                  ),
                  const Divider(height: 1, color: _dashboardBorder),
                  DashboardActionRow(
                    icon: Icons.price_change_outlined,
                    title: 'جۆری هاوبەشبوون',
                    subtitle:
                        '${selectedTariffProfile.title} • ${tariffRateLabel(selectedTariffProfile)}',
                    onTap: () => unawaited(onTariffTap()),
                  ),
                  const Divider(height: 1, color: _dashboardBorder),
                  DashboardActionRow(
                    icon: Icons.savings_outlined,
                    title: 'بەدجەتی مانگانە',
                    subtitle: budgetSubtitle,
                    onTap: () => unawaited(onBudgetTap()),
                  ),
                  const Divider(height: 1, color: _dashboardBorder),
                  DashboardActionRow(
                    icon: Icons.info_outline,
                    title: 'دەربارە',
                    subtitle: 'زانیاری بەرنامە و وەشان',
                    onTap: () => unawaited(onAboutTap()),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'وەشان $versionLabel',
                style: const TextStyle(
                  color: _dashboardMutedText,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
