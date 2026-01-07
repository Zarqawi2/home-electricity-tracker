import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key, this.onRefresh, this.isRefreshing = false});

  final VoidCallback? onRefresh;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/img/icon.png',
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'خەرجی کارەباکەت بزانە',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'بەکارهێنان، خەرجی و زانیاری ئامێرەکان لە یەک شوێن چاودێری بکە.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onRefresh != null)
            IconButton(
              icon: isRefreshing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              color: AppColors.primary,
              onPressed: isRefreshing ? null : onRefresh,
              tooltip: 'نوێکردنەوە',
            ),
        ],
      ),
    );
  }
}
