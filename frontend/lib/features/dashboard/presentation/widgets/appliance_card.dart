import 'package:flutter/material.dart';

import '../../../../core/formatters/currency_formatter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/appliance.dart';
import '../utils/dashboard_responsive.dart';

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
    final viewport = MediaQuery.sizeOf(context);
    final textColor = AppColors.textPrimaryFor(context);
    final mutedColor = AppColors.textSecondaryFor(context);
    final minutes = (appliance.dailyUseHours * 60).round();
    final hoursText = minutes % 60 == 0
        ? '${minutes ~/ 60} کاتژمێر'
        : '${minutes ~/ 60} کاتژمێر و ${minutes % 60} خولەک';
    final controlColumnWidth = (viewport.width * 0.2)
        .clamp(66.0, 82.0)
        .toDouble();

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Opacity(
            opacity: isOn ? 1 : 0.72,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ApplianceIcon(
                      icon: _iconForCategory(
                        appliance.category,
                        appliance.name,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appliance.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _localizedCategory(appliance.category),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: mutedColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: controlColumnWidth,
                      child: _AppliancePowerToggle(
                        isOn: isOn,
                        onToggle: onToggle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        label: 'توانا',
                        value: formatWatts(appliance.powerW),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoTile(
                        label: 'بەکارهێنانی ڕۆژانە',
                        value: hoursText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'بەشی خەمڵێنراو لە پسووڵەی مانگانە',
                        style: textTheme.bodySmall?.copyWith(color: mutedColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        formatIqd(monthlyCost),
                        style: textTheme.titleSmall?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForCategory(String category, String name) {
    switch (name) {
      case 'Refrigerator':
      case 'ساردکەرەوە':
        return Icons.kitchen_outlined;
      case 'Air Conditioner':
      case 'سەرماکەر':
        return Icons.ac_unit_outlined;
      case 'LED TV':
      case 'تێلیفیزیۆنی LED':
        return Icons.tv_outlined;
      case 'Washing Machine':
      case 'جلشۆر':
        return Icons.local_laundry_service_outlined;
      case 'Water Heater':
      case 'ئاو گەرمکەر':
        return Icons.water_drop_outlined;
      case 'Microwave':
      case 'مایکرۆفێف':
        return Icons.microwave_outlined;
      default:
        switch (category) {
          case 'Kitchen':
            return Icons.restaurant_outlined;
          case 'Entertainment':
            return Icons.movie_outlined;
          case 'Climate Control':
            return Icons.air_outlined;
          case 'Hall':
            return Icons.weekend_outlined;
          case 'Bathroom':
            return Icons.bathtub_outlined;
          case 'Outdoor':
            return Icons.yard_outlined;
          case 'Bedroom':
            return Icons.bed_outlined;
          default:
            return Icons.electrical_services_outlined;
        }
    }
  }

  String _localizedCategory(String category) {
    switch (category) {
      case 'Kitchen':
        return 'چێشتخانە';
      case 'Climate Control':
        return 'کۆنترۆڵی هەوا';
      case 'Entertainment':
        return 'سەرگرمی';
      case 'Laundry':
        return 'جلشۆر';
      case 'Water Heating':
        return 'گەرمکردنی ئاو';
      case 'Hall':
        return 'هۆڵ';
      case 'Bathroom':
        return 'حەمام';
      case 'Outdoor':
        return 'دەرەوە';
      case 'Bedroom':
        return 'ووری خەوتن';
      case 'Other':
        return 'هی تر';
      default:
        return category;
    }
  }
}

class _AppliancePowerToggle extends StatelessWidget {
  const _AppliancePowerToggle({required this.isOn, required this.onToggle});

  final bool isOn;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final trackWidth = DashboardResponsive.sp(context, 64, min: 58, max: 68);
    final trackHeight = DashboardResponsive.sp(context, 32, min: 28, max: 34);
    final knobSize = trackHeight - 6;

    return Semantics(
      button: true,
      toggled: isOn,
      label: isOn ? 'ناچالاککردنی ئامێر' : 'چالاککردنی ئامێر',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: trackWidth,
            height: trackHeight,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isOn
                  ? AppColors.primaryFor(context)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isOn
                    ? AppColors.primaryFor(context)
                    : const Color(0xFFCBD5E1),
              ),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knobSize,
                height: knobSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: const Icon(
                  Icons.power_settings_new_outlined,
                  size: 15,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplianceIcon extends StatelessWidget {
  const _ApplianceIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final size = (MediaQuery.sizeOf(context).width * 0.1)
        .clamp(42.0, 48.0)
        .toDouble();
    return SizedBox(
      width: size,
      height: size,
      child: Icon(icon, size: 21, color: const Color(0xFF0F172A)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelSize = DashboardResponsive.sp(context, 11, min: 10, max: 12);
    final valueSize = DashboardResponsive.sp(context, 12.5, min: 11, max: 13.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.start,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondaryFor(context),
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryFor(context),
              fontSize: valueSize,
            ),
          ),
        ),
      ],
    );
  }
}
