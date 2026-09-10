import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.backgroundColor,
    this.textColor,
    this.icon = Icons.wifi_off,
  });

  final String message;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final effectiveBackground =
        backgroundColor ?? AppColors.surfaceFor(context);
    final effectiveText = textColor ?? AppColors.textPrimaryFor(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Icon(icon, color: effectiveText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: effectiveText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
