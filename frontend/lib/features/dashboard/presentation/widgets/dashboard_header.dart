import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    this.onOutageTap,
    this.onProfileTap,
    this.onMenuTap,
    this.isOutageTrackingActive = false,
    this.outageTrackingStartedAt,
    this.houseName = '',
  });

  static const _outageTooltip =
      '\u06a9\u0627\u062a\u06cc \u0642\u06d5\u0637\u0639\u0628\u0648\u0648\u0646\u06cc \u06a9\u0627\u0631\u06d5\u0628\u0627 \u062f\u06cc\u0627\u0631\u06cc \u0628\u06a9\u06d5';
  static const _settingsTooltip =
      '\u0695\u06ce\u06a9\u062e\u0633\u062a\u0646\u06d5\u06a9\u0627\u0646';
  static const _profileTooltip =
      '\u06af\u06c6\u0695\u06cc\u0646\u06cc \u067e\u0631\u06c6\u0641\u0627\u06cc\u0644\u06cc \u0645\u0627\u06b5';

  final VoidCallback? onOutageTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onMenuTap;
  final bool isOutageTrackingActive;
  final DateTime? outageTrackingStartedAt;
  final String houseName;

  static double preferredContentHeight(MediaQueryData media) {
    final compact = media.size.width < 430 || media.size.height < 700;
    final ultraCompact = media.size.width < 360 || media.size.height < 640;
    return ultraCompact ? 64.0 : (compact ? 74.0 : 86.0);
  }

  static double preferredAppBarHeight(MediaQueryData media) {
    return media.padding.top + preferredContentHeight(media);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 430;
        final isShort = screenHeight < 700;
        final isUltraCompact = constraints.maxWidth < 360 || screenHeight < 640;
        final iconSize = isUltraCompact
            ? 34.0
            : (isNarrow ? (isShort ? 40.0 : 44.0) : 52.0);
        final actionSize = isUltraCompact ? 30.0 : (isNarrow ? 34.0 : 40.0);
        final horizontalPadding = isUltraCompact
            ? 8.0
            : (isNarrow ? 10.0 : 12.0);
        final verticalPadding = isUltraCompact ? 5.0 : (isNarrow ? 8.0 : 10.0);
        final actionGap = isUltraCompact ? 4.0 : 6.0;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(color: AppColors.surfaceFor(context)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface2For(context),
                  borderRadius: BorderRadius.circular(iconSize * 0.28),
                  border: Border.all(color: AppColors.borderFor(context)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(iconSize * 0.23),
                  child: Image.asset(
                    'assets/img/icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ڕووناکی',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (houseName.isNotEmpty)
                      Text(
                        houseName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (onOutageTap != null)
                _HeaderActionButton(
                  size: actionSize,
                  icon: isOutageTrackingActive
                      ? Icons.power_settings_new_outlined
                      : Icons.power_off_outlined,
                  tooltip: _outageTooltip,
                  onTap: onOutageTap!,
                ),
              if (onOutageTap != null && onProfileTap != null)
                SizedBox(width: actionGap),
              if (onProfileTap != null)
                _HeaderActionButton(
                  size: actionSize,
                  icon: Icons.home_work_outlined,
                  tooltip: _profileTooltip,
                  onTap: onProfileTap!,
                ),
              if (onProfileTap != null && onMenuTap != null)
                SizedBox(width: actionGap),
              if (onMenuTap != null)
                _HeaderActionButton(
                  size: actionSize,
                  icon: Icons.settings_outlined,
                  tooltip: _settingsTooltip,
                  onTap: onMenuTap!,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.size,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final double size;
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.surface2For(context),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderFor(context)),
            ),
            child: Center(
              child: Icon(
                icon,
                size: size * 0.52,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
