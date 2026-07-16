import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'course.dart';
import 'word.dart';

typedef ParsedCourse = ({String name, String description, List<Word> words});

ParsedCourse parseCourseJson(String rawJson, String fallbackName) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(rawJson);
  } catch (_) {
    throw const FormatException('Plik nie jest poprawnym JSON-em.');
  }
  var name = fallbackName;
  var description = '';
  final List<dynamic> rawWords;
  if (decoded is Map<String, dynamic>) {
    final n = (decoded['name'] as String?)?.trim();
    if (n != null && n.isNotEmpty) name = n;
    description = (decoded['description'] as String?)?.trim() ?? '';
    final w = decoded['words'];
    if (w is! List) throw const FormatException('Brak listy „words" w pliku.');
    rawWords = w;
  } else if (decoded is List) {
    rawWords = decoded;
  } else {
    throw const FormatException('Nieoczekiwany format pliku.');
  }

  final words = <Word>[];
  final base = DateTime.now().microsecondsSinceEpoch;
  for (final e in rawWords) {
    if (e is! Map) continue;
    final ru = (e['ru'] as String?)?.trim();
    if (ru == null || ru.isEmpty) continue;
    final plRaw = e['pl'];
    final pl = <String>[];
    if (plRaw is String) {
      pl.addAll(plRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty));
    } else if (plRaw is List) {
      pl.addAll(plRaw.map((s) => s.toString().trim()).where((s) => s.isNotEmpty));
    }
    if (pl.isEmpty) continue;
    final category = (e['category'] as String?)?.trim();
    final firstPerson = (e['firstPerson'] as String?)?.trim();
    final secondPerson = (e['secondPerson'] as String?)?.trim();
    final verbType = (e['verbType'] as String?)?.trim();
    words.add(Word(
      id: 'w-$base-${words.length}',
      ru: ru,
      ruAccented: e['ruAccented'] as String?,
      pl: pl,
      category: category == null || category.isEmpty ? null : category,
      pronunciation: e['pronunciation'] as String?,
      firstPerson: firstPerson == null || firstPerson.isEmpty ? null : firstPerson,
      secondPerson: secondPerson == null || secondPerson.isEmpty ? null : secondPerson,
      verbType: verbType == null || verbType.isEmpty ? null : verbType,
    ));
  }
  if (words.isEmpty) {
    throw const FormatException('Nie znaleziono żadnych słówek (potrzebne pola „ru" i „pl").');
  }
  return (name: name, description: description, words: words);
}

Future<({String raw, String name})?> pickCourseJson() async {
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    dialogTitle: 'Wybierz plik JSON z kursem',
  );
  final path = picked?.files.single.path;
  if (path == null) return null;
  final raw = await File(path).readAsString();
  final name = picked!.files.single.name.replaceAll(RegExp(r'\.json$', caseSensitive: false), '');
  return (raw: raw, name: name);
}

const exampleCourseJson = '''{
  "name": "Przykładowy kurs",
  "description": "Przykład formatu — zamień słówka na własne",
  "words": [
    {"ru": "кот", "pl": ["kot"]},
    {"ru": "собака", "pl": "pies, piesek"},
    {"ru": "дом", "pl": ["dom"], "category": "rzeczowniki"},
    {"ru": "хорошо", "ruAccented": "хорошо́", "pl": ["dobrze"], "category": "przysłówki", "pronunciation": "charaszo"},
    {"ru": "ехать", "ruAccented": "е́хать", "pl": ["jechać"], "category": "czasowniki", "firstPerson": "е́ду", "verbType": "1"},
    {"ru": "жить", "pl": ["mieszkać", "żyć"], "category": "czasowniki", "firstPerson": "живу", "secondPerson": "живёшь", "verbType": "1"}
  ]
}''';

Future<String?> saveExampleCourseJson() async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Zapisz przykładowy plik JSON',
    fileName: 'verba_przyklad.json',
  );
  if (path == null) return null;
  final target = path.toLowerCase().endsWith('.json') ? path : '$path.json';
  await File(target).writeAsString(exampleCourseJson);
  return target;
}

final customCoursesPathProvider = Provider<String>((ref) {
  throw UnimplementedError('customCoursesPathProvider requires an override');
});

final customCoursesRawProvider = Provider<String>((ref) {
  throw UnimplementedError('customCoursesRawProvider requires an override');
});

class CustomCoursesNotifier extends Notifier<List<Course>> {
  @override
  List<Course> build() {
    final raw = ref.read(customCoursesRawProvider);
    if (raw.trim().isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [for (final e in list) Course.fromJson(e as Map<String, dynamic>)];
    } catch (_) {
      return [];
    }
  }

  Course createCourse(String name, String description) {
    final course = Course(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      words: const [],
    );
    state = [...state, course];
    _persist();
    return course;
  }

  void renameCourse(String id, String name, String description) {
    state = [
      for (final c in state)
        if (c.id == id) c.copyWith(name: name, description: description) else c,
    ];
    _persist();
  }

  void deleteCourse(String id) {
    state = state.where((c) => c.id != id).toList();
    _persist();
  }

  void addWord(String courseId, Word word) {
    state = [
      for (final c in state)
        if (c.id == courseId) c.copyWith(words: [...c.words, word]) else c,
    ];
    _persist();
  }

  void removeWord(String courseId, String wordId) {
    state = [
      for (final c in state)
        if (c.id == courseId)
          c.copyWith(words: c.words.where((w) => w.id != wordId).toList())
        else
          c,
    ];
    _persist();
  }

  void updateWord(String courseId, String wordId, Word word) {
    state = [
      for (final c in state)
        if (c.id == courseId)
          c.copyWith(words: [for (final w in c.words) if (w.id == wordId) word else w])
        else
          c,
    ];
    _persist();
  }

  Course importCourse(String rawJson, String fallbackName) {
    final parsed = parseCourseJson(rawJson, fallbackName);
    final course = Course(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: parsed.name,
      description: parsed.description,
      words: parsed.words,
    );
    state = [...state, course];
    _persist();
    return course;
  }

  void setWords(String courseId, List<Word> words) {
    state = [
      for (final c in state)
        if (c.id == courseId) c.copyWith(words: words) else c,
    ];
    _persist();
  }

  void addWords(String courseId, List<Word> words) {
    state = [
      for (final c in state)
        if (c.id == courseId) c.copyWith(words: [...c.words, ...words]) else c,
    ];
    _persist();
  }

  Course? byId(String id) {
    for (final c in state) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _persist() {
    final path = ref.read(customCoursesPathProvider);
    final data = jsonEncode([for (final c in state) c.toJson()]);
    File(path).writeAsString(data);
  }
}

final customCoursesProvider =
    NotifierProvider<CustomCoursesNotifier, List<Course>>(CustomCoursesNotifier.new);
