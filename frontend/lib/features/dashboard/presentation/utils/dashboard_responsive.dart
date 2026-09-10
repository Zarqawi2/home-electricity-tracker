import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class DashboardResponsive {
  const DashboardResponsive._();

  static double _shortestSide(MediaQueryData media) =>
      math.min(media.size.width, media.size.height);

  static bool isCompact(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < 390 || size.height < 700;
  }

  static double textScaleFactor(MediaQueryData media) {
    final shortest = _shortestSide(media);
    if (shortest < 320) return 0.84;
    if (shortest < 360) return 0.9;
    if (shortest < 390) return 0.95;
    if (shortest < 430) return 0.98;
    if (shortest < 520) return 1.0;
    if (shortest < 700) return 1.04;
    return 1.08;
  }

  static TextScaler textScaler(
    MediaQueryData media, {
    double min = 0.86,
    double max = 1.18,
  }) {
    final baseScale = media.textScaler.scale(1.0);
    final responsiveScale = (baseScale * textScaleFactor(media))
        .clamp(min, max)
        .toDouble();
    return TextScaler.linear(responsiveScale);
  }

  static double sp(
    BuildContext context,
    double base, {
    double? min,
    double? max,
  }) {
    final media = MediaQuery.of(context);
    final scaled = base * textScaleFactor(media);
    if (min == null && max == null) return scaled;
    return scaled
        .clamp(min ?? double.negativeInfinity, max ?? double.infinity)
        .toDouble();
  }
}
