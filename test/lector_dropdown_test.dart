import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verba/services/audio_service.dart';
import 'package:verba/theme/app_theme.dart';
import 'package:verba/widgets/lector_dropdown.dart';

Future<List<Lector>> _openAndTapNadia(WidgetTester tester, {required bool googleUnavailable}) async {
  final picks = <Lector>[];
  await tester.pumpWidget(MaterialApp(
    theme: buildTheme(Brightness.light),
    home: Scaffold(
      body: Center(
        child: LectorDropdown(value: Lector.system, googleUnavailable: googleUnavailable, onChanged: picks.add),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(LectorDropdown));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Nadia').last);
  await tester.pumpAndSettle();
  return picks;
}

void main() {
  testWidgets('Nadia is disabled for custom courses', (tester) async {
    final picks = await _openAndTapNadia(tester, googleUnavailable: true);
    expect(picks, isEmpty);
  });

  testWidgets('Nadia is selectable for built-in courses', (tester) async {
    final picks = await _openAndTapNadia(tester, googleUnavailable: false);
    expect(picks, [Lector.google]);
  });
}
