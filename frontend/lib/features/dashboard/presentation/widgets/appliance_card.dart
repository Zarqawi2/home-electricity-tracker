import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/appliance.dart';

class ApplianceCard extends StatelessWidget {
  const ApplianceCard({
    super.key,
    required this.appliance,
    required this.monthlyCost,
    required this.onToggle,
    this.onEdit,
    this.onLongPress,
  });

  final Appliance appliance;
  final double monthlyCost;
  final VoidCallback onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final isOn = appliance.isOn;
    final textTheme = Theme.of(context).textTheme;
    final inactiveColor = AppColors.muted.withOpacity(0.8);
    final baseTextColor = AppColors.textPrimary;
    final inactiveTextColor = AppColors.textSecondary;
    final labelColor = isOn ? AppColors.textSecondary : inactiveTextColor;
    final valueColor = isOn ? baseTextColor : inactiveTextColor;
    final borderColor = isOn
        ? AppColors.primary.withOpacity(0.45)
        : AppColors.cardBorder;
    final surfaceColor = isOn
        ? AppColors.primary.withOpacity(0.03)
        : inactiveColor;

    return InkWell(
      borderRadius: BorderRadius.circular(9),
      splashColor: AppColors.primary.withOpacity(0.05),
      highlightColor: AppColors.primary.withOpacity(0.03),
      onTap: onEdit,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.all(color: borderColor, width: isOn ? 1.5 : 1),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
             
              children: [
                Icon(
                  _iconForCategory(appliance.category, appliance.name),
                  color: isOn ? AppColors.primary : inactiveTextColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appliance.name,
                        style: textTheme.titleSmall?.copyWith(
                          color: isOn ? baseTextColor : inactiveTextColor,
                        ),
                      ),
                     
                      Text(
                        _localizedCategory(appliance.category),
                        style: textTheme.bodySmall?.copyWith(color: labelColor),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Transform.scale(
                    scale: 0.9,
                    child: CupertinoSwitch(
                      value: isOn,
                      activeColor: AppColors.primary,
                      onChanged: (_) => onToggle(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoColumn(
                  label: 'وزە',
                  value: '${appliance.powerW.toStringAsFixed(0)}W',
                  labelColor: labelColor,
                  valueColor: valueColor,
                ),
                _InfoColumn(
                  label: 'بەکارهێنانی ڕۆژانە (کاتژمێر)',
                  value:
                      '${appliance.dailyUseHours.toStringAsFixed(appliance.dailyUseHours % 1 == 0 ? 0 : 1)}h',
                  labelColor: labelColor,
                  valueColor: valueColor,
                ),
                _InfoColumn(
                  label: 'خەرجی مانگانە',
                  value: '${monthlyCost.toStringAsFixed(0)} IQD',
                  labelColor: labelColor,
                  valueColor: valueColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String category, String name) {
    switch (name) {
      case 'Refrigerator':
      case 'ساردکەرەوە':
        return Icons.kitchen;
      case 'Air Conditioner':
      case 'سەرماکەر':
        return Icons.ac_unit;
      case 'LED TV':
      case 'تێلیڤیزیۆنی LED':
        return Icons.tv;
      case 'Washing Machine':
      case 'جلشۆر':
        return Icons.local_laundry_service;
      case 'Water Heater':
      case 'ئاو گەرمکەر':
        return Icons.water_drop;
      case 'Microwave':
      case 'مایکرۆڤێڤ':
        return Icons.microwave;
      default:
        switch (category) {
          case 'Kitchen':
            return Icons.restaurant;
          case 'Entertainment':
            return Icons.movie;
          case 'Climate Control':
            return Icons.waves;
          default:
            return Icons.electrical_services;
        }
    }
  }

  String _localizedCategory(String category) {
    switch (category) {
      case 'Kitchen':
        return 'چێشتخانە';
      case 'Climate Control':
        return 'کۆنترۆلی هەوا';
      case 'Entertainment':
        return 'ئەمەداڵی';
      case 'Laundry':
        return 'جلشۆر';
      case 'Water Heating':
        return 'گەرمکردنی ئاو';
      case 'Other':
        return 'هیتر';
      default:
        return category;
    }
  }
}

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: labelColor,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w400,
            color: valueColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
