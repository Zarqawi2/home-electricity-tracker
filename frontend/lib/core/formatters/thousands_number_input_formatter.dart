import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsNumberInputFormatter extends TextInputFormatter {
  ThousandsNumberInputFormatter({String locale = 'en_US'})
    : _formatter = NumberFormat.decimalPattern(locale);

  final NumberFormat _formatter;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final grouped = _formatter.format(int.parse(digitsOnly));
    final rightOffset = newValue.text.length - newValue.selection.extentOffset;
    final nextOffset = (grouped.length - rightOffset).clamp(0, grouped.length);

    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
  }
}
