import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verba/app.dart';
import 'package:verba/data/settings_store.dart';

void main() {
  testWidgets('app builds and shows shell', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [prefsProvider.overrideWithValue(prefs)],
        child: const VerbaApp(),
      ),
    );
    await tester.pump();
    expect(find.text('Verba'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Ustawienia'), findsOneWidget);
  });
}
