import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/data/custom_courses.dart';
import 'package:verba/data/settings_store.dart';
import 'package:verba/screens/course_editor_screen.dart';
import 'package:verba/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester, {String wordsJson = '', bool autoLayout = true}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({'settings.autoKeyboardLayout': autoLayout});
  final prefs = await SharedPreferences.getInstance();
  final raw = '[{"id":"custom-1","name":"Test","description":"d","words":[$wordsJson]}]';
  await tester.pumpWidget(ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      customCoursesPathProvider.overrideWithValue('unused'),
      customCoursesRawProvider.overrideWithValue(raw),
    ],
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: const CourseEditorScreen(courseId: 'custom-1'),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('editor shows dropdown, add button and a polish keyboard by default', (tester) async {
    await _pump(tester);
    expect(find.text('Kategoria'), findsOneWidget);
    expect(find.text('Bez kategorii'), findsOneWidget);
    expect(find.text('Dodaj'), findsOneWidget);
    expect(find.text('Zapisz'), findsOneWidget);
    expect(find.text('Wymowa (opcjonalnie)'), findsOneWidget);
    expect(find.text('ł'), findsWidgets);
    expect(find.text('а'), findsNothing);
  });

  testWidgets('auto layout switches the keyboard to match the focused field', (tester) async {
    await _pump(tester);
    expect(find.text('ł'), findsWidgets);
    expect(find.text('а'), findsNothing);

    await tester.tap(find.byType(TextField).at(0)); // Rosyjski
    await tester.pumpAndSettle();
    expect(find.text('а'), findsWidgets, reason: 'focusing the Russian field switches to the Russian layout');
    expect(find.text('ł'), findsNothing);

    await tester.tap(find.byType(TextField).at(1)); // Polski
    await tester.pumpAndSettle();
    expect(find.text('ł'), findsWidgets, reason: 'focusing the Polish field switches back to Polish');
    expect(find.text('а'), findsNothing);
  });

  testWidgets('with auto layout off, focusing a field does not switch the keyboard', (tester) async {
    await _pump(tester, autoLayout: false);

    await tester.tap(find.byType(TextField).at(0)); // Rosyjski
    await tester.pumpAndSettle();
    expect(find.text('ł'), findsWidgets, reason: 'auto off: the layout stays as chosen');
    expect(find.text('а'), findsNothing);
  });

  testWidgets('the manual layout toggle still switches the keyboard', (tester) async {
    await _pump(tester, autoLayout: false);

    await tester.tap(find.text('Rosyjska'));
    await tester.pumpAndSettle();
    expect(find.text('а'), findsWidgets);
    expect(find.text('е́'), findsWidgets, reason: 'russian layout has an accented-vowel row');
    expect(find.text('ł'), findsNothing);
  });

  testWidgets('adding with an empty field shows an error and adds nothing', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField).at(0), 'кот'); // only Russian filled
    await tester.tap(find.text('Dodaj'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.textContaining('nie mogą być puste'), findsOneWidget);
    expect(find.text('Dodaj pierwsze słówko powyżej'), findsOneWidget);
  });

  testWidgets('adding with both required fields creates the word', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField).at(0), 'кот');
    await tester.enterText(find.byType(TextField).at(1), 'kot');
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    expect(find.text('кот'), findsOneWidget);
    expect(find.text('kot'), findsOneWidget);
  });

  testWidgets('the accent is split off into ruAccented, ru stays plain', (tester) async {
    await _pump(tester);

    await tester.enterText(find.byType(TextField).at(0), 'дава́ть'); // stress mark in the field
    await tester.enterText(find.byType(TextField).at(1), 'dawać');
    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    expect(find.text('давать'), findsOneWidget); // the list shows the plain ru
  });

  testWidgets('add-form verb fields are disabled when no category is chosen', (tester) async {
    await _pump(tester);

    expect(tester.widget<TextField>(find.byType(TextField).at(3)).enabled, isFalse); // 1. osoba
    expect(tester.widget<TextField>(find.byType(TextField).at(4)).enabled, isFalse); // 2. osoba
    expect(tester.widget<TextField>(find.byType(TextField).at(5)).enabled, isFalse); // Typ
  });

  testWidgets('the edit dialog enables verb fields for a verb, disables them otherwise', (tester) async {
    await _pump(tester, wordsJson: '{"id":"a","ru":"жить","pl":["żyć"],"category":"czasowniki","firstPerson":"живу"}');

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final verbFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    expect(tester.widget<TextField>(verbFields.at(3)).enabled, isTrue); // 1. osoba
    expect(tester.widget<TextField>(verbFields.at(4)).enabled, isTrue); // Typ
    expect(tester.widget<TextField>(verbFields.at(5)).enabled, isTrue); // 2. osoba
  });

  testWidgets('the edit dialog disables verb fields for a non-verb', (tester) async {
    await _pump(tester, wordsJson: '{"id":"a","ru":"дом","pl":["dom"],"category":"rzeczowniki"}');

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    expect(tester.widget<TextField>(fields.at(3)).enabled, isFalse);
    expect(tester.widget<TextField>(fields.at(5)).enabled, isFalse);
  });

  testWidgets('add-form adjective fields are disabled when no category is chosen', (tester) async {
    await _pump(tester);

    expect(tester.widget<TextField>(find.byType(TextField).at(6)).enabled, isFalse); // rodz. męski
    expect(tester.widget<TextField>(find.byType(TextField).at(9)).enabled, isFalse); // l. mnoga
  });

  testWidgets('the edit dialog enables adjective fields for an adjective and disables verb ones', (tester) async {
    await _pump(tester,
        wordsJson: '{"id":"a","ru":"новый","ruAccented":"но́вый","pl":["nowy"],"category":"przymiotniki","feminine":"но́вая"}');

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    expect(tester.widget<TextField>(fields.at(6)).enabled, isTrue); // rodz. męski
    expect(tester.widget<TextField>(fields.at(9)).enabled, isTrue); // l. mnoga
    expect(tester.widget<TextField>(fields.at(3)).enabled, isFalse); // 1. osoba (verb) greyed
  });

  testWidgets('words are numbered from 1 with the first added on top', (tester) async {
    await _pump(tester, wordsJson: '{"id":"a","ru":"кот","pl":["kot"]},{"id":"b","ru":"дом","pl":["dom"]}');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('кот')).dy,
      lessThan(tester.getTopLeft(find.text('дом')).dy),
    );
  });

  testWidgets('the pencil dialog edits a word', (tester) async {
    await _pump(tester, wordsJson: '{"id":"a","ru":"кот","pl":["kot"]}');

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Edytuj słówko'), findsOneWidget);

    final dialogFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
    await tester.enterText(dialogFields.at(1), 'kot, kotek');
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Zapisz')));
    await tester.pumpAndSettle();

    expect(find.text('kot, kotek'), findsOneWidget);
  });
}
