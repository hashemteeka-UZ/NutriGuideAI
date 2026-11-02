/// The meal's emoji from what the dish is, never from the time of day (P2g).
///
/// The phone keeps the catalog of one language at a time, so the rules read
/// the meal name in Arabic or English and give the same icon in both:
/// 1. the head noun (Arabic: the first word; English: the last word before
///    «with», «(» or «,», or before «and» when that word is known);
/// 2. otherwise any known word, in [_rules] order;
/// 3. otherwise the heaviest ingredient that is not water;
/// 4. otherwise a plate.
library;

const fallbackDishIcon = 'fork-and-knife-with-plate';

/// Time-of-day emoji that a meal must never get.
const timeOfDayIcons = <String>{'sunrise', 'sun', 'crescent-moon'};

class _Rule {
  const _Rule(this.icon, this.ar, this.en);

  final String icon;
  final Set<String> ar;
  final Set<String> en;
}

/// Priority order for step 2; step 1 uses the same table.
const _rules = <_Rule>[
  _Rule('teacup-without-handle', {'قهوة', 'شاي'}, {'coffee', 'tea'}),
  _Rule('tumbler-glass', {'عصير', 'سموذي'}, {'juice', 'smoothie', 'lemonade'}),
  _Rule('glass-of-milk', {'حليب_مشروب', 'لبن_مشروب'}, {'milk', 'buttermilk'}),
  _Rule('pot-of-food', {'شوربة', 'شربة'}, {'soup', 'sharba'}),
  _Rule(
    'green-salad',
    {'سلطة', 'تبولة', 'فتوش'},
    {'salad', 'tabbouleh', 'fattoush'},
  ),
  _Rule('sandwich', {'سندويتش', 'ساندويتش'}, {'sandwich'}),
  _Rule(
    'spaghetti',
    {'معكرونة', 'مبكبكة', 'رشتة', 'كشري'},
    {'pasta', 'mbakbaka', 'macaroni', 'noodles', 'rishta', 'koshari'},
  ),
  _Rule('falafel', {'فلافل', 'طعمية'}, {'falafel', "ta'meya"}),
  _Rule('pancakes', {'بان'}, {'pancakes'}),
  _Rule(
    'fish',
    {'سمك', 'حوت', 'سلمون', 'تن', 'تونة', 'سردين', 'بلطي', 'قاروص', 'صيادية'},
    {'fish', 'salmon', 'tuna', 'sardines', 'tilapia', 'bass', 'sayadieh'},
  ),
  _Rule(
    'poultry-leg',
    {'دجاج', 'طاووق', 'مسخن'},
    {'chicken', 'tawook', 'musakhan'},
  ),
  _Rule(
    'cut-of-meat',
    {'لحم', 'كفتة', 'كبدة', 'كبة', 'شاكرية', 'ضأن'},
    {
      'lamb',
      'beef',
      'meat',
      'meatballs',
      'kofta',
      'liver',
      'kibbeh',
      'shakriyeh',
    },
  ),
  _Rule(
    'cooking',
    {'بيض', 'عجة', 'شكشوكة', 'أومليت', 'بيضتان', 'بيضتين'},
    {'egg', 'eggs', 'omelette', 'shakshuka'},
  ),
  _Rule('stuffed-flatbread', {'بريك', 'بوريك'}, {'brik', 'bourek'}),
  _Rule(
    'peanuts',
    {'لوز', 'جوز', 'بذور', 'مكسرات', 'فشار', 'فول_سوداني'},
    {'almonds', 'walnuts', 'seeds', 'nuts', 'popcorn', 'peanut'},
  ),
  _Rule(
    'beans',
    {
      'فول',
      'عدس',
      'حمص',
      'فاصوليا',
      'لوبيا',
      'مجدرة',
      'مسبحة',
      'فتة',
      'بازلاء',
    },
    {
      'beans',
      'bean',
      'lentils',
      'lentil',
      'chickpeas',
      'chickpea',
      'hummus',
      'peas',
      'mujaddara',
      'msabbaha',
      'fava',
    },
  ),
  _Rule('cooked-rice', {'رز', 'أرز', 'برغل'}, {'rice', 'pilaf', 'bulgur'}),
  _Rule(
    'steaming-bowl',
    {'كسكسي', 'بازين', 'عصيدة', 'بسيسة', 'زميطة'},
    {'couscous', 'bazeen', 'asida', 'bsisa', 'zummita'},
  ),
  _Rule(
    'bowl-with-spoon',
    {'زبادي', 'لبنة', 'لبن', 'جبن', 'جبنة', 'قريش', 'شوفان', 'موزاريلا'},
    {
      'yogurt',
      'labneh',
      'cheese',
      'feta',
      'mozzarella',
      'oats',
      'oatmeal',
      'laban',
    },
  ),
  _Rule(
    'red-apple',
    {
      'تفاح',
      'تفاحة',
      'موز',
      'موزة',
      'عنب',
      'بطيخ',
      'رمان',
      'كمثرى',
      'تين',
      'مشمش',
      'تمر',
      'فواكه',
      'برتقال',
      'فراولة',
    },
    {
      'apple',
      'apples',
      'banana',
      'grapes',
      'watermelon',
      'pomegranate',
      'pear',
      'figs',
      'apricots',
      'dates',
      'fruit',
      'orange',
      'strawberries',
    },
  ),
  _Rule('croissant', {'غريبة', 'كعك'}, {'ghraiba', 'kaak'}),
  _Rule(
    'flatbread',
    {'خبز', 'توست', 'عيش', 'مناقيش', 'منقوشة', 'فطاير', 'فطيرة', 'سفنز'},
    {'bread', 'toast', 'pita', 'manakish', 'fatayer', 'fteera', 'sfinz'},
  ),
  _Rule(
    'shallow-pan-of-food',
    {
      'طبيخة',
      'يخنة',
      'محشي',
      'مسقعة',
      'متبل',
      'ملوخية',
      'مقلوبة',
      'ورق',
      'مبطن',
      'بطاطا',
    },
    {
      'stew',
      'stuffed',
      'moussaka',
      'mutabbal',
      'molokhia',
      'maqluba',
      'mbatan',
      'potato',
      'potatoes',
    },
  ),
  _Rule('olive', {'زيتون'}, {'olives', 'olive'}),
];

