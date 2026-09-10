import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/settings/house_profile_controller.dart';
import '../../../../../core/theme/app_responsive.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_dialog_shell.dart';
import '../../../domain/entities/appliance.dart';
import '../../viewmodels/appliance_view_model.dart';
import '../widgets/snackbar.dart';

class ApplianceDialog extends StatefulWidget {
  const ApplianceDialog({super.key, required this.ref, this.appliance});

  final WidgetRef ref;
  final Appliance? appliance;

  static Future<bool?> show(
    BuildContext context,
    WidgetRef ref, {
    Appliance? appliance,
  }) => showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ApplianceDialog(ref: ref, appliance: appliance),
  );

  @override
  State<ApplianceDialog> createState() => _ApplianceDialogState();
}

class _ApplianceDialogState extends State<ApplianceDialog> {
  static const _applianceNames = [
    'گڵۆپی لێد',
    'تەلفزیۆن',
    'سەلاجە',
    'پەنکە',
    'فڕۆشککەرەوە',
    'ئۆتۆ',
    'بۆیلەر (گێزەر)',
    'جلشۆر',
    'سپلیت',
    'گسکی کاربایی',
    'قاپشۆر',
    'موبایدە',
    'مزەخە',
    'گەرمکەرەوە (هیتر)',
    'شەحن',
    'ساحیبە',
    'مەکینەی قیمە',
    'مچەمیدە',
  ];
  static const _categories = {
    'Kitchen': 'چێشتخانە',
    'Climate Control': 'کۆنترۆڵی هەوا',
    'Entertainment': 'سەرگرمی',
    'Laundry': 'جلشۆر',
    'Water Heating': 'گەرمکردنی ئاو',
    'Other': 'هی تر',
  };

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _powerController;
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;
  String? _name;
  late String _category;
  late bool _isOn;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final appliance = widget.appliance;
    _name = appliance?.name;
    _category = appliance?.category ?? 'Kitchen';
    _isOn = appliance?.isOn ?? true;
    _powerController = TextEditingController(
      text: appliance == null ? '' : _formatNumber(appliance.powerW),
    );
    final minutes = ((appliance?.dailyUseHours ?? 2 / 60) * 60).round();
    _hoursController = TextEditingController(text: '${minutes ~/ 60}');
    _minutesController = TextEditingController(text: '${minutes % 60}');
  }

  @override
  void dispose() {
    _powerController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedHouse = widget.ref
        .watch(houseProfileProvider)
        .selectedProfile;
    final names = <String>{..._applianceNames, if (_name != null) _name!};
    final categories = <String, String>{
      ..._categories,
      if (!_categories.containsKey(_category)) _category: _category,
    };
    final availableHeight = AppResponsive.maxDialogHeight(
      context,
      ratio: 0.92,
      min: 280,
      max: 760,
    );

    return AppDialogShell(
      title: widget.appliance == null ? 'زیادکردنی ئامێر' : 'چاککردنی ئامێر',
      subtitle: selectedHouse.name,
      icon: Icons.electrical_services_outlined,
      onClose: () {
        if (!_isSaving) Navigator.of(context).pop(false);
      },
      maxWidth: 480,
      insetPadding: AppResponsive.dialogInsets(
        context,
        horizontal: 16,
        vertical: 16,
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: (availableHeight - 200).clamp(100, 560),
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _name,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  decoration: const InputDecoration(labelText: 'ناوی ئامێر'),
                  hint: const Text('ئامێرێک هەڵبژێرە'),
                  items: names
                      .map(
                        (name) =>
                            DropdownMenuItem(value: name, child: Text(name)),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _name = value),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'ئامێرێک هەڵبژێرە'
                      : null,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _powerController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'توانا',
                    suffixText: 'W',
                    hintText: '1000',
                  ),
                  textDirection: TextDirection.ltr,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    final power = double.tryParse(
                      _normalizeNumber(value ?? ''),
                    );
                    if (power == null || !power.isFinite || power <= 0) {
                      return 'توانایەکی دروست بنووسە';
                    }
                    if (power > 100000) {
                      return 'توانا نابێت لە 100,000 وات زیاتر بێت';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'ماوەی بەکارهێنانی ڕۆژانە',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _hoursController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(labelText: 'کاتژمێر'),
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final hours = int.tryParse(
                            _normalizeNumber(value ?? ''),
                          );
                          if (hours == null || hours < 0 || hours > 24) {
                            return 'لە 0 تا 24';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _minutesController,
                        enabled: !_isSaving,
                        decoration: const InputDecoration(
                          labelText: 'خولەک',
                          errorMaxLines: 2,
                        ),
                        textDirection: TextDirection.ltr,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          final minutes = int.tryParse(
                            _normalizeNumber(value ?? ''),
                          );
                          if (minutes == null || minutes < 0 || minutes > 59) {
                            return 'لە 0 تا 59';
                          }
                          final hours = int.tryParse(
                            _normalizeNumber(_hoursController.text),
                          );
                          if (hours != null &&
                              (hours * 60 + minutes < 2 ||
                                  hours * 60 + minutes > 1440)) {
                            return 'کۆی ماوە: 2 خولەک تا 24 کاتژمێر';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    maintainState: true,
                    iconColor: const Color(0xFF0F172A),
                    collapsedIconColor: const Color(0xFF0F172A),
                    title: Text(
                      'وردەکاری زیاتر',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    children: [
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'بەشی ئامێر',
                        ),
                        items: categories.entries
                            .map(
                              (entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (value) => setState(
                                () => _category = value ?? _category,
                              ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('چالاکە'),
                        subtitle: const Text(
                          'لە خەمڵاندنی بەکارهێناندا حیساب دەکرێت',
                        ),
                        value: _isOn,
                        onChanged: _isSaving
                            ? null
                            : (value) => setState(() => _isOn = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        AppButton(
          label: 'پاشەکەوتکردن',
          icon: Icons.check_circle_outline,
          variant: AppButtonVariant.primary,
          isLoading: _isSaving,
          onPressed: _isSaving ? null : _onSave,
        ),
      ],
    );
  }

  String _formatNumber(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();

  String _normalizeNumber(String value) {
    var normalized = value.trim().replaceAll(',', '.').replaceAll('٫', '.');
    for (var digit = 0; digit < 10; digit++) {
      normalized = normalized
          .replaceAll('٠١٢٣٤٥٦٧٨٩'[digit], '$digit')
          .replaceAll('۰۱۲۳۴۵۶۷۸۹'[digit], '$digit');
    }
    return normalized;
  }

  Future<void> _onSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    final notifier = widget.ref.read(appliancesProvider.notifier);
    final appliance = widget.appliance;
    final power = double.parse(_normalizeNumber(_powerController.text));
    final hours =
        int.parse(_normalizeNumber(_hoursController.text)) +
        int.parse(_normalizeNumber(_minutesController.text)) / 60;
    final success = appliance == null
        ? await notifier.add(
            name: _name!,
            category: _category,
            powerW: power,
            dailyUseHours: hours,
            isOn: _isOn,
          )
        : await notifier.update(
            id: appliance.id,
            name: _name!,
            category: _category,
            powerW: power,
            dailyUseHours: hours,
            isOn: _isOn,
          );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
      showSnack(context, 'پاشەکەوتکردن شکستی هێنا؛ دووبارە هەوڵ بدەوە.');
    }
  }
}
