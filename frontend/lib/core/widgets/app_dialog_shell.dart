import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const _defaultCloseLabel = 'داخستن';

/// A compact, accessible close control shared by dialogs and bottom sheets.
class AppModalCloseButton extends StatelessWidget {
  const AppModalCloseButton({
    super.key,
    required this.onPressed,
    this.tooltip = _defaultCloseLabel,
  });

  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    const border = AppColors.lightBorder;

    return Material(
      color: AppColors.lightSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: border),
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded),
        iconSize: 20,
        color: AppColors.lightTextPrimary,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      ),
    );
  }
}

class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    super.key,
    required this.content,
    this.title,
    this.subtitle,
    this.icon,
    this.onClose,
    this.closeTooltip = _defaultCloseLabel,
    this.actions = const [],
    this.maxWidth = 520,
    this.insetPadding = const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 24,
    ),
    this.contentPadding = const EdgeInsets.fromLTRB(20, 16, 20, 18),
    this.actionPadding = const EdgeInsets.fromLTRB(20, 14, 20, 18),
    this.accentColor,
  });

  final Widget content;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;
  final String closeTooltip;
  final List<Widget> actions;
  final double maxWidth;
  final EdgeInsets insetPadding;
  final EdgeInsets contentPadding;
  final EdgeInsets actionPadding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    const border = AppColors.lightBorder;
    final hasHeader =
        title != null || subtitle != null || icon != null || onClose != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: insetPadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasHeader)
                _ModalHeader(
                  title: title,
                  subtitle: subtitle,
                  icon: icon,
                  onClose: onClose,
                  closeTooltip: closeTooltip,
                ),
              if (hasHeader) Divider(height: 1, color: border),
              Padding(padding: contentPadding, child: content),
              if (actions.isNotEmpty) ...[
                Divider(height: 1, color: border),
                Padding(
                  padding: actionPadding,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppSheetShell extends StatelessWidget {
  const AppSheetShell({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.onClose,
    this.closeTooltip = _defaultCloseLabel,
    this.actions = const [],
    this.showHandle = true,
    this.expandChild = false,
    this.maxWidth = 720,
    this.padding = const EdgeInsets.fromLTRB(20, 16, 20, 18),
    this.actionPadding = const EdgeInsets.fromLTRB(20, 14, 20, 18),
    this.accentColor,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;
  final String closeTooltip;
  final List<Widget> actions;
  final bool showHandle;
  final bool expandChild;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry actionPadding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isDesktop = media.size.width >= 700;
    const border = AppColors.lightBorder;
    final hasHeader =
        title != null || subtitle != null || icon != null || onClose != null;

    return Align(
      alignment: isDesktop ? Alignment.center : Alignment.bottomCenter,
      widthFactor: 1,
      heightFactor: 1,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 8,
          isDesktop ? 18 : 8,
          isDesktop ? 24 : 8,
          isDesktop ? 18 : 8,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: Column(
              mainAxisSize: expandChild ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHandle && !isDesktop)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 42,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: AppColors.lightTextSecondary.withValues(
                          alpha: 0.28,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                if (hasHeader)
                  _ModalHeader(
                    title: title,
                    subtitle: subtitle,
                    icon: icon,
                    onClose: onClose,
                    closeTooltip: closeTooltip,
                    topPadding: showHandle && !isDesktop ? 10 : 18,
                  ),
                if (hasHeader) Divider(height: 1, color: border),
                if (expandChild)
                  Expanded(
                    child: Padding(padding: padding, child: child),
                  )
                else
                  Flexible(
                    fit: FlexFit.loose,
                    child: Padding(padding: padding, child: child),
                  ),
                if (actions.isNotEmpty) ...[
                  Divider(height: 1, color: border),
                  Padding(
                    padding: actionPadding,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      children: actions,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModalHeader extends StatelessWidget {
  const _ModalHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onClose,
    required this.closeTooltip,
    this.topPadding = 18,
  });

  final String? title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;
  final String closeTooltip;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.lightSurface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: Icon(icon, size: 21, color: AppColors.lightTextPrimary),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onClose != null) ...[
            const SizedBox(width: 12),
            AppModalCloseButton(tooltip: closeTooltip, onPressed: onClose!),
          ],
        ],
      ),
    );
  }
}
