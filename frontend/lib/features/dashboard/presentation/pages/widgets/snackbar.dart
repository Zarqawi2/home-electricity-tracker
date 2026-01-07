import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

enum SnackBarVariant { info, success, error }

void showSnack(
  BuildContext context,
  String message, {
  SnackBarVariant variant = SnackBarVariant.info,
}) {
  final color = _colorForVariant(variant);
  final icon = _iconForVariant(variant);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.95), color.withOpacity(0.85)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 20,
              ),
              onPressed: () =>
                  ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              splashRadius: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

Color _colorForVariant(SnackBarVariant variant) {
  switch (variant) {
    case SnackBarVariant.success:
      return AppColors.positive;
    case SnackBarVariant.error:
      return AppColors.negative;
    case SnackBarVariant.info:
    default:
      return AppColors.primary;
  }
}

IconData _iconForVariant(SnackBarVariant variant) {
  switch (variant) {
    case SnackBarVariant.success:
      return Icons.check_rounded;
    case SnackBarVariant.error:
      return Icons.error_rounded;
    case SnackBarVariant.info:
    default:
      return Icons.info_rounded;
  }
}
