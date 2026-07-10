import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verba/data/course.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Course> load(String asset) async {
    final raw = await rootBundle.loadString(asset);
    return Course.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  test('course assets load with unique word ids across courses', () async {
    final ids = <String>{};
    var total = 0;
    for (final asset in ['assets/data/course_starter.json', 'assets/data/course_ru1000.json']) {
      final course = load(asset);
      final loaded = await course;
      expect(loaded.words, isNotEmpty);
      for (final word in loaded.words) {
        expect(ids.add(word.id), isTrue, reason: 'duplicate id ${word.id}');
        expect(word.pl, isNotEmpty, reason: 'empty pl for ${word.ru}');
      }
      total += loaded.words.length;
    }
    expect(total, 1050);
  });

  test('every word has pronunciation', () async {
    for (final asset in ['assets/data/course_starter.json', 'assets/data/course_ru1000.json']) {
      final course = await load(asset);
      for (final word in course.words) {
        expect(word.pronunciation, isNotNull, reason: 'missing pronunciation for ${word.ru}');
      }
    }
  });

  test('ru1000 has exactly 1000 words', () async {
    final course = await load('assets/data/course_ru1000.json');
    expect(course.words.length, 1000);
  });

  test('every word has a category', () async {
    for (final asset in ['assets/data/course_starter.json', 'assets/data/course_ru1000.json']) {
      final course = await load(asset);
      for (final word in course.words) {
        expect(word.category, isNotNull, reason: 'missing category for ${word.ru}');
      }
    }
  });

  test('ru1000 verbs carry first-person and conjugation data', () async {
    final course = await load('assets/data/course_ru1000.json');
    final verbs = course.words.where((w) => w.category == 'czasowniki').toList();
    expect(verbs.length, greaterThan(200));
    final withInfo = verbs.where((w) => w.firstPerson != null && w.verbType != null).length;
    expect(withInfo, greaterThan(230));
    for (final word in verbs) {
      if (word.verbType != null) {
        expect(['1', '2'].contains(word.verbType), isTrue, reason: 'odd verbType ${word.verbType} for ${word.ru}');
      }
    }
  });
}
