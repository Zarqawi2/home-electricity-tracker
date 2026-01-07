import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/appliance.dart';
import '../../viewmodels/appliance_view_model.dart';
import '../../viewmodels/dashboard_view_model.dart';
import '../dialogs/appliance_dialog.dart';
import '../widgets/snackbar.dart';

class ApplianceActions {
  ApplianceActions({
    required this.context,
    required this.ref,
  });

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
    final success =
        await ref.read(appliancesProvider.notifier).toggle(appliance.id);
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
    final success =
        await ref.read(appliancesProvider.notifier).delete(appliance.id);
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('سڕینەوەی ئامێر؟'),
          content: Text('ئایا دڵنیایت دەته‌وێت "${appliance.name}" بسڕیتەوە؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('پەڕاندن'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('سڕینەوە'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}
