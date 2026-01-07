import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/appliance.dart';
import '../../viewmodels/appliance_view_model.dart';
import '../widgets/snackbar.dart';

class ApplianceDialog extends StatefulWidget {
  const ApplianceDialog({
    super.key,
    required this.ref,
    this.appliance,
  });

  final WidgetRef ref;
  final Appliance? appliance;

  static Future<bool?> show(
    BuildContext context,
    WidgetRef ref, {
    Appliance? appliance,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ApplianceDialog(ref: ref, appliance: appliance),
    );
  }

  @override
  State<ApplianceDialog> createState() => _ApplianceDialogState();
}

class _ApplianceDialogState extends State<ApplianceDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController powerController;
  late final TextEditingController hoursController;
  late String category;
  late bool isOn;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final appliance = widget.appliance;
    nameController = TextEditingController(text: appliance?.name ?? '');
    powerController = TextEditingController(
      text: appliance != null ? appliance.powerW.toStringAsFixed(0) : '',
    );
    hoursController = TextEditingController(
      text: appliance != null ? appliance.dailyUseHours.toString() : '',
    );
    category = appliance?.category ?? 'Kitchen';
    isOn = appliance?.isOn ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    powerController.dispose();
    hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.appliance == null ? 'زیادکردنی ئامێر' : 'چاککردنی ئامێر',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'ناو'),
                  validator: (value) =>
                      (value == null || value.isEmpty) ? 'داواکراوە' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'جۆر'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Kitchen',
                      child: Text('چێشتخانە'),
                    ),
                    DropdownMenuItem(
                      value: 'Climate Control',
                      child: Text('کۆنترۆڵی هەوا'),
                    ),
                    DropdownMenuItem(
                      value: 'Entertainment',
                      child: Text('موزیک'),
                    ),
                    DropdownMenuItem(
                      value: 'Laundry',
                      child: Text('جلشۆر'),
                    ),
                    DropdownMenuItem(
                      value: 'Water Heating',
                      child: Text('ئاو گەرمکەر'),
                    ),
                    DropdownMenuItem(
                      value: 'Other',
                      child: Text('هی تر'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    category = value ?? category;
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: powerController,
                  decoration: const InputDecoration(
                    labelText: 'وزە (وات)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'داواکراوە';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'ژمارەیەکی دروست بنووسە';
                    }
                    if (parsed > 100000) {
                      return 'ئەوە زۆر گەورەیە، تکایە ژمارەیەکی گونجاو بنووسە';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: hoursController,
                  decoration: const InputDecoration(
                    labelText: 'بەکارهێنانی ڕۆژانە (کاتژمێر)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'داواکراوە';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'ژمارەیەکی دروست بنووسە';
                    }
                    if (parsed > 24) {
                      return 'نابێت لە ٢٤ کاتژمێر زیاتر بێت';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Switch(
                      value: isOn,
                      onChanged: isSaving
                          ? null
                          : (value) => setState(() => isOn = value),
                    ),
                    const SizedBox(width: 8),
                    const Text('کارا'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'پەڕاندن',
          variant: AppButtonVariant.ghost,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          borderRadius: 9,
          onPressed:
              isSaving ? null : () => Navigator.of(context).pop(null),
        ),
        const SizedBox(width: 8),
        AppButton(
          label: 'پاشەکەوتکردن',
          variant: AppButtonVariant.successOutline,
          isLoading: isSaving,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          borderRadius: 9,
          onPressed: isSaving ? null : _onSave,
        ),
      ],
    );
  }

  Future<void> _onSave() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    setState(() => isSaving = true);
    final notifier = widget.ref.read(appliancesProvider.notifier);
    final appliance = widget.appliance;
    final success = appliance == null
        ? await notifier.add(
            name: nameController.text,
            category: category,
            powerW: double.parse(powerController.text),
            dailyUseHours: double.parse(hoursController.text),
            isOn: isOn,
          )
        : await notifier.update(
            id: appliance.id,
            name: nameController.text,
            category: category,
            powerW: double.parse(powerController.text),
            dailyUseHours: double.parse(hoursController.text),
            isOn: isOn,
          );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pop(false);
      showSnack(context, 'پاشەکەوتکردن شکستی هێنا');
    }
  }
}
