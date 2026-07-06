import '../data/word.dart';

String normalizeRu(String value) {
  return value
      .replaceAll('́', '')
      .toLowerCase()
      .replaceAll('ё', 'е')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
}

String normalizePl(String value) {
  return value.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}

bool checkRuAnswer(Word word, String answer) {
  return normalizeRu(answer) == normalizeRu(word.ru);
}

bool checkPlAnswer(Word word, String answer) {
  final normalized = normalizePl(answer);
  return word.pl.any((variant) => normalizePl(variant) == normalized);
}
