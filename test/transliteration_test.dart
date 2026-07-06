import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verba/core/transliteration.dart';

TextEditingValue typeText(String input) {
  var value = TextEditingValue.empty;
  for (final ch in input.split('')) {
    final proposed = TextEditingValue(
      text: value.text + ch,
      selection: TextSelection.collapsed(offset: value.text.length + 1),
    );
    value = Transliteration.processEdit(value, proposed);
  }
  return value;
}

void main() {
  group('convert', () {
    test('maps simple words', () {
      expect(Transliteration.convert('privet'), 'привет');
      expect(Transliteration.convert('spasibo'), 'спасибо');
      expect(Transliteration.convert('zdravstvujte'), 'здравствуйте');
    });

    test('maps digraphs', () {
      expect(Transliteration.convert('zhena'), 'жена');
      expect(Transliteration.convert('chas'), 'час');
      expect(Transliteration.convert('shkola'), 'школа');
      expect(Transliteration.convert('borw'), 'борщ');
    });

    test('keeps x as plain h without digraph absorption', () {
      expect(Transliteration.convert('sxema'), 'схема');
      expect(Transliteration.convert('sh'), 'ш');
    });

    test('maps soft and hard signs', () {
      expect(Transliteration.convert("den'"), 'день');
      expect(Transliteration.convert("ob''ekt"), 'объект');
    });

    test('maps e modifiers', () {
      expect(Transliteration.convert('vse='), 'всё');
      expect(Transliteration.convert('e==to'), 'это');
    });

    test('maps iotated vowels through j', () {
      expect(Transliteration.convert('ja'), 'я');
      expect(Transliteration.convert('julija'), 'юлия');
      expect(Transliteration.convert('jolka'), 'йолка');
    });

    test('adds stress mark after vowel and ignores q elsewhere', () {
      expect(Transliteration.convert('priveqt'), 'приве́т');
      expect(Transliteration.convert('tq'), 'т');
      expect(Transliteration.convert('q'), '');
    });

    test('keeps case', () {
      expect(Transliteration.convert('Privet'), 'Привет');
      expect(Transliteration.convert('Zhena'), 'Жена');
      expect(Transliteration.convert('MOSKVA'), 'МОСКВА');
    });

    test('passes through unmapped characters', () {
      expect(Transliteration.convert('privet!'), 'привет!');
      expect(Transliteration.convert('da, net'), 'да, нет');
      expect(Transliteration.convert('123'), '123');
    });
  });

  group('processEdit', () {
    test('transliterates typed characters sequentially', () {
      final value = typeText('spasibo');
      expect(value.text, 'спасибо');
      expect(value.selection.baseOffset, 7);
    });

    test('applies combos while typing', () {
      expect(typeText("ob''ekt").text, 'объект');
      expect(typeText('horosho').text, 'хорошо');
    });

    test('handles insertion in the middle of text', () {
      const old = TextEditingValue(text: 'ск', selection: TextSelection.collapsed(offset: 1));
      const proposed = TextEditingValue(text: 'сhк', selection: TextSelection.collapsed(offset: 2));
      final result = Transliteration.processEdit(old, proposed);
      expect(result.text, 'шк');
      expect(result.selection.baseOffset, 1);
    });

    test('leaves deletions untouched', () {
      const old = TextEditingValue(text: 'привет', selection: TextSelection.collapsed(offset: 6));
      const proposed = TextEditingValue(text: 'приве', selection: TextSelection.collapsed(offset: 5));
      final result = Transliteration.processEdit(old, proposed);
      expect(result.text, 'приве');
    });

    test('converts pasted chunks', () {
      const old = TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
      const proposed = TextEditingValue(text: 'privet', selection: TextSelection.collapsed(offset: 6));
      final result = Transliteration.processEdit(old, proposed);
      expect(result.text, 'привет');
    });
  });
}
