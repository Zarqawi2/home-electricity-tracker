import 'package:intl/intl.dart';

final NumberFormat _iqdNumberFormat = NumberFormat.decimalPattern('en_US')
  ..minimumFractionDigits = 2
  ..maximumFractionDigits = 2;

final NumberFormat _wattsNumberFormat = NumberFormat.decimalPattern('en_US');

String formatIqd(num value) {
  return '${_iqdNumberFormat.format(value)} \u062f\u06cc\u0646\u0627\u0631';
}

String formatWatts(num value) {
  return '${_wattsNumberFormat.format(value.round())} \u0648\u0627\u062a';
}
