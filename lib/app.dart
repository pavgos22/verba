import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/settings_store.dart';
import 'screens/shell_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_fade.dart';

class VerbaApp extends ConsumerWidget {
  const VerbaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'Verba',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: themeMode,
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => ThemeFade(key: themeFadeKey, child: child ?? const SizedBox.shrink()),
      home: const ShellScreen(),
    );
  }
}
