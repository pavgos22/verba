import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/data/progress_store.dart';
import 'package:verba/data/settings_store.dart';
import 'package:verba/data/word.dart';
import 'package:verba/data/words_repository.dart';
import 'package:verba/screens/session_screen.dart';
import 'package:verba/theme/app_theme.dart';

const _word = Word(id: 'w1', ru: 'кот', pl: ['kot']);

Future<ProviderContainer> _pumpRetry(WidgetTester tester, {bool loop = false, bool enterEmpty = true}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'settings.autoplay': false,
    'settings.answerSounds': false,
    'settings.showKeyboard': false,
    'settings.enterEmptyIsGiveUp': enterEmpty,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(prefs),
    wordsProvider.overrideWith((ref) => [_word]),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: SessionScreen(
        mode: SessionMode.retry,
        retryTasks: const [SessionTask(word: _word, kind: TaskKind.typingRuToPl)],
        loop: loop,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('retry session does not credit correct answers', (tester) async {
    final container = await _pumpRetry(tester);

    await tester.enterText(find.byType(TextField), 'kot');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(container.read(progressProvider).words, isEmpty);
  });

  testWidgets('retry session still records mistakes', (tester) async {
    final container = await _pumpRetry(tester);

    await tester.enterText(find.byType(TextField), 'pies');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final progress = container.read(progressProvider).words['w1'];
    expect(progress, isNotNull);
    expect(progress!.wrong, 1);
    expect(progress.box, 1);
  });

  testWidgets('Enter on an empty field counts as a give-up', (tester) async {
    final container = await _pumpRetry(tester);

    await tester.testTextInput.receiveAction(TextInputAction.done); // Enter, nothing typed
    await tester.pumpAndSettle();

    final progress = container.read(progressProvider).words['w1'];
    expect(progress, isNotNull);
    expect(progress!.wrong, 1);
  });

  testWidgets('Enter on an empty field does nothing when the setting is off', (tester) async {
    final container = await _pumpRetry(tester, enterEmpty: false);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(container.read(progressProvider).words, isEmpty);
  });

  testWidgets('a word loses at most one point per session however many misses', (tester) async {
    final container = await _pumpRetry(tester, loop: true);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kot');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(container.read(progressProvider).words['w1']!.wrong, 1);
  });

  testWidgets('loop retry counter shrinks to the words still to fix each round', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'settings.autoplay': false,
      'settings.answerSounds': false,
      'settings.showKeyboard': false,
    });
    final prefs = await SharedPreferences.getInstance();
    const w1 = Word(id: 'w1', ru: 'кот', pl: ['kot']);
    const w2 = Word(id: 'w2', ru: 'дом', pl: ['dom']);
    final container = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      wordsProvider.overrideWith((ref) => [w1, w2]),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const SessionScreen(
          mode: SessionMode.retry,
          retryTasks: [
            SessionTask(word: w1, kind: TaskKind.typingRuToPl),
            SessionTask(word: w2, kind: TaskKind.typingRuToPl),
          ],
          loop: true,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kot'); // w1 correct
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz'); // w2 wrong
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'dom'); // retype correct
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();

    // second round contains only the one word that was still wrong
    expect(find.text('1 / 1'), findsOneWidget);
    expect(find.text('дом'), findsOneWidget);
  });

  testWidgets('after a correct PL->RU answer, holding Tab reveals verb info', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'settings.autoplay': false,
      'settings.answerSounds': false,
      'settings.showKeyboard': false,
      'settings.showAccents': false,
    });
    final prefs = await SharedPreferences.getInstance();
    const verb = Word(id: 'v', ru: 'ехать', ruAccented: 'е́хать', pl: ['jechać'], firstPerson: 'еду', verbType: '1');
    final container = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      wordsProvider.overrideWith((ref) => [verb]),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const SessionScreen(
          mode: SessionMode.retry,
          retryTasks: [SessionTask(word: verb, kind: TaskKind.typingPlToRu)],
          loop: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ехать');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('еду'), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('еду'), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
  });

  testWidgets('losing focus un-sticks the Tab details view (missed key-up)', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'settings.autoplay': false,
      'settings.answerSounds': false,
      'settings.showKeyboard': false,
      'settings.showAccents': false,
    });
    final prefs = await SharedPreferences.getInstance();
    const verb = Word(id: 'v', ru: 'ехать', ruAccented: 'е́хать', pl: ['jechać'], firstPerson: 'еду', verbType: '1');
    final container = ProviderContainer(overrides: [
      prefsProvider.overrideWithValue(prefs),
      wordsProvider.overrideWith((ref) => [verb]),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: const SessionScreen(
          mode: SessionMode.retry,
          retryTasks: [SessionTask(word: verb, kind: TaskKind.typingPlToRu)],
          loop: false,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ехать');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(find.text('еду'), findsOneWidget);

    // The Tab key-up is never delivered (e.g. Alt+Tab away); focus leaves the session.
    tester.binding.focusManager.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('еду'), findsNothing);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
  });

  testWidgets('the end-of-session summary always shows and no Enter skips it into the retry', (tester) async {
    await _pumpRetry(tester, loop: false);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'kot');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Sesja ukończona!'), findsOneWidget);

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Sesja ukończona!'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Sesja ukończona!'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Popraw błędne (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Sesja ukończona!'), findsNothing);
  });
}
