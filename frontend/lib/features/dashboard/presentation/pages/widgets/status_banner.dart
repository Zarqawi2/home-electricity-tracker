import 'package:flutter/material.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    this.backgroundColor = const Color(0xFFFFF3CD),
    this.textColor = const Color(0xFF856404),
    this.icon = Icons.wifi_off,
  });

  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
