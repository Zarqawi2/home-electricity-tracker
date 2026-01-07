import "package:flutter/material.dart";

import '../../domain/entities/view_mode.dart';
import '../../../../core/widgets/app_button.dart';

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: 'ڕۆژانە',
          variant: AppButtonVariant.segment,
          selected: mode == DashboardViewMode.daily,
          onPressed: () => onChanged(DashboardViewMode.daily),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: 10,
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'مانگانە',
          variant: AppButtonVariant.segment,
          selected: mode == DashboardViewMode.monthly,
          onPressed: () => onChanged(DashboardViewMode.monthly),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          borderRadius: 10,
        ),
      ],
    );
  }
}
