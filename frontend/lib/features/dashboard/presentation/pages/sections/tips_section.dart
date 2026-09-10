import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_card.dart';
import '../../utils/dashboard_responsive.dart';

class TipsSection extends StatelessWidget {
  const TipsSection({super.key, required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'چۆن بەکارهێنانی کارەبا کەم بکەینەوە؟',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 10),
          if (tips.isEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.textPrimaryFor(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هێشتا هیچ پێشنیارێک نییە.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          else
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '-',
                      style: TextStyle(
                        color: AppColors.textPrimaryFor(context),
                        fontSize: DashboardResponsive.sp(
                          context,
                          16,
                          min: 13,
                          max: 17,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium,
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
