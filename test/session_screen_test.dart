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

  testWidgets('loop retry counter counts cleared words out of the original total', (tester) async {
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

    expect(find.text('0 / 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'kot'); // w1 correct
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 2'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzz'); // w2 wrong -> requeued at the end
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'dom'); // retype correct to move on
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();

    // one cleared out of two; now re-testing the word that was still wrong, count does not jump back
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('дом'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dom'); // clears the requeued word
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dalej'));
    await tester.pumpAndSettle();
    expect(find.text('Wszystko poprawione!'), findsOneWidget);
  });

  testWidgets('the session top bar shows the category filter as a badge, hidden for all words', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> pump({String? category}) async {
      final initial = <String, Object>{
        'settings.autoplay': false,
        'settings.answerSounds': false,
        'settings.showKeyboard': false,
      };
      if (category != null) initial['settings.mode.full.category'] = category;
      SharedPreferences.setMockInitialValues(initial);
      final prefs = await SharedPreferences.getInstance();
      const word = Word(id: 'w1', ru: 'кот', pl: ['kot'], category: 'czasowniki');
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        wordsProvider.overrideWith((ref) => [word]),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: buildTheme(Brightness.light), home: const SessionScreen(mode: SessionMode.full)),
      ));
      await tester.pumpAndSettle();
    }

    await pump(category: 'czasowniki');
    expect(find.text('Czasowniki'), findsOneWidget); // capitalised badge in the top bar

    await pump(); // "wszystkie" — no category filter
    expect(find.text('Czasowniki'), findsNothing);
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

  testWidgets('a fresh Enter on the summary starts the retry, a carried-over one does not', (tester) async {
    await _pumpRetry(tester, loop: false);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'kot');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Enter on the focused "Dalej" advances to the summary; the key stays held.
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Sesja ukończona!'), findsOneWidget);

    // The still-held Enter (auto-repeat) must not skip straight into the retry.
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Sesja ukończona!'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    // A fresh Enter press (after release) starts the retry.
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Sesja ukończona!'), findsNothing);
  });

  testWidgets('a PL->RU answer given as a synonym counts but names the card word', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const similar = Word(
      id: 's',
      ru: 'похожий',
      ruAccented: 'похожий',
      ruAlt: ['подобный'],
      pl: ['podobny'],
      category: 'przymiotniki',
    );

    Future<void> pump(String runKey) async {
      SharedPreferences.setMockInitialValues({
        'settings.autoplay': false,
        'settings.answerSounds': false,
        'settings.showKeyboard': false,
        'settings.showAccents': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(prefs),
        wordsProvider.overrideWith((ref) => [similar]),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: SessionScreen(
            key: ValueKey(runKey),
            mode: SessionMode.retry,
            retryTasks: const [SessionTask(word: similar, kind: TaskKind.typingPlToRu)],
            loop: false,
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    await pump('alt');
    await tester.enterText(find.byType(TextField), 'подобный');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Świetnie!'), findsOneWidget);
    expect(find.text('· na tej karcie:'), findsOneWidget);
    expect(find.text('похожий'), findsOneWidget);

    await pump('own');
    await tester.enterText(find.byType(TextField), 'похожий');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Świetnie!'), findsOneWidget);
    expect(find.text('· na tej karcie:'), findsNothing);
  });

  testWidgets('detailsAfterCorrect reveals verb info without Tab after a correct answer', (tester) async {
    tester.view.physicalSize = const Size(1400, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      'settings.autoplay': false,
      'settings.answerSounds': false,
      'settings.showKeyboard': false,
      'settings.showAccents': false,
      'settings.detailsAfterCorrect': true,
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
    expect(find.text('еду'), findsOneWidget);
  });
}
