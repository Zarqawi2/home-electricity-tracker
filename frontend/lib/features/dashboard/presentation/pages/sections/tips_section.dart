import 'package:flutter/material.dart';

import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/widgets/app_card.dart';

class TipsSection extends StatelessWidget {
  const TipsSection({super.key, required this.tips});

  final List<String> tips;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: const Color(0xFFF1F5FF),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'پێشنیارەکانی کەمکردنەوەی خەرجی کارەبا',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          if (tips.isEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'هێشتا هیچ پێشنیارێک بوونی نییە.',
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
                    const Text(
                      '-',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
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
