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
}
