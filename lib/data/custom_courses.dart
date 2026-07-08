import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'course.dart';
import 'word.dart';

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

  Course importCourse(String rawJson, String fallbackName) {
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
      words.add(Word(
        id: 'w-$base-${words.length}',
        ru: ru,
        ruAccented: e['ruAccented'] as String?,
        pl: pl,
        category: (e['category'] as String?)?.trim().isEmpty ?? true ? null : e['category'] as String?,
        pronunciation: e['pronunciation'] as String?,
      ));
    }
    if (words.isEmpty) throw const FormatException('Nie znaleziono żadnych słówek (potrzebne pola „ru" i „pl").');

    final course = Course(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      words: words,
    );
    state = [...state, course];
    _persist();
    return course;
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
