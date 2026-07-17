import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/transliteration.dart';
import '../data/settings_store.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';
import '../widgets/onscreen_keyboard.dart';

class KeyboardScreen extends ConsumerStatefulWidget {
  const KeyboardScreen({super.key});

  @override
  ConsumerState<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends ConsumerState<KeyboardScreen> {
  final _controller = TextEditingController();
  KeyboardLayoutType _layout = KeyboardLayoutType.russian;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Klawiatura', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.c.foreground)),
          const SizedBox(height: 4),
          Text(
            _layout == KeyboardLayoutType.russian
                ? 'Pisz po łacińsku — Verba zamienia znaki na cyrylicę'
                : 'Zwykła klawiatura łacińska z polskimi znakami',
            style: TextStyle(fontSize: 14, color: context.c.mutedForeground),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    controller: _controller,
                    maxLines: 6,
                    minLines: 6,
                    inputFormatters: _layout == KeyboardLayoutType.russian ? [TransliterationFormatter()] : null,
                    style: TextStyle(fontSize: 18, height: 1.5, color: context.c.foreground),
                    decoration: InputDecoration.collapsed(
                      hintText: _layout == KeyboardLayoutType.russian ? 'privet — привет...' : 'Zacznij pisać...',
                      hintStyle: TextStyle(fontSize: 18, color: context.c.mutedForeground),
                    ),
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _controller.clear()),
                        child: const Text('Wyczyść'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: _controller.text));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(const SnackBar(
                              content: Text('Skopiowano do schowka'),
                              duration: Duration(seconds: 2),
                            ));
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Kopiuj'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_layout == KeyboardLayoutType.russian && settings.showHints)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppBadge(label: 'zh → ж'),
                AppBadge(label: 'ch → ч'),
                AppBadge(label: 'sh → ш'),
                AppBadge(label: 'w → щ'),
                AppBadge(label: "' → ь"),
                AppBadge(label: "'' → ъ"),
                AppBadge(label: 'e= → ё'),
                AppBadge(label: 'e== → э'),
                AppBadge(label: 'q → akcent'),
              ],
            ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                SegmentedButton<KeyboardLayoutType>(
                  segments: const [
                    ButtonSegment(value: KeyboardLayoutType.russian, label: Text('Cyrylica')),
                    ButtonSegment(value: KeyboardLayoutType.polish, label: Text('Polski')),
                  ],
                  selected: {_layout},
                  onSelectionChanged: (selection) => setState(() => _layout = selection.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 16),
                OnScreenKeyboard(
                  layout: _layout,
                  accentRow: true,
                  onText: (text) => insertIntoController(_controller, text),
                  onBackspace: () => backspaceInController(_controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
