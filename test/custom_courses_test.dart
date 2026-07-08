import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verba/data/custom_courses.dart';
import 'package:verba/data/word.dart';

ProviderContainer make([String raw = '']) {
  return ProviderContainer(overrides: [
    customCoursesRawProvider.overrideWithValue(raw),
    customCoursesPathProvider.overrideWithValue('${Directory.systemTemp.path}/verba_test_courses.json'),
  ]);
}

void main() {
  test('create, add words, remove, delete', () {
    final container = make();
    final notifier = container.read(customCoursesProvider.notifier);

    final course = notifier.createCourse('Test', 'opis');
    expect(course.id.startsWith('custom-'), isTrue);
    expect(container.read(customCoursesProvider).length, 1);

    notifier.addWord(course.id, const Word(id: 'w1', ru: 'дом', pl: ['dom']));
    notifier.addWord(course.id, const Word(id: 'w2', ru: 'кот', pl: ['kot']));
    expect(container.read(customCoursesProvider).first.words.length, 2);

    notifier.removeWord(course.id, 'w1');
    expect(container.read(customCoursesProvider).first.words.single.ru, 'кот');

    notifier.deleteCourse(course.id);
    expect(container.read(customCoursesProvider), isEmpty);
  });

  test('imports a course object with lenient word formats', () {
    final container = make();
    final notifier = container.read(customCoursesProvider.notifier);
    const raw = '{"name":"Zwierzęta","description":"test","words":['
        '{"ru":"кот","pl":["kot"]},'
        '{"ru":"собака","pl":"pies, piesek"},'
        '{"ru":"","pl":["x"]},'
        '{"pl":["brak ru"]}'
        ']}';
    final course = notifier.importCourse(raw, 'plik');
    expect(course.name, 'Zwierzęta');
    expect(course.words.length, 2);
    expect(course.words[1].pl, ['pies', 'piesek']);
    expect(course.isCustom, isTrue);
  });

  test('imports a bare word array using fallback name', () {
    final container = make();
    final notifier = container.read(customCoursesProvider.notifier);
    const raw = '[{"ru":"дом","pl":["dom"]}]';
    final course = notifier.importCourse(raw, 'moj-plik');
    expect(course.name, 'moj-plik');
    expect(course.words.single.ru, 'дом');
  });

  test('rejects invalid json and empty words', () {
    final container = make();
    final notifier = container.read(customCoursesProvider.notifier);
    expect(() => notifier.importCourse('nonsense', 'x'), throwsFormatException);
    expect(() => notifier.importCourse('{"words":[]}', 'x'), throwsFormatException);
  });

  test('loads from raw json', () {
    const raw = '[{"id":"custom-1","name":"Moje","description":"d",'
        '"words":[{"id":"w","ru":"вода","pl":["woda"]}]}]';
    final container = make(raw);
    final courses = container.read(customCoursesProvider);
    expect(courses.single.name, 'Moje');
    expect(courses.single.isCustom, isTrue);
    expect(courses.single.words.single.pl, ['woda']);
  });
}
