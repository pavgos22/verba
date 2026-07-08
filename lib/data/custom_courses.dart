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
