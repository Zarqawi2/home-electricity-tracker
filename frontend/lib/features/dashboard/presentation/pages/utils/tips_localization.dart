List<String> localizedTips(List<String> tips) {
  const fallbackTips = [
    'ئەو ئامێرەی کارت پێی نییە، لە وایەرەکەیەوە بیکوژێنەوە؛ نەکەی بە داگیرساوی جێی بهێڵیت و بەخۆڕایی کارەبا بەکاربهێنێت.',
    'گلۆپی LED دابنێ؛ چونکە زۆر لە گلۆپە کۆنەکان چاکترە و کارەبای زۆر کەمتر بەکاردەهێنێت.',
    'بە پێی وەرزەکان و ئامێرەکان کارەبا بەکاربهێنە و بڕی بە کارهێنانیشیان با زۆر نەبێت.',
    'کاتێک سەلاجە یان سپلیت دەکڕیت، سەیری نیشانەی (Energy Star) بکە؛ ئەوانە بۆ دەستپێوەگرتن و کەم بەکارهێنانی کارەبا زۆر باشن.',
    'سپلیت و موبەریدەکان زوو زوو خاوێن بکەرەوە؛ چونکە ئەگەر پیس بن، زۆرتر ماندوو دەبن و کارەبای زۆرتر بەکاردەهێنن.',
  ];

  if (tips.isEmpty) {
    return fallbackTips;
  }

  const map = <String, String>{
    'Turn off appliances when not in use to reduce standby power consumption':
        'ئەو ئامێرەی کارت پێی نییە، لە وایەرەکەیەوە بیکوژێنەوە؛ نەکەی بە داگیرساوی جێی بهێڵیت و بەخۆڕایی کارەبا بەکاربهێنێت.',
    'Use LED bulbs which consume 75% less energy than incandescent bulbs':
        'گلۆپی LED دابنێ؛ چونکە زۆر لە گلۆپە کۆنەکان چاکترە و کارەبای زۆر کەمتر بەکاردەهێنێت.',
    'Set your thermostat 2-3 degrees lower in winter and higher in summer':
        'بە پێی وەرزەکان و ئامێرەکان کارەبا بەکاربهێنە و بڕی بە کارهێنانیشیان با زۆر نەبێت.',
    'Use energy-efficient appliances with high Energy Star ratings':
        'کاتێک سەلاجە یان سپلیت دەکڕیت، سەیری نیشانەی (Energy Star) بکە؛ ئەوانە بۆ دەستپێوەگرتن و کەم بەکارهێنانی کارەبا زۆر باشن.',
    'Regular maintenance of AC units can improve efficiency by up to 15%':
        'سپلیت و موبەریدەکان زوو زوو خاوێن بکەرەوە؛ چونکە ئەگەر پیس بن، زۆرتر ماندوو دەبن و کارەبای زۆرتر بەکاردەهێنن.',
  };

  return tips.map((tip) => map[tip] ?? tip).toList();
}
