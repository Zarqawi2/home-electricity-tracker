import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class AppResponsive {
  const AppResponsive._();

  static double shortestSide(MediaQueryData media) =>
      math.min(media.size.width, media.size.height);

  static bool isCompact(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < 390 || size.height < 700;
  }

  static bool isVerySmall(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width < 360 || size.height < 640;
  }

  static double scaleFactor(MediaQueryData media) {
    final shortest = shortestSide(media);
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
    final scaled = (baseScale * scaleFactor(media)).clamp(min, max).toDouble();
    return TextScaler.linear(scaled);
  }

  static double sp(
    BuildContext context,
    double base, {
    double? min,
    double? max,
  }) {
    final media = MediaQuery.of(context);
    final scaled = base * scaleFactor(media);
    if (min == null && max == null) return scaled;
    return scaled
        .clamp(min ?? double.negativeInfinity, max ?? double.infinity)
        .toDouble();
  }

  static EdgeInsets dialogInsets(
    BuildContext context, {
    double horizontal = 20,
    double vertical = 16,
  }) {
    final media = MediaQuery.of(context);
    final isCompactWidth = media.size.width < 390;
    return EdgeInsets.symmetric(
      horizontal: isCompactWidth
          ? sp(context, horizontal * 0.7, min: 10, max: horizontal)
          : sp(context, horizontal, min: 14, max: 28),
      vertical: sp(context, vertical, min: 10, max: 24),
    );
  }

  static double maxDialogHeight(
    BuildContext context, {
    double ratio = 0.9,
    double min = 260,
    double max = 760,
    double reservedVertical = 8,
  }) {
    final media = MediaQuery.of(context);
    final available =
        media.size.height -
        media.padding.top -
        media.padding.bottom -
        media.viewInsets.bottom -
        reservedVertical;
    return math.min(available, media.size.height * ratio).clamp(min, max);
  }
}
