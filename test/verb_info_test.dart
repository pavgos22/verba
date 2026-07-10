import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/data/settings_store.dart';
import 'package:verba/data/word.dart';
import 'package:verba/theme/app_theme.dart';
import 'package:verba/widgets/common.dart';

const _verb = Word(
  id: 'v',
  ru: 'ехать',
  ruAccented: 'е́хать',
  pl: ['jechać'],
  category: 'czasowniki',
  firstPerson: 'е́ду',
  verbType: '1',
);
const _noun = Word(id: 'n', ru: 'дом', pl: ['dom']);

Future<void> _pump(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({'settings.showAccents': false});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(ProviderScope(
    overrides: [prefsProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(body: Center(child: child)),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('verb info shows first person and type when visible', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _verb, visible: true));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('еду'), findsOneWidget);
  });

  testWidgets('verb info reserves but hides content when not visible', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _verb, visible: false));
    expect(find.text('1'), findsNothing);
    expect(find.text('еду'), findsNothing);
  });

  testWidgets('a non-verb word renders nothing', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _noun, visible: true));
    expect(find.text('1'), findsNothing);
  });

  test('showVerbInfo respects mode and hold state', () {
    expect(showVerbInfo(_verb, VerbInfoMode.never, true), isFalse);
    expect(showVerbInfo(_verb, VerbInfoMode.always, false), isTrue);
    expect(showVerbInfo(_verb, VerbInfoMode.onHold, false), isFalse);
    expect(showVerbInfo(_verb, VerbInfoMode.onHold, true), isTrue);
    expect(showVerbInfo(_noun, VerbInfoMode.always, true), isFalse);
  });
}
