import 'package:flutter/material.dart';
import '../../utils/dashboard_responsive.dart';

enum SnackBarVariant { info, success, error }

void showSnack(
  BuildContext context,
  String message, {
  SnackBarVariant variant = SnackBarVariant.info,
}) {
  final icon = _iconForVariant(variant);
  final messageSize = DashboardResponsive.sp(context, 15, min: 12.5, max: 16);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      elevation: 0,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: Icon(icon, color: Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  color: const Color(0xFF0F172A),
                  fontSize: messageSize,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, color: Color(0xFF334155), size: 20),
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

IconData _iconForVariant(SnackBarVariant variant) {
  switch (variant) {
    case SnackBarVariant.success:
      return Icons.check_circle_outline;
    case SnackBarVariant.error:
      return Icons.error_outline;
    case SnackBarVariant.info:
      return Icons.info_outline;
  }
}
