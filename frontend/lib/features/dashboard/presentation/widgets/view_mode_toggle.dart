import "package:flutter/material.dart";

import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/view_mode.dart';
import '../utils/dashboard_responsive.dart';

class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final DashboardViewMode mode;
  final ValueChanged<DashboardViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final compact = DashboardResponsive.isCompact(context);
    final horizontal = DashboardResponsive.sp(
      context,
      compact ? 11 : 14,
      min: 10,
      max: 16,
    );
    final vertical = DashboardResponsive.sp(
      context,
      compact ? 8 : 10,
      min: 7,
      max: 11,
    );
    final fontSize = DashboardResponsive.sp(
      context,
      compact ? 12 : 13,
      min: 11,
      max: 14,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: 'ڕۆژانە',
          variant: AppButtonVariant.segment,
          selected: mode == DashboardViewMode.daily,
          onPressed: () => onChanged(DashboardViewMode.daily),
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          fontSize: fontSize,
          borderRadius: 10,
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'مانگانە',
          variant: AppButtonVariant.segment,
          selected: mode == DashboardViewMode.monthly,
          onPressed: () => onChanged(DashboardViewMode.monthly),
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          fontSize: fontSize,
          borderRadius: 10,
        ),
      ],
    );
  }
}
