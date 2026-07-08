import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'course.dart';
import 'custom_courses.dart';
import 'settings_store.dart';
import 'word.dart';

const _courseAssets = [
  'assets/data/course_starter.json',
  'assets/data/course_ru1000.json',
];

final builtInCoursesProvider = FutureProvider<List<Course>>((ref) async {
  final courses = <Course>[];
  for (final asset in _courseAssets) {
    final raw = await rootBundle.loadString(asset);
    courses.add(Course.fromJson(jsonDecode(raw) as Map<String, dynamic>));
  }
  return courses;
});

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final builtIn = await ref.watch(builtInCoursesProvider.future);
  final custom = ref.watch(customCoursesProvider);
  return [...builtIn, ...custom];
});

final activeCourseProvider = FutureProvider<Course>((ref) async {
  final courses = await ref.watch(coursesProvider.future);
  final id = ref.watch(settingsProvider.select((s) => s.activeCourseId));
  return courses.firstWhere((c) => c.id == id, orElse: () => courses.first);
});

final wordsProvider = FutureProvider<List<Word>>((ref) async {
  final course = await ref.watch(activeCourseProvider.future);
  return course.words;
});
