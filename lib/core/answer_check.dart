import '../data/word.dart';

enum AnswerGrade { correct, almost, wrong }

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

const List<Set<String>> ruSynonymGroups = [
  {'так', 'да'},
  {'нет', 'не'},
];

List<String> acceptedRu(Word word) {
  final n = normalizeRu(word.ru);
  for (final group in ruSynonymGroups) {
    if (group.contains(n)) return group.toList();
  }
  return [n];
}

List<String> _answerTokens(String answer, String Function(String) normalize) {
  return answer.split(',').map(normalize).where((t) => t.isNotEmpty).toList();
}

bool _checkTokens(String answer, List<String> accepted, String Function(String) normalize) {
  final set = accepted.toSet();
  final tokens = _answerTokens(answer, normalize);
  return tokens.isNotEmpty && tokens.every(set.contains);
}

bool checkRuAnswer(Word word, String answer) => _checkTokens(answer, acceptedRu(word), normalizeRu);

bool checkPlAnswer(Word word, String answer) =>
    _checkTokens(answer, [for (final variant in word.pl) normalizePl(variant)], normalizePl);

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  var current = List<int>.filled(b.length + 1, 0);
  for (var i = 0; i < a.length; i++) {
    current[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final substitution = previous[j] + (a[i] == b[j] ? 0 : 1);
      final insertion = current[j] + 1;
      final deletion = previous[j + 1] + 1;
      current[j + 1] = [substitution, insertion, deletion].reduce((x, y) => x < y ? x : y);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}

AnswerGrade _grade(String given, List<String> accepted) {
  var bestDistance = 1 << 30;
  var bestLength = 0;
  for (final target in accepted) {
    if (given == target) return AnswerGrade.correct;
    final distance = levenshtein(given, target);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestLength = target.length;
    }
  }
  if (bestDistance == 1 && bestLength >= 3) return AnswerGrade.almost;
  if (bestDistance == 2 && bestLength >= 6) return AnswerGrade.almost;
  return AnswerGrade.wrong;
}

AnswerGrade _gradeTokens(String answer, List<String> accepted, String Function(String) normalize) {
  final tokens = _answerTokens(answer, normalize);
  if (tokens.isEmpty) return AnswerGrade.wrong;
  var worst = AnswerGrade.correct;
  for (final token in tokens) {
    final grade = _grade(token, accepted);
    if (grade.index > worst.index) worst = grade;
  }
  return worst;
}

AnswerGrade gradeRuAnswer(Word word, String answer) => _gradeTokens(answer, acceptedRu(word), normalizeRu);

AnswerGrade gradePlAnswer(Word word, String answer) =>
    _gradeTokens(answer, [for (final variant in word.pl) normalizePl(variant)], normalizePl);
