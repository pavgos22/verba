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
const _joVerb = Word(
  id: 'v2',
  ru: 'жить',
  ruAccented: 'жить',
  pl: ['mieszkać'],
  category: 'czasowniki',
  firstPerson: 'живу',
  secondPerson: 'живёшь',
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

  testWidgets('verb info shows the second person (ё trap) when present', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _joVerb, visible: true));
    expect(find.text('живу'), findsOneWidget);
    expect(find.text('живёшь'), findsOneWidget);
  });

  testWidgets('the ё in the second person is highlighted in its own colour', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _joVerb, visible: true));
    final richText = tester.widget<Text>(find.text('живёшь'));
    final joSpans = <TextSpan>[];
    richText.textSpan!.visitChildren((span) {
      if (span is TextSpan && span.text == 'ё') joSpans.add(span);
      return true;
    });
    expect(joSpans, hasLength(1));
    expect(joSpans.single.style?.color, isNotNull);
  });

  testWidgets('the second person is hidden when not visible', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _joVerb, visible: false));
    expect(find.text('живёшь'), findsNothing);
  });

  testWidgets('a non-verb word shows no verb content', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _noun, visible: true));
    expect(find.text('1'), findsNothing);
  });

  testWidgets('reserves the same height for verbs and non-verbs so words do not jump', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _noun, visible: false));
    final nounHeight = tester.getSize(find.byType(VerbInfoSlot)).height;
    await _pump(tester, const VerbInfoSlot(word: _verb, visible: false));
    final verbHeight = tester.getSize(find.byType(VerbInfoSlot)).height;
    expect(nounHeight, greaterThan(0));
    expect(nounHeight, verbHeight);
  });

  testWidgets('reserve:false collapses the slot to nothing', (tester) async {
    await _pump(tester, const VerbInfoSlot(word: _verb, visible: false, reserve: false));
    expect(tester.getSize(find.byType(VerbInfoSlot)).height, 0);
  });

  test('showVerbInfo respects mode and hold state', () {
    expect(showVerbInfo(_verb, VerbInfoMode.never, true), isFalse);
    expect(showVerbInfo(_verb, VerbInfoMode.always, false), isTrue);
    expect(showVerbInfo(_verb, VerbInfoMode.onHold, false), isFalse);
    expect(showVerbInfo(_verb, VerbInfoMode.onHold, true), isTrue);
    expect(showVerbInfo(_noun, VerbInfoMode.always, true), isFalse);
  });
}
