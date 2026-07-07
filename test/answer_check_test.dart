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

  test('levenshtein distance', () {
    expect(levenshtein('kot', 'kot'), 0);
    expect(levenshtein('kot', 'kos'), 1);
    expect(levenshtein('kot', 'sok'), 2);
    expect(levenshtein('', 'abc'), 3);
    expect(levenshtein('хорошо', 'харашо'), 2);
  });

  const good = Word(
    id: 'good',
    ru: 'хорошо',
    ruAccented: 'хорошо́',
    pl: ['dobrze'],
    category: 'zwroty',
  );

  const thanks = Word(
    id: 'thanks',
    ru: 'спасибо',
    ruAccented: 'спаси́бо',
    pl: ['dziękuję'],
    category: 'zwroty',
  );

  const yes = Word(id: 'yes', ru: 'да', ruAccented: 'да', pl: ['tak'], category: 'zwroty');

  test('grades russian answers with typo tolerance', () {
    expect(gradeRuAnswer(good, 'хорошо'), AnswerGrade.correct);
    expect(gradeRuAnswer(good, 'хорошо́'), AnswerGrade.correct);
    expect(gradeRuAnswer(good, 'харашо'), AnswerGrade.almost);
    expect(gradeRuAnswer(good, 'хорша'), AnswerGrade.almost);
    expect(gradeRuAnswer(good, 'плохо'), AnswerGrade.wrong);
    expect(gradeRuAnswer(thanks, 'спасибa'), AnswerGrade.almost);
  });

  test('short words have no typo tolerance', () {
    expect(gradeRuAnswer(yes, 'да'), AnswerGrade.correct);
    expect(gradeRuAnswer(yes, 'до'), AnswerGrade.wrong);
  });

  test('grades polish answers including diacritic slips', () {
    expect(gradePlAnswer(thanks, 'dziękuję'), AnswerGrade.correct);
    expect(gradePlAnswer(thanks, 'dziekuje'), AnswerGrade.almost);
    expect(gradePlAnswer(thanks, 'prosze'), AnswerGrade.wrong);
    expect(gradePlAnswer(word, 'znac'), AnswerGrade.almost);
  });
}
