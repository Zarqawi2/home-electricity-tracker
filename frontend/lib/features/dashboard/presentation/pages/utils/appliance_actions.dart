import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_dialog_shell.dart';
import '../../../domain/entities/appliance.dart';
import '../../viewmodels/appliance_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../dialogs/appliance_dialog.dart';
import '../widgets/snackbar.dart';

class ApplianceActions {
  ApplianceActions({required this.context, required this.ref});

  final BuildContext context;
  final WidgetRef ref;

  Future<void> refreshAll() async {
    await ref.read(appliancesProvider.notifier).refresh();
    await ref.read(dashboardProvider.notifier).refresh();
  }

  Future<void> add() async {
    final added = await ApplianceDialog.show(context, ref);
    if (!context.mounted) return;
    if (added == true) {
      await refreshAll();
    }
  }

  Future<void> edit(Appliance appliance) async {
    final updated = await ApplianceDialog.show(
      context,
      ref,
      appliance: appliance,
    );
    if (!context.mounted) return;
    if (updated == true) {
      await refreshAll();
    }
  }

  Future<void> toggle(Appliance appliance) async {
    final success = await ref
        .read(appliancesProvider.notifier)
        .toggle(appliance.id);
    if (!context.mounted) return;
    if (success) {
      await ref.read(dashboardProvider.notifier).refresh();
    } else {
      showSnack(context, 'نوژکردنەوەی دوخەکە شکستی هێنا');
    }
  }

  Future<void> delete(Appliance appliance) async {
    final confirm = await _confirmDelete(appliance);
    if (!confirm) return;
    final success = await ref
        .read(appliancesProvider.notifier)
        .delete(appliance.id);
    if (!context.mounted) return;
    if (success) {
      await ref.read(dashboardProvider.notifier).refresh();
    } else {
      showSnack(context, 'سڕینەوە شکستی هێنا');
    }
  }

  Future<bool> _confirmDelete(Appliance appliance) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final accent = AppColors.negativeFor(dialogContext);

        return AppDialogShell(
          title: 'سڕینەوەی ئامێر؟',
          subtitle: appliance.name,
          icon: Icons.delete_outline_rounded,
          accentColor: accent,
          onClose: () => Navigator.of(dialogContext).pop(false),
          maxWidth: 390,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 34,
            vertical: 18,
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          actionPadding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          content: Text(
            'ئایا دڵنیایت دەتەوێت "${appliance.name}" بسڕیتەوە؟',
            textDirection: TextDirection.rtl,
            style: Theme.of(dialogContext).textTheme.bodyMedium,
          ),
          actions: [
            AppButton(
              label: 'پەڕاندن',
              variant: AppButtonVariant.ghost,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            AppButton(
              label: 'سڕینەوە',
              variant: AppButtonVariant.destructive,
              icon: Icons.delete_forever_outlined,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
