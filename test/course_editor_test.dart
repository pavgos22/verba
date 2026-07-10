import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/data/custom_courses.dart';
import 'package:verba/data/settings_store.dart';
import 'package:verba/screens/course_editor_screen.dart';
import 'package:verba/theme/app_theme.dart';

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  const raw = '[{"id":"custom-1","name":"Test","description":"d","words":[]}]';
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
    expect(find.text('ł'), findsWidgets);
    expect(find.text('а'), findsNothing);
  });

  testWidgets('the layout toggle switches the keyboard, focus does not', (tester) async {
    await _pump(tester);

    await tester.tap(find.byType(TextField).at(0));
    await tester.pumpAndSettle();
    expect(find.text('ł'), findsWidgets, reason: 'focusing the Russian field must not change the layout');
    expect(find.text('а'), findsNothing);

    await tester.tap(find.text('Rosyjska'));
    await tester.pumpAndSettle();
    expect(find.text('а'), findsWidgets);
    expect(find.text('ł'), findsNothing);
  });
}
