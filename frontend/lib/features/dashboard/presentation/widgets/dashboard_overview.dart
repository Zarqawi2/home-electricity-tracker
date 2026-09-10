import 'package:flutter/material.dart';
import '../../../../core/formatters/currency_formatter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/dashboard_summary.dart';

/// A concise view of the current estimate, separate from historical readings.
class DashboardOverview extends StatelessWidget {
  const DashboardOverview({
    super.key,
    required this.summary,
    required this.houseName,
    required this.tariffLabel,
    required this.monthlyBudgetIqd,
    required this.isLoading,
    required this.onBudgetTap,
    required this.onTariffTap,
    required this.onAppliancesTap,
    required this.onOutageTap,
  });

  final DashboardSummary? summary;
  final String houseName;
  final String tariffLabel;
  final double? monthlyBudgetIqd;
  final bool isLoading;
  final VoidCallback onBudgetTap;
  final VoidCallback onTariffTap;
  final VoidCallback onAppliancesTap;
  final VoidCallback onOutageTap;

  String _money(double value) => formatIqd(value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final ready = !isLoading && summary != null;
    final bill = ready ? _money(summary!.estimatedCost) : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? 20 : 32),
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                houseName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleMedium?.copyWith(
                  color: AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'خەمڵاندنی تێچووی ئەم مانگە',
                style: theme.titleMedium?.copyWith(
                  color: AppColors.lightTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    bill,
                    style: theme.displaySmall?.copyWith(
                      fontSize: compact ? 36 : 48,
                      color: AppColors.lightTextPrimary,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'بۆ ڕۆژەکانی ئەم مانگە، بەپێی ئامێرە چالاکەکان و کاتی بەکارهێنانی ئێستا. ئەنجامەکە خەمڵاندنە.',
                style: theme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _UsageValue(
                      label: 'خەمڵاندنی ڕۆژانە',
                      value: ready ? summary!.dailyKwh.toStringAsFixed(2) : '—',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _UsageValue(
                      label: 'خەمڵاندنی ئەم مانگە',
                      value: ready
                          ? summary!.monthlyKwh.toStringAsFixed(2)
                          : '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.lightBorder),
              _buildBudget(context, ready),
              const Divider(height: 1, color: AppColors.lightBorder),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppButton(
                    label: 'ئامێرەکان',
                    icon: Icons.electrical_services_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: onAppliancesTap,
                  ),
                  AppButton(
                    label: summary?.outageTrackingActive == true
                        ? 'کۆتایی قەطعبوون'
                        : 'تۆماری قەطعبوون',
                    icon: Icons.power_off_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: onOutageTap,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onTariffTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.lightTextSecondary,
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(48, 48),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'نرخی کارەبا: $tariffLabel',
                        style: theme.bodySmall?.copyWith(
                          color: AppColors.lightTextSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_left,
                      textDirection: TextDirection.ltr,
                      size: 18,
                      color: AppColors.lightTextPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudget(BuildContext context, bool ready) {
    final theme = Theme.of(context).textTheme;
    final budget = monthlyBudgetIqd;
    final hasBudget = budget != null && budget.isFinite && budget > 0;
    final ratio = hasBudget && ready ? summary!.estimatedCost / budget : null;
    final description = !hasBudget
        ? 'سنوورێک بۆ خەرجی مانگانەت دابنێ'
        : !ready
        ? 'سنوور: ${_money(budget)}'
        : '${_money(summary!.estimatedCost)} لە ${_money(budget)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onBudgetTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 20,
                    color: AppColors.lightTextPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'بەدجەتی مانگانە',
                      style: theme.titleSmall?.copyWith(
                        color: AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (ratio != null) ...[
                    Text(
                      '${(ratio * 100).round()}%',
                      style: theme.labelLarge?.copyWith(
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(
                    Icons.chevron_left,
                    textDirection: TextDirection.ltr,
                    size: 20,
                    color: AppColors.lightTextPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                description,
                style: theme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                  height: 1.5,
                ),
              ),
              if (ratio != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                  backgroundColor: AppColors.lightBorder,
                  color: AppColors.lightTextPrimary,
                  semanticsLabel: 'خەمڵاندنی بەکارهێنانی بەدجەت',
                  semanticsValue: '${(ratio * 100).round()}%',
                ),
                if (ratio > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    'خەمڵاندنەکە ${_money(summary!.estimatedCost - budget!)} لە سنوورەکەت زیاترە.',
                    style: theme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageValue extends StatelessWidget {
  const _UsageValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.bodySmall?.copyWith(color: AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 6),
        Text.rich(
          TextSpan(
            text: value,
            children: [
              TextSpan(
                text: ' kWh',
                style: theme.bodySmall?.copyWith(
                  color: AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          textDirection: TextDirection.ltr,
          style: theme.titleLarge?.copyWith(
            color: AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
