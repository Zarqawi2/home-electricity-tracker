import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum AppButtonVariant {
  primary,
  neutral,
  outline,
  ghost,
  segment,
  destructive,
  success,
  successOutline,
}

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.selected = false,
    this.isLoading = false,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 12,
    this.fontSize = 14,
    this.iconSize = 18,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.splashColor,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool selected;
  final bool isLoading;
  final IconData? icon;
  final EdgeInsets padding;
  final double borderRadius;
  final double fontSize;
  final double iconSize;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final Color? splashColor;
  final bool fullWidth;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.variant, widget.selected);
    final disabled = widget.onPressed == null || widget.isLoading;
    final baseBg = widget.backgroundColor ?? palette.background;
    final baseText = widget.textColor ?? palette.text;
    final baseBorder = widget.borderColor ?? palette.border;
    final baseSplash = widget.splashColor ?? palette.splashColor;

    final bgColor = disabled ? baseBg.withOpacity(0.6) : baseBg;
    final fgColor = disabled ? baseText.withOpacity(0.6) : baseText;
    final effectiveBorderColor = disabled
        ? baseBorder.withOpacity(0.5)
        : baseBorder;

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(
          color: effectiveBorderColor,
          width: palette.borderWidth,
        ),
        boxShadow: widget.selected && palette.shadow != null
            ? [palette.shadow!]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: baseSplash,
          highlightColor: baseSplash?.withOpacity(0.08),
          onHighlightChanged: (value) => setState(() => _pressed = value),
          onTap: disabled ? null : widget.onPressed,
          child: Padding(
            padding: widget.padding,
            child: Row(
              mainAxisSize: widget.fullWidth
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                    ),
                  ),
                if (widget.isLoading) const SizedBox(width: 8),
                if (!widget.isLoading && widget.icon != null) ...[
                  Icon(widget.icon, size: widget.iconSize, color: fgColor),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: fgColor,
                      fontSize: widget.fontSize,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.98 : 1,
      child: widget.fullWidth
          ? SizedBox(width: double.infinity, child: content)
          : content,
    );
  }

  _ButtonPalette _paletteFor(AppButtonVariant variant, bool selected) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _ButtonPalette(
          background: AppColors.primary,
          text: Colors.white,
          border: AppColors.primary,
          splashColor: AppColors.primary.withOpacity(0.12),
          shadow: const BoxShadow(
            color: Color(0x332563EB),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        );
      case AppButtonVariant.neutral:
        return _ButtonPalette(
          background: selected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.white,
          text: selected ? AppColors.primary : AppColors.textPrimary,
          border: selected ? AppColors.primary : AppColors.cardBorder,
          splashColor: AppColors.primary.withOpacity(0.08),
        );
      case AppButtonVariant.outline:
        return _ButtonPalette(
          background: Colors.white,
          text: AppColors.primary,
          border: AppColors.primary,
          splashColor: AppColors.primary.withOpacity(0.08),
        );
      case AppButtonVariant.ghost:
        return _ButtonPalette(
          background: Colors.transparent,
          text: AppColors.textPrimary,
          border: Colors.transparent,
          splashColor: AppColors.primary.withOpacity(0.08),
          borderWidth: 0,
        );
      case AppButtonVariant.segment:
        return _ButtonPalette(
          background: selected ? AppColors.primary : Colors.white,
          text: selected ? Colors.white : AppColors.textPrimary,
          border: selected ? AppColors.primary : AppColors.cardBorder,
          splashColor: AppColors.primary.withOpacity(0.08),
          shadow: selected
              ? BoxShadow(
                  color: AppColors.primary.withOpacity(0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              : null,
        );
      case AppButtonVariant.destructive:
        return _ButtonPalette(
          background: AppColors.negative,
          text: Colors.white,
          border: AppColors.negative,
          splashColor: AppColors.negative.withOpacity(0.12),
          shadow: const BoxShadow(
            color: Color(0x33DC2626),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        );
      case AppButtonVariant.success:
        return _ButtonPalette(
          background: AppColors.positive,
          text: Colors.white,
          border: AppColors.positive,
          splashColor: AppColors.positive.withOpacity(0.12),
          shadow: const BoxShadow(
            color: Color(0x3316A34A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        );
      case AppButtonVariant.successOutline:
        return _ButtonPalette(
          background: Colors.white,
          text: AppColors.positive,
          border: AppColors.positive,
          splashColor: AppColors.positive.withOpacity(0.08),
        );
    }
  }
}

class _ButtonPalette {
  _ButtonPalette({
    required this.background,
    required this.text,
    required this.border,
    this.borderWidth = 1,
    this.shadow,
    this.splashColor,
  });

  final Color background;
  final Color text;
  final Color border;
  final double borderWidth;
  final BoxShadow? shadow;
  final Color? splashColor;
}
