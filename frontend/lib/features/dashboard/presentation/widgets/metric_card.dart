import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../utils/dashboard_responsive.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final titleSize = DashboardResponsive.sp(context, 13, min: 11, max: 14);
    final valueSize = DashboardResponsive.sp(context, 24, min: 18, max: 26);
    final subtitleSize = DashboardResponsive.sp(context, 12, min: 10, max: 13);
    final badgeSize = DashboardResponsive.sp(context, 46, min: 40, max: 50);
    final badgeIconSize = DashboardResponsive.sp(context, 22, min: 18, max: 24);
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.bodyMedium?.copyWith(fontSize: titleSize),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: valueSize,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondaryFor(context),
                    fontWeight: FontWeight.w600,
                    fontSize: subtitleSize,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: badgeSize,
            height: badgeSize,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF0F172A),
              size: badgeIconSize,
            ),
          ),
        ],
      ),
    );
  }
}
