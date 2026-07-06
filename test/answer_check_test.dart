import 'package:flutter_test/flutter_test.dart';
import 'package:verba/core/answer_check.dart';
import 'package:verba/data/word.dart';

const word = Word(
  id: 'know',
  ru: 'знать',
  ruAccented: 'знать',
  pl: ['wiedzieć', 'znać'],
  category: 'czasowniki',
);

const accented = Word(
  id: 'time',
  ru: 'время',
  ruAccented: 'вре́мя',
  pl: ['czas'],
  category: 'rzeczowniki',
);

void main() {
  test('accepts exact russian answer', () {
    expect(checkRuAnswer(word, 'знать'), isTrue);
    expect(checkRuAnswer(word, ' ЗНАТЬ '), isTrue);
    expect(checkRuAnswer(word, 'знат'), isFalse);
  });

  test('ignores stress marks and yo in russian answers', () {
    expect(checkRuAnswer(accented, 'вре́мя'), isTrue);
    expect(checkRuAnswer(accented, 'время'), isTrue);
  });

  test('accepts any polish variant', () {
    expect(checkPlAnswer(word, 'wiedzieć'), isTrue);
    expect(checkPlAnswer(word, 'znać'), isTrue);
    expect(checkPlAnswer(word, 'Znać '), isTrue);
    expect(checkPlAnswer(word, 'umieć'), isFalse);
  });
}
