import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verba/main.dart';

void main() {
  testWidgets('app builds', (tester) async {
    await tester.pumpWidget(const VerbaApp());
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
