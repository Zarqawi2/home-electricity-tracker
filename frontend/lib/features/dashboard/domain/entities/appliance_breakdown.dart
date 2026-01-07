import 'package:flutter/material.dart';

class ApplianceBreakdown {
  const ApplianceBreakdown({
    required this.name,
    required this.percentage,
    required this.color,
  });

  final String name;
  final double percentage;
  final Color color;
}