/// Icons that name the kind of dish rather than one of its ingredients.
const _dishForms = <String>{
  'teacup-without-handle',
  'tumbler-glass',
  'glass-of-milk',
  'pot-of-food',
  'green-salad',
  'sandwich',
  'spaghetti',
  'falafel',
  'pancakes',
  'stuffed-flatbread',
  'croissant',
  'shallow-pan-of-food',
};

final _arabic = RegExp(r'[؀-ۿ]');

bool _isArabic(String text) => _arabic.hasMatch(text);

/// Word forms of an Arabic token without the joined و / ب / ال / لل.
Set<String> _arForms(String token) {
  final forms = <String>{token};
  final queue = <String>[token];
  while (queue.isNotEmpty) {
    final word = queue.removeLast();
    for (final prefix in const <String>['و', 'بال', 'لل', 'ال', 'ب']) {
      if (word.length > prefix.length + 1 && word.startsWith(prefix)) {
        final rest = word.substring(prefix.length);
        if (forms.add(rest)) {
          queue.add(rest);
        }
      }
    }
  }
  return forms;
}

List<String> _arTokens(String name) {
  var text = name.replaceAll(RegExp(r'[()،,.]'), ' ');
  // Peanut butter is a nut, not a fava bean.
  text = text.replaceAll(RegExp(r'ال?فول ال?سوداني'), 'فول_سوداني');
  text = text.replaceAll('ورق عنب', 'ورق');
  final tokens = text.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  return tokens.toList();
}

String? _arIcon(String token, {required bool head}) {
  var forms = _arForms(token);
  if (head && (forms.contains('حليب') || forms.contains('لبن'))) {
    // A name that starts with milk or laban is the drink itself.
    forms = <String>{...forms, 'حليب_مشروب', 'لبن_مشروب'};
  }
  for (final rule in _rules) {
    if (forms.any(rule.ar.contains)) {
      return rule.icon;
    }
  }
  return null;
}

String? _iconForArabic(String name) {
  final tokens = _arTokens(name);
  if (tokens.isEmpty) {
    return null;
  }
  final head = _arIcon(tokens.first, head: true);
  if (head != null) {
    return head;
  }
  for (final rule in _rules) {
    for (final token in tokens.skip(1)) {
      if (_arForms(token).any(rule.ar.contains)) {
        return rule.icon;
      }
    }
  }
  return null;
}

List<String> _enWords(String text) {
  return text
      .toLowerCase()
      .split(RegExp(r'[\s,]+'))
      .map((w) => w.replaceAll(RegExp(r"[^a-z'\-]"), ''))
      .where((w) => w.isNotEmpty)
      .toList();
}

String? _enIcon(String word) {
  for (final rule in _rules) {
    if (rule.en.contains(word)) {
      return rule.icon;
    }
  }
  return null;
}

String? _iconForEnglish(String name) {
  final lower = name.toLowerCase().replaceAll('peanut butter', 'peanut');
  final cut = RegExp(r'\s+(with|in)\s+|\(|,').firstMatch(lower);
  final phrase = cut == null ? lower : lower.substring(0, cut.start);
  final parts = phrase.split(RegExp(r'\s+and\s+'));
  // «Feta and vegetable sandwich» is a sandwich; «Chicken and rice» is
  // chicken: a dish word at the end wins, otherwise the first noun does.
  final last = _lastWord(phrase).map(_enIcon).firstOrNull;
  if (last != null && _dishForms.contains(last)) {
    return last;
  }
  final heads = <String>[
    if (parts.length > 1) ..._lastWord(parts.first),
    ..._lastWord(phrase),
  ];
  for (final word in heads) {
    final icon = _enIcon(word);
    if (icon != null) {
      return icon;
    }
  }
  final words = _enWords(lower);
  for (final rule in _rules) {
    if (words.any(rule.en.contains)) {
      return rule.icon;
    }
  }
  return null;
}

List<String> _lastWord(String phrase) {
  final words = _enWords(phrase);
  return words.isEmpty ? const <String>[] : <String>[words.last];
}

String? _iconForText(String text) {
  return _isArabic(text) ? _iconForArabic(text) : _iconForEnglish(text);
}

bool _isWater(String name) {
  final trimmed = name.trim().toLowerCase();
  return trimmed == 'ماء' || trimmed == 'water';
}

/// The emoji of a meal from its [name], else from its [ingredients]
/// (heaviest first), else a plate. Never a time-of-day emoji.
String dishIcon(String name, {List<String> ingredients = const <String>[]}) {
  final byName = _iconForText(name);
  if (byName != null) {
    return byName;
  }
  for (final ingredient in ingredients) {
    if (_isWater(ingredient)) {
      continue;
    }
    return _iconForText(ingredient) ?? fallbackDishIcon;
  }
  return fallbackDishIcon;
}
