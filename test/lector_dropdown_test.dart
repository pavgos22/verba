import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verba/services/audio_service.dart';
import 'package:verba/theme/app_theme.dart';
import 'package:verba/widgets/lector_dropdown.dart';

Future<List<Lector>> _openAndTapVerba(WidgetTester tester, {required bool googleUnavailable}) async {
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
  await tester.tap(find.text('Verba').last);
  await tester.pumpAndSettle();
  return picks;
}

void main() {
  testWidgets('Verba is disabled for custom courses', (tester) async {
    final picks = await _openAndTapVerba(tester, googleUnavailable: true);
    expect(picks, isEmpty);
  });

  testWidgets('Verba is selectable for built-in courses', (tester) async {
    final picks = await _openAndTapVerba(tester, googleUnavailable: false);
    expect(picks, [Lector.google]);
  });

  testWidgets('trigger shows system when Verba is unavailable', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      home: Scaffold(
        body: Center(
          child: LectorDropdown(value: Lector.google, googleUnavailable: true, onChanged: (_) {}),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Lektor: Systemowy'), findsOneWidget);
    expect(find.text('Lektor: Verba'), findsNothing);
  });
}
