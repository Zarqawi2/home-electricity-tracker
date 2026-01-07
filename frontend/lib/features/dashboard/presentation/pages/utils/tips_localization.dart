List<String> localizedTips(List<String> tips) {
  if (tips.isEmpty) {
    return const [
      'کاتێک بەکارنایە ئامێرەکان بکوژێنەوە بۆ کەمکردنەوەی خەرجی ستاندبای.',
      'لامپە LED بەکاربهێنە چونکە تا %75 کارەبا کەمتر دەخۆن لە لامپە کۆنڤەکسیۆنەکان.',
      'تێرمۆستات لە زستان 2-3 پلە کەم و لە هاوین 2-3 پلە بەرز بکە بۆ خەرجی کەمتر.',
      'ئامێری کارامە بە هەڵسەنگاندنی بەرزی Energy Star بەکاربهێنە.',
      'چاککردنی بەردەوامی یەکەکانی AC دەتوانێت کاراییان تا %15 بەرز بکات.',
    ];
  }

  final map = <String, String>{
    'Turn off appliances when not in use to reduce standby power consumption':
        'کاتێک بەکارنایە ئامێرەکان بکوژێنەوە بۆ کەمکردنەوەی خەرجی ستاندبای.',
    'Use LED bulbs which consume 75% less energy than incandescent bulbs':
        'لامپە LED بەکاربهێنە چونکە تا %75 کارەبا کەمتر دەخۆن لە لامپە کۆنڤەکسیۆنەکان.',
    'Set your thermostat 2-3 degrees lower in winter and higher in summer':
        'تێرمۆستات لە زستان 2-3 پلە کەم و لە هاوین 2-3 پلە بەرز بکە بۆ خەرجی کەمتر.',
    'Use energy-efficient appliances with high Energy Star ratings':
        'ئامێری کارامە بە هەڵسەنگاندنی بەرزی Energy Star بەکاربهێنە.',
    'Regular maintenance of AC units can improve efficiency by up to 15%':
        'چاککردنی بەردەوامی یەکەکانی AC دەتوانێت کاراییان تا %15 بەرز بکات.',
  };

  return tips.map((tip) => map[tip] ?? tip).toList();
}
