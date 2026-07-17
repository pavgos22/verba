import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verba/theme/app_theme.dart';

void main() {
  MouseCursor? enabled(WidgetStateProperty<MouseCursor?>? property) => property?.resolve({});

  for (final brightness in Brightness.values) {
    test('clickable controls use the pointer cursor (${brightness.name})', () {
      final theme = buildTheme(brightness);
      expect(enabled(theme.iconButtonTheme.style?.mouseCursor), SystemMouseCursors.click);
      expect(enabled(theme.filledButtonTheme.style?.mouseCursor), SystemMouseCursors.click);
      expect(enabled(theme.outlinedButtonTheme.style?.mouseCursor), SystemMouseCursors.click);
      expect(enabled(theme.textButtonTheme.style?.mouseCursor), SystemMouseCursors.click);
    });
  }
}
