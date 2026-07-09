import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/data/progress_store.dart';
import 'package:verba/data/settings_store.dart';
import 'package:verba/data/word.dart';
import 'package:verba/data/words_repository.dart';
import 'package:verba/screens/words_screen.dart';
import 'package:verba/theme/app_theme.dart';

const _words = [
  Word(id: 'w1', ru: 'кот', pl: ['kot']),
  Word(id: 'w2', ru: 'собака', pl: ['pies']),
  Word(id: 'w3', ru: 'дом', pl: ['dom']),
];

Future<ProviderContainer> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    wordsProvider.overrideWith((ref) => _words),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const Scaffold(body: WordsScreen()),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('a learned word shows as "W nauce" without searching', (tester) async {
    final container = await _pump(tester);

    expect(find.text('W nauce'), findsOneWidget);

    container.read(progressProvider.notifier).recordAnswer('w1', true);
    await tester.pumpAndSettle();

    expect(find.text('W nauce'), findsNWidgets(2));
  });

  testWidgets('status filter shows only matching words', (tester) async {
    final container = await _pump(tester);
    container.read(progressProvider.notifier).recordAnswer('w1', true);
    await tester.pumpAndSettle();

    expect(find.text('kot'), findsOneWidget);
    expect(find.text('pies'), findsOneWidget);

    await tester.tap(find.text('W nauce (1)'));
    await tester.pumpAndSettle();

    expect(find.text('kot'), findsOneWidget);
    expect(find.text('pies'), findsNothing);
    expect(find.text('dom'), findsNothing);
  });
}
