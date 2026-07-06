import 'package:flutter/services.dart';

class Transliteration {
  static const String stressMark = '́';

  static const Map<String, String> _singles = {
    'a': 'а',
    'b': 'б',
    'c': 'ц',
    'd': 'д',
    'e': 'е',
    'f': 'ф',
    'g': 'г',
    'h': 'х',
    'i': 'и',
    'j': 'й',
    'k': 'к',
    'l': 'л',
    'm': 'м',
    'n': 'н',
    'o': 'о',
    'p': 'п',
    'r': 'р',
    's': 'с',
    't': 'т',
    'u': 'у',
    'v': 'в',
    'w': 'щ',
    'x': 'х',
    'y': 'ы',
    'z': 'з',
    "'": 'ь',
  };

  static const Map<String, String> _combos = {
    'зh': 'ж',
    'цh': 'ч',
    'сh': 'ш',
    "ь'": 'ъ',
    'е=': 'ё',
    'ё=': 'э',
    'йu': 'ю',
    'йa': 'я',
  };

  static const String _vowels = 'аеёиоуыэюя';

  static String applyChar(String text, String ch) {
    final lower = ch.toLowerCase();
    if (text.isNotEmpty) {
      final last = text.substring(text.length - 1);
      final combo = _combos[last.toLowerCase() + lower];
      if (combo != null) {
        final replacement = last == last.toLowerCase() ? combo : combo.toUpperCase();
        return text.substring(0, text.length - 1) + replacement;
      }
      if (lower == 'q') {
        if (_vowels.contains(last.toLowerCase())) return text + stressMark;
        return text;
      }
    } else if (lower == 'q') {
      return text;
    }
    final single = _singles[lower];
    if (single == null) return text + ch;
    return text + (ch == lower ? single : single.toUpperCase());
  }

  static String convert(String latin) {
    var result = '';
    for (final ch in latin.split('')) {
      result = applyChar(result, ch);
    }
    return result;
  }

  static TextEditingValue processEdit(TextEditingValue oldValue, TextEditingValue newValue) {
    final oldText = oldValue.text;
    final newText = newValue.text;
    if (newText.length <= oldText.length) return newValue;
    final caret = newValue.selection.baseOffset;
    final insertedCount = newText.length - oldText.length;
    final insertStart = caret - insertedCount;
    if (insertStart < 0 || caret > newText.length) return newValue;
    final prefixMatches = newText.substring(0, insertStart) == oldText.substring(0, insertStart);
    final suffixMatches = newText.substring(caret) == oldText.substring(insertStart);
    if (!prefixMatches || !suffixMatches) return newValue;
    var head = oldText.substring(0, insertStart);
    final inserted = newText.substring(insertStart, caret);
    for (final ch in inserted.split('')) {
      head = applyChar(head, ch);
    }
    return TextEditingValue(
      text: head + oldText.substring(insertStart),
      selection: TextSelection.collapsed(offset: head.length),
    );
  }
}

class TransliterationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return Transliteration.processEdit(oldValue, newValue);
  }
}
